# frozen_string_literal: true

module Cloudcost
  # Tabular output methods for the ServerList class
  module TabularOutput
    def headings
      headings = if @options[:summary]
                   [""]
                 elsif @options[:group_by]
                   %w[Group Servers]
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

    def grouped_cost_table(group_rows)
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
end
