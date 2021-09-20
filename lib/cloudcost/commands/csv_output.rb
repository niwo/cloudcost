# frozen_string_literal: true

module Cloudcost
  # generic CSV output methods
  module CsvOutput
    def groups_to_csv(group_rows)
      CSV.generate do |csv|
        csv << headings
        group_rows.each { |row| csv << row }
      end
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
