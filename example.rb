#!/usr/bin/env ruby

require 'rubygems'
require 'rt/client' # requires ruby 1.8
require 'pp'


ticket_id = '1318622'
parent_id = '1258480'

rt = RT_Client.new
rt.add_link(:id => "ticket/#{ticket_id}", :MemberOf => '1258480')

links = rt.links(:id => ticket_id)

pp links

=begin
----
{:DependsOn=>"1258480", :id=>"1318622"}
----
"DependsOn: 1258480\nid: 1318622"
=end
