require "cloudscale_cost_explorer/pricing"
require 'excon'
require 'json'

module CloudscaleCostExplorer
  API_TOKEN = ENV["CLOUDSCALE_API_TOKEN"]
  AUTH_HEADER = { "Authorization" => "Bearer #{API_TOKEN}" }

  def self.load_servers
    connection = Excon.new(
      'https://api.cloudscale.ch',
      headers: AUTH_HEADER
    )
    response = connection.get(path: "v1/servers", expects: [200])
    JSON.parse(response.body, symbolize_names: true)
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