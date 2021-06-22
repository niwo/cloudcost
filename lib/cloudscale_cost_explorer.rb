require 'thor'
require 'terminal-table'
require 'tty-spinner'
require 'cloudscale_cost_explorer/version'
require 'cloudscale_cost_explorer/server'

module CloudscaleCostExplorer

  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    desc 'version', 'app version'
    def version
      puts "v#{CloudscaleCostExplorer::VERSION}"
    end
    map %w(--version -v) => :version

    desc "servers", "explore servers"
    option :name_filter, desc: "filter name by regex"
    option :tag_filter, desc: "filter servers by tag"
    def servers
      spinner =  TTY::Spinner.new("[:spinner] Loading servers...")
      spinner.auto_spin
      begin
        servers = CloudscaleCostExplorer.load_servers(options['tag_filter'])
        spinner.success "(loaded #{servers.size} servers)"
        CloudscaleCostExplorer.print_servers(servers, options)
      rescue StandardError => e
        spinner.error("(#{e.message})")
      end
    end

  end

end