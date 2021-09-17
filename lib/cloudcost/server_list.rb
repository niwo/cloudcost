# frozen_string_literal: true

module Cloudcost
  class ServerList
    def initialize(servers, options = {})
      @servers = servers
      @options = options
    end

    def calculate_totals(servers = @servers)
      totals = { vcpu: 0, memory: 0, ssd: 0, bulk: 0, cost: 0.0 }
      servers.each do |server|
        totals[:vcpu] += server.vcpu_count
        totals[:memory] += server.memory_gb
        totals[:ssd] += server.storage_size(:ssd)
        totals[:bulk] += server.storage_size(:bulk)
        totals[:cost] += server.total_costs_per_day
      end
      totals
    end

    def headings
      headings = if @options[:summary]
        [""]
      elsif @options[:group_by]
        ["Group",  "Servers"]
      else
        %w[Name UUID Flavor Tags]
      end
      headings.concat ["vCPU's", "Memory [GB]", "SSD [GB]", "Bulk [GB]", "CHF/day", "CHF/30-days"]
    end

    def rows
      rows = []
      @servers.sort_by(&:name).map do |server|
        rows << [
          server.name,
          server.uuid,
          server.flavor,
          server.tags_to_s,
          server.vcpu_count,
          server.memory_gb,
          server.storage_size(:ssd),
          server.storage_size(:bulk),
          format("%.2f", server.total_costs_per_day.round(2)),
          format("%.2f", (server.total_costs_per_day * 30).round(2))
        ]
      end
      rows
    end

    def totals(servers = @servers)
      totals = calculate_totals(servers)
      total_row = @options[:summary] ? %w[Total] : ["Total", "", "", ""]
      total_row.concat [
        totals[:vcpu],
        totals[:memory],
        totals[:ssd],
        totals[:bulk],
        format("%.2f", totals[:cost].round(2)),
        format("%.2f", (totals[:cost] * 30).round(2))
      ]
    end

    def tags_table
      Terminal::Table.new do |t|
        t.title = "cloudscale.ch server tags"
        t.title += " (#{@options[:profile]})" if @options[:profile]
        t.headings = %w[Name UUID Tags]
        t.rows = @servers.sort_by(&:name).map do |server|
          [
            server.name,
            server.uuid,
            server.tags_to_s
          ]
        end
      end
    end

    def cost_table
      table = Terminal::Table.new do |t|
        t.title = "cloudscale.ch server costs"
        t.title += " (#{@options[:profile]})" if @options[:profile]
        t.headings = headings
        t.rows = rows unless @options[:summary]
      end

      table.add_separator unless @options[:summary]
      table.add_row totals
      first_number_row = @options[:summary] ? 1 : 2
      (first_number_row..table.columns.size).each { |column| table.align_column(column, :right) }
      table
    end

    def grouped_cost_table
      no_tag = "<no-tag>"
      group_rows = @servers.group_by {|s| s.tags[@options[:group_by].to_sym] || no_tag }.map do |name, servers|
        server_groups_data(name, servers).values.flatten
      end.sort {|a, b| a[0] == no_tag ? 1 : a[0] <=> b[0] }
      if @options[:output] == "csv"
        CSV.generate do |csv|
          csv << headings
          group_rows.each { |row| csv << row }
        end
      elsif @options[:output] == "influx"
        lines = []
        group_rows.each do |row|
          [
            { field: "server_count", position: 1, unit: "i" },
            { field: "vcpus", position: 2, unit: "i" },
            { field: "memory_gb", position: 3, unit: "i" },
            { field: "ssd_gb", position: 4, unit: "i" },
            { field: "bulk_gb", position: 5, unit: "i" },
            { field: "chf_per_day", position: 6, unit: "" },
          ].each do |field| 
            lines << "cloudscaleServerCosts,group=#{row[0]},profile=#{@options[:profile] || "?"} #{field[:field]}=#{row[field[:position]]}#{field[:unit]}"
          end
        end
        lines.join("\n")
      else
        table = Terminal::Table.new do |t|
          t.title = "cloudscale.ch server costs grouped by tag \"#{@options[:group_by]}\""
          t.title += " (#{@options[:profile]})" if @options[:profile]
          t.headings = headings
        end
        table.rows = group_rows
        (1..table.columns.size).each { |column| table.align_column(column, :right) }
        table
      end
    end

    def server_groups_data(name, servers)
      data = { name: name, count: 0, vcpu: 0, memory: 0, ssd: 0, bulk: 0, costs_daily: 0 }
      servers.each do |server|
        data[:count] += 1
        data[:vcpu] += server.vcpu_count
        data[:memory] += server.memory_gb
        data[:ssd] += server.storage_size(:ssd)
        data[:bulk] += server.storage_size(:bulk)
        data[:costs_daily] += server.total_costs_per_day
      end
      data[:costs_monthly] = (data[:costs_daily] * 30).round(2)
      data[:costs_daily] = data[:costs_daily].round(2)
      data
    end

    def to_csv
      CSV.generate do |csv|
        csv << headings
        if @options[:summary]
          csv << totals
        else
          rows.each { |row| csv << row }
        end
      end
    end

  end
end
