# frozen_string_literal: true

module Cloudcost
  # InfluxDB output methods for the ServerList class
  module VolumeInfluxdbOutput
    def totals_influx_line_protocol
      lines = []
      tag_set = [
        "profile=#{@options[:profile] || "?"}",
        "state=#{volumes_attached_state}"
      ]
      metrics = calculate_totals
      [
        { field: "ssd_gb", key: :size_ssd, unit: "i" },
        { field: "bulk_gb", key: :size_bulk, unit: "i" },
        { field: "chf_per_day", key: :size, unit: "" }
      ].each do |field|
        lines << %(
          cloudscaleVolumeCosts,#{tag_set.join(",")}
          #{field[:field]}=#{metrics[field[:key]]}#{field[:unit]}
        ).gsub(/\s+/, " ").strip
      end
      lines.join("\n")
    end

    def volumes_attached_state
      case @options[:attached]
      when true
        "attached"
      when false
        "unattached"
      else
        "all"
      end
    end
  end
end
