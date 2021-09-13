# frozen_string_literal: true

require "thor"
require "tty-spinner"

module Cloudcost
  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    def self.exit_on_failure?
      true
    end

    class_option :profile,
                 desc: "cloudscale.ini profile name",
                 aliases: %w[-p]

    class_option :api_token,
                 desc: "cloudscale api token",
                 aliases: %w[-a]

    desc "version", "app version"
    def version
      puts "cloudcost v#{Cloudcost::VERSION}"
    end
    map %w[--version -v] => :version

    desc "servers", "explore servers"
    option :name, desc: "filter name by regex", aliases: %w[-n]
    option :tag, desc: "filter servers by tag", aliases: %w[-t]
    option :summary, desc: "display totals only", type: :boolean, aliases: %w[-S]
    option :group_by, desc: "group by tag", aliases: %w[-G]
    option :output, default: "table", enum: %w[table csv influx], desc: "output format", aliases: %w[-o]
    def servers
      servers = load_servers(options)
      if options[:output] == "table"
        spinner = TTY::Spinner.new("[:spinner] Calculating costs...", clear: options[:csv])
        spinner.auto_spin
      end
      output(servers, options) do |result|
        spinner.success("(done)") if spinner
        puts result
      end
    rescue Excon::Error, TokenError, ProfileError, PricingError => e
      error_message = "ERROR: #{e.message}"
      if spinner
        spinner.error("(#{error_message})")
      else
        puts error_message
      end
    end

    desc "server-tags", "show and assign tags of servers"
    option :name, desc: "filter name by regex", aliases: %w[-n]
    option :tag, desc: "filter servers by tag", aliases: %w[-t]
    option :set_tags,
           desc: "set tags",
           aliases: %w[-T],
           type: :array
    option :remove_tags,
           desc: "remove tags",
           aliases: %w[-D],
           type: :array
    option :missing_tag,
           desc: "show severs with missing tags",
           aliases: %w[-M]
    def server_tags
      servers = load_servers(options)
      servers.size.positive? ? puts(Cloudcost::ServerList.new(servers, options).tags_table) : exit
      if (options[:set_tags] || options[:remove_tags]) && ask(
        "Do you want to #{tag_option_to_s(options)}?",
        default: "n"
      ) == "y"
        spinners = TTY::Spinner::Multi.new("[:spinner] Settings server tags")
        servers.each do |server|
          spinners.register("[:spinner] #{server.name}") do |spinner|
            tags = server.tags.merge(options[:set_tags] ? tags_to_h(options[:set_tags]) : {})
            (options[:remove_tags] || []).each do |tag|
              tags.reject! { |k| k == tag.to_sym }
            end
            api_connection(options).set_server_tags(server.uuid, tags)
            spinner.success
          end
        end
        spinners.auto_spin
      end
    rescue Excon::Error, TokenError, ProfileError => e
      error_message = "ERROR: #{e.message}"
      if defined?(spinner)
        spinner.error("(#{error_message})")
      else
        puts error_message
      end
    end

    no_tasks do
      def tags_to_h(tags_array)
        tags_hash = {}
        tags_array.each do |tag|
          k_v = tag.split("=")
          tags_hash[k_v[0].to_sym] = k_v[1]
        end
        tags_hash
      end

      def api_connection(options)
        api_token = options[:api_token] || Cloudcost::ApiToken.new(options).token
        Cloudcost::ApiConnection.new(api_token, options)
      end

      def load_servers(options)
        if options[:output] == "table"
          spinner = TTY::Spinner.new("[:spinner] Loading servers...", clear: options[:csv])
          spinner.auto_spin
        end
        servers = api_connection(options).get_servers(options).map { |server| Server.new(server) }
        spinner.success "(#{servers.size} found)" if spinner
        servers
      end

      def output(servers, options)
        if options[:group_by]
          yield Cloudcost::ServerList.new(servers, options).grouped_cost_table
        elsif options[:output] == "csv"
          yield Cloudcost::ServerList.new(servers, options).to_csv
        else
          yield Cloudcost::ServerList.new(servers, options).cost_table
        end
      end

      def tag_option_to_s(options)
        messages = []
        messages << "set tags \"#{options[:set_tags].join(", ")}\"" if options[:set_tags]
        messages << "remove tags \"#{options[:remove_tags].join(", ")}\"" if options[:remove_tags]
        messages.join(" and ")
      end
    end
  end
end
