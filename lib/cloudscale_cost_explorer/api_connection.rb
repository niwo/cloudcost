require "parseconfig"

module CloudscaleCostExplorer
  class ApiConnection
    API_URL = 'https://api.cloudscale.ch'

    attr_accessor :connection

    def initialize(options = {})
      @api_url = options[:api_url] || API_URL
      @profile = options[:profile]
      @api_token = options[:api_token] || get_api_token()
      @connection = new_connection()
    end

    def get_resource(resource, options = {})
      path = "v1/#{resource}"
      path += "?tag:#{options[:tag]}" if options[:tag]
      response = @connection.get(path: path, expects: [200])
      JSON.parse(response.body, symbolize_names: true)
    end

    private

    def new_connection
      connection = Excon.new(
        @api_url, headers: auth_header()
      )
    end

    def get_api_token
      api_token = nil
      if @profile
        api_token = get_token_from_profile(@profile)
        raise("profile \"#{@profile}\" not found") unless api_token
      else
        api_token = ENV["CLOUDSCALE_API_TOKEN"]
        raise("no CLOUDSCALE_API_TOKEN found in environment") unless api_token
      end
      api_token
    end

    def get_token_from_profile(profile = @profile)
      [
        "#{ENV['XDG_CONFIG_HOME'] || ENV['HOME'] + '/.config' }/cloudscale/cloudscale.ini",
        "#{ENV['HOME']}/.cloudscale.ini",
        "#{ENV['PWD']}/cloudscale.ini"
      ].each do |path|
        if File.exists? path
          config = ParseConfig.new(path)
          return config[profile]["api_token"]
        end
      end
      nil
    end

    def auth_header
      { "Authorization" => "Bearer #{@api_token}" }
    end

  end
end