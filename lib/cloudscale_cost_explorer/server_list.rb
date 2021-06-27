module CloudscaleCostExplorer

  class ServerList

    def initialize(servers, options = {})
      @servers = servers
      @options = options
      @totals = calculate_totals()
    end

    def calculate_totals
      totals = { vcpu: 0, memory: 0, ssd: 0, bulk: 0, cost: 0.0 }
      @servers.each do |server|
        totals[:vcpu] += server.vcpu_count
        totals[:memory] += server.memory_gb
        totals[:ssd] += server.storage_size(:ssd)
        totals[:bulk] += server.storage_size(:bulk)
        totals[:cost] += server.total_costs_per_day
      end
      totals
    end

    def table
      table = Terminal::Table.new do |t|
        t.title = "cloudscale.ch costs"
        t.title += " (#{@options[:profile]})" if @options[:profile]
        headings = @options[:summary] ? [""] : ["Name", "Flavor"] 
        headings.concat ["vCPU's", "Memory", "SSD", "Bulk", "CHF per day", "CHF per month"]
        t.headings = headings
      end
  
      unless @options[:summary]
        @servers.sort_by{ |s| s.name }.each do |server|
            table.add_row [
              server.name,
              server.flavor,
              server.vcpu_count,
              server.memory_gb,
              server.storage_size(:ssd) > 0 ? "#{server.storage_size(:ssd)} GB" : "-",
              server.storage_size(:bulk) > 0 ? "#{server.storage_size(:bulk)} GB" : "-",
              sprintf("%.2f", server.total_costs_per_day.round(2)),
              "#{(server.total_costs_per_day * 30).round}.-"
            ]
        end
      end
  
      table.add_separator unless @options[:summary]
      total_row = @options[:summary] ? %w(Total) : ["Total", ""]
      total_row.concat [
        @totals[:vcpu], 
        "#{@totals[:memory]} GB",
        "#{@totals[:ssd]} GB",
        "#{@totals[:bulk]} GB",
        "#{@totals[:cost].round}.-",
        "#{(@totals[:cost] * 30).round.to_s.reverse.scan(/.{1,3}/).join("'").reverse}.-"
      ]  
      table.add_row total_row
      first_number_row = @options[:summary] ? 1 : 2
      (first_number_row..table.columns.size).each {|column| table.align_column(column, :right) }
      table
    end

  end

end