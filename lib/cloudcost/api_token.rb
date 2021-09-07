# frozen_string_literal: true

require "parseconfig"
require "excon"
require "json"
require "cloudcost/error"

module Cloudcost
  class ApiToken
    attr_accessor :profile, :token

    def initialize(options = {})
      @profile = options[:profile]
      @token = load
    end

    def load
      api_token = nil
      if @profile
        api_token = get_from_profile
        raise ProfileError, "profile \"#{@profile}\" not found" unless api_token
      else
        api_token = ENV["CLOUDSCALE_API_TOKEN"]
        raise TokenError, "no CLOUDSCALE_API_TOKEN found in environment" unless api_token
      end
      api_token
    end

    def get_from_profile
      [
        "#{ENV["XDG_CONFIG_HOME"] || "#{ENV["HOME"]}/.config"}/cloudscale/cloudscale.ini",
        "#{ENV["HOME"]}/.cloudscale.ini",
        "#{ENV["PWD"]}/cloudscale.ini"
      ].each do |path|
        if File.exist? path
          config = ParseConfig.new(path)
          return config[@profile]["api_token"] if config.groups.include? @profile
        end
      end
      nil
    end
  end
end
