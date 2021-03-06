# frozen_string_literal: true

require "terminal-table"

module Cloudcost
  # volumeList represents a list of volumes and integrates several output methods
  class VolumeList
    include Cloudcost::CsvOutput
    include Cloudcost::VolumeInfluxdbOutput

    def initialize(volumes, options = {})
      @volumes = volumes
      @options = options
    end

    def calculate_totals(volumes = @volumes)
      total = { size: 0, size_ssd: 0, size_bulk: 0, cost: 0.0 }
      volumes.each do |volume|
        total[:size] += volume.size_gb
        total["size_#{volume.type}".to_sym] += volume.size_gb if %w[ssd bulk].include? volume.type
        total[:cost] += volume.costs_per_day
      end
      total
    end

    def totals(volumes = @volumes)
      total = calculate_totals(volumes)
      total_row = @options[:summary] ? %w[Total] : ["Total", "", "", "", ""]
      if @options[:summary]
        total_row.concat [
          total[:size_ssd],
          total[:size_bulk],
          total[:size]
        ]
      else
        total_row.concat [total[:size]]
      end
      total_row.concat [
        format("%.2f", total[:cost].round(2)),
        format("%.2f", (total[:cost] * 30).round(2))
      ]
    end

    def headings
      headings = if @options[:summary]
                   ["", "SSD [GB]", "Bulk [GB]", "Total [GB]"]
                 else
                   ["Name", "UUID", "Type", "Servers", "Tags", "Size [GB]"]
                 end
      headings.concat ["CHF/day", "CHF/30-days"]
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
  end
end
