# frozen_string_literal: true

module Cloudcost
  # Representation of cloudscale.ch volume object
  class Volume
    attr_accessor :data

    def initialize(data)
      @data = data
    end

    def name
      @data[:name]
    end

    def uuid
      @data[:uuid]
    end

    def type
      @data[:type]
    end

    def servers
      @data[:servers]
    end

    def server_name
      servers.size.positive? ? servers.first[:name] : ""
    end

    def attached?
      servers.size.positive?
    end

    def server_uuids
      @data[:server_uuids]
    end

    def tags
      @data[:tags]
    end

    def size_gb
      @data[:size_gb]
    end

    def tags_to_s
      Cloudcost.tags_to_s(tags)
    end

    def costs_per_day
      Pricing.storage_costs_per_day(type, size_gb)
    end
  end
end
