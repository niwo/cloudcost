require "thor"
require "terminal-table"
require "tty-spinner"

module CloudscaleCostExplorer

  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    def self.exit_on_failure?
      true
    end

    class_option :profile,
      desc: "cloudscale.ini profile name",
      aliases: %w(-p)

    class_option :api_token,
      desc: "cloudscale api token",
      aliases: %w(-t)

    desc "version", "app version"
    def version
      puts "v#{CloudscaleCostExplorer::VERSION}"
    end
    map %w(--version -v) => :version

    desc "servers", "explore servers"
    option :name, desc: "filter name by regex", aliases: %w(-n)
    option :tag, desc: "filter servers by tag", aliases: %w(-t)
    option :summary, desc: "display totals only", type: :boolean, aliases: %w(-S)
    def servers
      spinner =  TTY::Spinner.new("[:spinner] Loading servers...")
      begin
        api_token = options[:api_token] || CloudscaleCostExplorer::ApiToken.new(options).token
        api = CloudscaleCostExplorer::ApiConnection.new(api_token, options)
        spinner.auto_spin
        servers = api.get_servers(options).map { |server| Server.new(server) }
        spinner.success "(loaded #{servers.size} servers)"
        puts CloudscaleCostExplorer::ServerList.new(servers, options).table
      rescue Excon::Error, TokenError, ProfileError => e
        spinner.error("(ERROR: #{e.message})")
      end
    end

  end

end