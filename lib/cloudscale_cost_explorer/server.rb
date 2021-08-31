require "cloudscale_cost_explorer/pricing"

module CloudscaleCostExplorer

  def self.tags_to_s(tag_hash = [])
    tag_hash.map {|k,v| "#{k}=#{v}" }.join(" ")
  end

  class Server
    def initialize(data)
      @data = data
      @total_storage_per_type = sum_up_storage_per_type
    end

    def name
      @data[:name]
    end

    def uuid
      @data[:uuid]
    end

    def flavor
      @data[:flavor][:slug]
    end

    def vcpu_count
      @data[:flavor][:vcpu_count]
    end

    def memory_gb
      @data[:flavor][:memory_gb]
    end

    def tags
      @data[:tags]
    end

    def tags_to_s
      CloudscaleCostExplorer::tags_to_s(tags)
    end

    def storage_size(type = :ssd)
      @total_storage_per_type[type] || 0
    end

    def server_costs_per_day
      Pricing.server_costs_per_day(@data[:flavor][:slug])
    end

    def storage_costs_per_day(type = :ssd)
      Pricing.storage_costs_per_day(type.to_s, storage_size(type))
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