# frozen_string_literal: true

require "yaml"

PRICING = YAML.load_file("data/pricing.yml")

module Cloudcost
  class PricingError < StandardError
  end

  module Pricing
    def self.server_costs_per_day(flavor)
      PRICING["servers"][flavor] || raise(PricingError, "#{flavor} flavor not found in pricing.yml")
    end

    def self.storage_costs_per_day(type, size_in_gb)
      raise PricingError, "#{type} storage type not found in pricing.yml" unless PRICING["storage"][type]

      PRICING["storage"][type] * size_in_gb
    end
  end
end
