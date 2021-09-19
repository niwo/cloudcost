# frozen_string_literal: true

module Cloudcost
  # InfluxDB output methods for the ServerList class
  module InfluxdbOutput
    def grouped_influx_line_protocol(group_rows)
      lines = []
      group_rows.each do |row|
        [
          { field: "server_count", position: 1, unit: "i" },
          { field: "vcpus", position: 2, unit: "i" },
          { field: "memory_gb", position: 3, unit: "i" },
          { field: "ssd_gb", position: 4, unit: "i" },
          { field: "bulk_gb", position: 5, unit: "i" },
          { field: "chf_per_day", position: 6, unit: "" }
        ].each do |field|
          lines << %(
            cloudscaleServerCosts,group=#{row[0]},profile=#{@options[:profile] || "?"}
            #{field[:field]}=#{row[field[:position]]}#{field[:unit]}
          ).gsub(/\s+/, " ").strip
        end
      end
      lines.join("\n")
    end
  end
end
