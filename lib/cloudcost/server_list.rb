# frozen_string_literal: true

module Cloudcost
  # ServerList represents a list of servers and integrates several output methods
  class ServerList
    include Cloudcost::TabularOutput
    include Cloudcost::CsvOutput
    include Cloudcost::InfluxdbOutput

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

    def grouped_costs
      no_tag = "<no-tag>"
      group_rows = @servers.group_by { |s| s.tags[@options[:group_by].to_sym] || no_tag }.map do |name, servers|
        server_groups_data(name, servers).values.flatten
      end
      group_rows.sort! { |a, b| a[0] == no_tag ? 1 : a[0] <=> b[0] }
      case @options[:output]
      when "csv"
        groups_to_csv(group_rows)
      when "influx"
        grouped_influx_line_protocol(group_rows)
      else
        grouped_cost_table(group_rows)
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
  end
end
