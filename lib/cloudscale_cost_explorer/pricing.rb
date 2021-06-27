
require "yaml"

PRICING = YAML.load_file("data/pricing.yml")

module CloudscaleCostExplorer
  module Pricing
    def self.server_costs_per_day(flavor)
      PRICING["servers"][flavor]
    end
  
    def self.storage_costs_per_day(type, size_in_gb)
      PRICING["storage"][type] * size_in_gb
    end
  end
end
