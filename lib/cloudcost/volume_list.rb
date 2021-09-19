# frozen_string_literal: true

module Cloudcost
  # volumeList represents a list of volumes and integrates several output methods
  class VolumeList

    def initialize(volumes, options = {})
      @volumes = volumes
      @options = options
    end

    def calculate_totals(volumes = @volumes)
      total = { size: 0, cost: 0.0 }
      volumes.each do |volume|
        total[:size] += volume.size_gb
        total[:cost] += volume.costs_per_day
      end
      total
    end

    def totals(volumes = @volumes)
      total = calculate_totals(volumes)
      total_row = @options[:summary] ? %w[Total] : ["Total", "", "", "", ""]
      total_row.concat [
        total[:size],
        format("%.2f", total[:cost].round(2)),
        format("%.2f", (total[:cost] * 30).round(2))
      ]
    end

    def headings
      headings = if @options[:summary]
                   [""]
                 elsif @options[:group_by]
                   %w[Group Volumes]
                 else
                   %w[Name UUID Type Servers Tags]
                 end
      headings.concat ["Size [GB]", "CHF/day", "CHF/30-days"]
    end

    def rows
      rows = []
      @volumes.sort_by(&:name).map do |volume|
        rows << [
          volume.name,
          volume.uuid,
          volume.type,
          volume.server_name,
          volume.tags_to_s,
          volume.size_gb,
          format("%.2f", volume.costs_per_day.round(2)),
          format("%.2f", (volume.costs_per_day * 30).round(2))
        ]
      end
      rows
    end

    def cost_table
      table = Terminal::Table.new do |t|
        t.title = "cloudscale.ch volume costs"
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
        t.title = "cloudscale.ch volume costs grouped by tag \"#{@options[:group_by]}\""
        t.title += " (#{@options[:profile]})" if @options[:profile]
        t.headings = headings
      end
      table.rows = group_rows
      (1..table.columns.size).each { |column| table.align_column(column, :right) }
      table
    end

  end
end
