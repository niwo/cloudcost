require 'thor'
require 'terminal-table'
require 'tty-spinner'
require 'cloudscale_cost_explorer/version'
require "cloudscale_cost_explorer/api_connection"
require 'cloudscale_cost_explorer/server'

module CloudscaleCostExplorer

  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    class_option :profile,
      desc: "cloudscale.ini profile name",
      aliases: %w(-p)

    class_option :api_token,
      desc: "cloudscale api token",
      aliases: %w(-t)

    desc 'version', 'app version'
    def version
      puts "v#{CloudscaleCostExplorer::VERSION}"
    end
    map %w(--version -v) => :version

    desc "servers", "explore servers"
    option :name, desc: "filter name by regex", aliases: %w(-n)
    option :tag, desc: "filter servers by tag", aliases: %w(-t)
    def servers
      spinner =  TTY::Spinner.new("[:spinner] Loading servers...")
      begin
        connection = CloudscaleCostExplorer::ApiConnection.new(options)
        spinner.auto_spin
        servers = CloudscaleCostExplorer.get_servers(connection, options)
        spinner.success "(loaded #{servers.size} servers)"
        CloudscaleCostExplorer.print_servers(servers, options)
      rescue StandardError => e
        spinner.error("(ERROR: #{e.message})")
      end
    end

  end

end