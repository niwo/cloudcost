# frozen_string_literal: true

require "excon"
require "json"

module Cloudcost
  # Connecting to and accessing the cloudscale.ch API
  class ApiConnection
    API_URL = "https://api.cloudscale.ch"

    attr_accessor :connection

    def initialize(api_token, options = {})
      @api_url = options[:api_url] || API_URL
      @api_token = api_token
      @connection = new_connection
    end

    def get_resource(resource, options = {})
      path = "v1/#{resource}"
      path += "?tag:#{options[:tag]}" if options[:tag]
      response = @connection.get(path: path, expects: [200])
      JSON.parse(response.body, symbolize_names: true)
    end

    def get_servers(options = {})
      servers = get_resource("servers", options)
      servers = servers.reject { |server| server[:tags].key?(options[:missing_tag].to_sym) } if options[:missing_tag]
      servers = servers.select { |server| /#{options[:name]}/.match? server[:name] } if options[:name]
      servers
    end

    def set_server_tags(uuid, tags)
      @connection.patch(
        path: "v1/servers/#{uuid}",
        body: { tags: tags }.to_json,
        headers: { "Content-Type": "application/json" },
        expects: [204]
      )
    end

    def get_volumes(options = {})
      volumes = get_resource("volumes", options)
      volumes = volumes.reject { |volume| volume[:tags].key?(options[:missing_tag].to_sym) } if options[:missing_tag]
      volumes = volumes.select { |volume| /#{options[:name]}/.match? volume[:name] } if options[:name]
      volumes = volumes.select { |volume| /#{options[:type]}/.match? volume[:type] } if options[:type]
      unless options[:attached].nil?
        volumes = volumes.select do |volume|
          (volume[:servers].size.positive?) == options[:attached]
        end
      end
      volumes
    end

    private

    def new_connection
      Excon.new(
        @api_url, headers: auth_header
      )
    end

    def auth_header
      { "Authorization" => "Bearer #{@api_token}" }
    end
  end
end
