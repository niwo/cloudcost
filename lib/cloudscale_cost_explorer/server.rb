require "cloudscale_cost_explorer/pricing"
require 'excon'
require 'json'

module CloudscaleCostExplorer
  API_TOKEN = ENV["CLOUDSCALE_API_TOKEN"]
  AUTH_HEADER = { "Authorization" => "Bearer #{API_TOKEN}" }

  def self.load_servers(tag)
    connection = Excon.new(
      'https://api.cloudscale.ch',
      headers: AUTH_HEADER
    )
    path = "v1/servers"
    path += "?tag:#{tag}" if tag
    response = connection.get(path: path, expects: [200])
    JSON.parse(response.body, symbolize_names: true)
  end

  def self.print_servers(servers, filters = {})
    if filters.has_key?("name_filter")
      servers = servers.select { |server| /#{filters["name_filter"]}/.match? server[:name] }
    end
    table = Terminal::Table.new do |t|
      t.title = "cloudscale.ch Costs"
      t.headings = ['Name', 'Flavor', 'SSD', 'Bulk', 'CHF per Day', 'CHF per Month']
    end
    grand_total = 0
    servers.sort_by{|server| server[:name]}.each do |server_data| 
      server = Server.new(server_data)
      grand_total += server.total_costs_per_day
      table.add_row [
        server.name,
        server.flavor,
        server.storage_size(:ssd) > 0 ? "#{server.storage_size(:ssd)} GB" : "-",
        server.storage_size(:bulk) > 0 ? "#{server.storage_size(:bulk)} GB" : "-",
        sprintf("%.2f", server.total_costs_per_day.round(2)),
        "#{(server.total_costs_per_day * 30).round}.-"
      ]
    end

    table.add_separator
    table.add_row [
      'Total', '', '', '',
      "#{grand_total.round}.-",
      "#{(grand_total * 30).round.to_s.reverse.scan(/.{1,3}/).join("'").reverse}.-"
    ]
    (2..5).each {|column| table.align_column(column, :right) }
    puts table
  end

  class Server
    def initialize(data)
      @data = data
      @total_storage_per_type = sum_up_storage_per_type
    end

    def name
      @data[:name]
    end

    def flavor
      @data[:flavor][:slug]
    end

    def storage_size(type = :ssd)
      @total_storage_per_type[type] || 0
    end

    def server_costs_per_day
      Pricing.server_costs_per_day(@data[:flavor][:slug])
    end

    def storage_costs_per_day(type = :ssd)
      Pricing.storage_costs_per_day(type.to_s, @total_storage_per_type[type] || 0)
    end

    def total_costs_per_day
      server_costs_per_day + storage_costs_per_day(:ssd) + storage_costs_per_day(:bulk) 
    end

    def sum_up_storage_per_type
      sum = {}
      @data[:volumes].group_by {|volume| volume[:type].itself }.each do |group, vols|
        sum.store(group.to_sym,  0)
        vols.each { |volume| sum[volume[:type].to_sym] += volume[:size_gb] }
      end
      sum
    end

  end
end