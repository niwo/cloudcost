require 'terminal-table'
require 'tty-spinner'
require 'cloudscale_cost_explorer/server'

module CloudscaleCostExplorer

  def self.print_servers(servers, filters = {})
    if filters.has_key?(:name)
      servers = servers.select { |server| filters[:name].match? server[:name] }
    end
    table = Terminal::Table.new do |t|
      t.title = "cloudscale.ch Costs"
      t.headings = ['Name', 'Flavor', 'SSD', 'Bulk', 'CHF per Day', 'CHF per Month']
    end
    grand_total = 0
    servers.sort_by{|server| server[:name]}.each do |server_data| 
      server = Server.new(server_data)
      grand_total += server.total_costs_per_day
      table.add_row [
        server.name,
        server.flavor,
        server.storage_size(:ssd) > 0 ? "#{server.storage_size(:ssd)} GB" : "-",
        server.storage_size(:bulk) > 0 ? "#{server.storage_size(:bulk)} GB" : "-",
        sprintf("%.2f", server.total_costs_per_day.round(2)),
        "#{(server.total_costs_per_day * 30).round}.-"
      ]
    end

    table.add_separator
    table.add_row [
      'Total', '', '', '',
      "#{grand_total.round}.-",
      "#{(grand_total * 30).round.to_s.reverse.scan(/.{1,3}/).join("'").reverse}.-"
    ]
    (2..5).each {|column| table.align_column(column, :right) }
    puts table
  end

  def self.run
    spinner =  TTY::Spinner.new("[:spinner] Loading servers...")
    spinner.auto_spin
    begin
      servers = CloudscaleCostExplorer.load_servers
      spinner.success "(loaded #{servers.size} servers)"
      # You can filter names by regex, cool!
      # print_servers(servers, name: /ocp4.*/)
      print_servers(servers)
    rescue StandardError => e
      spinner.error("(#{e.message})")
    end
  end

end