# frozen_string_literal: true

module Cloudcost
  class ServerList
    def initialize(servers, options = {})
      @servers = servers
      @options = options
    end

    def calculate_totals
      totals = { vcpu: 0, memory: 0, ssd: 0, bulk: 0, cost: 0.0 }
      @servers.each do |server|
        totals[:vcpu] += server.vcpu_count
        totals[:memory] += server.memory_gb
        totals[:ssd] += server.storage_size(:ssd)
        totals[:bulk] += server.storage_size(:bulk)
        totals[:cost] += server.total_costs_per_day
      end
      totals
    end

    def headings
      headings = @options[:summary] ? [""] : %w[Name UUID Flavor Tags]
      headings.concat ["vCPU's", "Memory [GB]", "SSD [GB]", "Bulk [GB]", "CHF/day", "CHF/30-days"]
    end

    def rows
      rows = []
      unless @options[:summary]
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
      end
      rows
    end

    def totals
      totals = calculate_totals
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
