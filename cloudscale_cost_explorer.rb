#!/usr/bin/env ruby

require 'rubygems'
require 'excon'
require 'json'
require 'yaml'
require 'terminal-table'

API_TOKEN = ENV["CLOUDSCALE_API_TOKEN"]
AUTH_HEADER = { "Authorization" => "Bearer #{API_TOKEN}" }
PRICING = YAML.load_file('pricing.yml')

def print_servers(servers, filters = {})
  if filters.has_key?(:name)
    servers = servers.select { |server| filters[:name].match? server[:name] }
  end
  table = Terminal::Table.new do |t|
    t.title = "cloudscale.ch Costs"
    t.headings = ['Name', 'Flavor', 'SSD', 'Bulk', 'CHF per Day', 'CHF per Month']
  end
  grand_total = 0
  servers.sort_by{|server| server[:name]}.each do |server| 
    volumes = sumup_volumes(server[:volumes])
    server_costs = server_costs_per_day(server[:flavor][:slug])
    ssd_costs = storage_costs_per_day('ssd', volumes[:ssd] || 0)
    bulk_costs = storage_costs_per_day('bulk', volumes[:bulk] || 0)
    total = server_costs + ssd_costs + bulk_costs
    grand_total += total
    table.add_row [
      server[:name],
      server[:flavor][:slug],
      volumes[:ssd] ? "#{volumes[:ssd]} GB" : "-",
      volumes[:bulk] ? "#{volumes[:bulk]} GB" : "-",
      sprintf("%.2f", total.round(2)),
      "#{(total * 30).round}.-"
    ]
  end

  table.add_separator
  table.add_row [
    'Total', '', '', '',
    "#{grand_total.round}.-",
    "#{(grand_total * 30).round}.-"
  ]
  (2..5).each {|column| table.align_column(column, :right) }
  puts table
end

def server_costs_per_day(flavor)
  PRICING['servers'][flavor]
end

def storage_costs_per_day(type, size_in_gb)
  PRICING['storage'][type] * size_in_gb
end

def sumup_volumes(volumes)
  volumes_by_type = volumes.group_by {|volume| volume[:type].itself }
  sum = {}
  volumes_by_type.each do |group, vols|
    sum.store(group.to_sym,  0)
    vols.each do |volume|
      sum[volume[:type].to_sym] += volume[:size_gb]
    end
  end
  sum
end

def print_volumes(volumes)
  volumes.each do |volume|
    puts "#{volume[:type]} \t #{volume[:size_gb]}GB"
  end
end

connection = Excon.new(
  'https://api.cloudscale.ch',
  headers: AUTH_HEADER
)

response = connection.get(path: "v1/servers")

case response.data[:status]
when 200 then
  servers = JSON.parse(response.body, symbolize_names: true)
  #print_servers(servers, name: /ocp4.*/)
  print_servers(servers)
when 401
  puts "ERROR: Authentication failed!"
else 
  puts "ERROR: Something strange happened!"
  puts "\t HTTP Status code: #{response.data[:status]}"
end