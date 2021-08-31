require "excon"
require "json"

module CloudscaleCostExplorer
  class ApiConnection
    API_URL = 'https://api.cloudscale.ch'

    attr_accessor :connection

    def initialize(api_token, options = {})
      @api_url = options[:api_url] || API_URL
      @api_token = api_token
      @connection = new_connection()
    end

    def get_resource(resource, options = {})
      path = "v1/#{resource}"
      path += "?tag:#{options[:tag]}" if options[:tag]
      response = @connection.get(path: path, expects: [200])
      JSON.parse(response.body, symbolize_names: true)
    end

    def get_servers(options = {})
      servers = get_resource("servers", options)
      if options[:name]
        servers = servers.select { |server| /#{options[:name]}/.match? server[:name] }
      end
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

    private

    def new_connection
      connection = Excon.new(
        @api_url, headers: auth_header()
      )
    end

    def auth_header
      { "Authorization" => "Bearer #{@api_token}" }
    end

  end
end