# frozen_string_literal: true

require "thor"
require "tty-spinner"

module Cloudcost
  # Implementaion of CLI functionality
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
      output_servers(servers, options) do |result|
        spinner&.success("(done)")
        puts result
      end
    rescue Excon::Error, TokenError, ProfileError, PricingError => e
      error_message = "ERROR: #{e.message}"
      spinner ? spinner.error(error_message) : puts(error_message)
    end

    desc "server-tags", "show and assign tags of servers"
    option :name, desc: "filter name by regex", aliases: %w[-n]
    option :tag, desc: "filter by tag", aliases: %w[-t]
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
            begin
              api_connection(options).set_server_tags(server.uuid, tags)
              spinner.success
            rescue Excon::Error => e
              spinner.error "ERROR: #{e.message}"
            end
          end
        end
        spinners.auto_spin
      end
    rescue Cloudcost::TokenError, Cloudcost::ProfileError => e
      puts "ERROR: #{e.message}"
    end

    desc "volumes", "explore volumes"
    option :name, desc: "filter name by regex", aliases: %w[-n]
    option :tag, desc: "filter by tag", aliases: %w[-t]
    option :summary, desc: "display totals only", type: :boolean, aliases: %w[-S]
    option :type, enum: %w[ssd bulk], desc: "volume type"
    option :attached, type: :boolean, desc: "volume attached to servers"
    option :output, default: "table", enum: %w[table csv influx], desc: "output format", aliases: %w[-o]
    def volumes
      volumes = load_volumes(options)
      if options[:output] == "table"
        spinner = TTY::Spinner.new("[:spinner] Calculating costs...", clear: options[:csv])
        spinner.auto_spin
      end
      output_volumes(volumes, options) do |result|
        spinner&.success("(done)")
        puts result
      end
    rescue Excon::Error, Cloudcost::TokenError, Cloudcost::ProfileError, Cloudcost::PricingError => e
      error_message = "ERROR: #{e.message}"
      spinner ? spinner.error(error_message) : puts(error_message)
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
        servers = api_connection(options).get_servers(options).map { |server| Cloudcost::Server.new(server) }
        spinner&.success "(#{servers.size} found)"
        servers
      rescue Excon::Error => e
        spinner&.error "ERROR: #{e.message}"
        []
      end

      def load_volumes(options)
        if options[:output] == "table"
          spinner = TTY::Spinner.new("[:spinner] Loading volumes...", clear: options[:csv])
          spinner.auto_spin
        end
        volumes = api_connection(options).get_volumes(options).map { |volume| Cloudcost::Volume.new(volume) }
        spinner&.success "(#{volumes.size} found)"
        volumes
      rescue Excon::Error => e
        spinner&.error "\ERROR: #{e.message}"
        []
      end

      def output_servers(servers, options)
        if servers.empty?
          yield "WARNING: No servers found."
        elsif options[:group_by]
          yield Cloudcost::ServerList.new(servers, options).grouped_costs
        elsif options[:output] == "csv"
          yield Cloudcost::ServerList.new(servers, options).to_csv
        else
          if options[:output] == "influx"
            puts "ERROR: group-by option required for influx output"
            exit 1
          end
          yield Cloudcost::ServerList.new(servers, options).cost_table
        end
      end

      def output_volumes(volumes, options)
        if volumes.empty?
          yield "WARNING: No volumes found."
        elsif options[:output] == "csv"
          yield Cloudcost::VolumeList.new(volumes, options).to_csv
        elsif options[:output] == "influx"
          yield Cloudcost::VolumeList.new(volumes, options).totals_influx_line_protocol
        else
          yield Cloudcost::VolumeList.new(volumes, options).cost_table
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
