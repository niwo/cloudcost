require "parseconfig"
require "excon"
require "json"
require "cloudscale_cost_explorer/error"


module CloudscaleCostExplorer
  class ApiToken

    attr_accessor :profile
    attr_accessor :token

    def initialize(options = {})
      @profile = options[:profile]
      @token = load 
    end

    def load
      api_token = nil
      if @profile
        api_token = get_from_profile
        unless api_token
          raise ProfileError, "profile \"#{@profile}\" not found"
        end
      else
        api_token = ENV["CLOUDSCALE_API_TOKEN"]
        unless api_token
          raise TokenError, "no CLOUDSCALE_API_TOKEN found in environment"
        end
      end
      api_token
    end

    def get_from_profile
      [
        "#{ENV['XDG_CONFIG_HOME'] || ENV['HOME'] + '/.config' }/cloudscale/cloudscale.ini",
        "#{ENV['HOME']}/.cloudscale.ini",
        "#{ENV['PWD']}/cloudscale.ini"
      ].each do |path|
        if File.exists? path
          config = ParseConfig.new(path)
          if config.groups.include? @profile
            return config[@profile]["api_token"]
          end
        end
      end
      nil
    end

  end
end