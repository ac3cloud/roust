#!/usr/bin/env ruby

require 'rubygems'
require 'rt/client' # requires ruby 1.8
require 'pp'


ticket_id = '1318622'
parent_id = '1258480'

rt = RT_Client.new
rt.add_link(:id => ticket_id, :MemberOf => parent_id)
rt.links(:id => ticket_id)

