#!/opt/ruby-enterprise-1.8.7-2010.02/bin/ruby

## XML RPC service to provide a cross-platform API for
## RT ticket creation/maintenance.  Essentially just a wrapper
## around the rt/client library.

require "rubygems"             # so we can load gems
require "rt/client"            # rt-client REST library
require "xmlrpc/server"        # that's what we're doing
require "date"                 # for parsing arbitrary date formats
require "pp"

PORT=8080
MAX_CONN=50

# extend the Hash class to 
# translate string keys into symbol keys
class Hash # :nodoc:
  def remapkeys!
    n = Hash.new
    self.each_key do |key|
      n[key.to_sym] = self[key]
    end
    self.replace(n)
    n = nil
    $stderr.puts self.map { |k,v| "#{k} => #{v}" }
    self
  end
end

class TicketSrv

  def initialize
  end
  
  INTERFACE = XMLRPC::interface("rt") {
    meth 'string add_watcher(struct)','Calls RT_Client::add_watcher'
    meth 'array attachments(struct)','Calls RT_Client::attachments'
    meth 'string comment(struct)','Calls RT_Client::comment'
    meth 'string correspond(struct)','Calls RT_Client::correspond'
    meth 'string create(struct)','Calls RT_Client::create'
    meth 'string create_user(struct)','Calls RT_Client::create_user'
    meth 'string edit(struct)','Calls RT_Client::edit'
    meth 'string edit_or_create_user(struct)','Calls RT_Client::edit_or_create_user'
    meth 'struct get_attachment(struct)','Calls RT_Client::get_attachment'
    meth 'struct history(struct)','Calls RT_Client::history (long form)'
    meth 'struct history_item(struct)','Calls RT_Client::history_item'
    meth 'array list(struct)','Calls RT_Client::list'
    meth 'array query(struct)','Calls RT_Client::query (long form)'
    meth 'struct show(struct)','Calls RT_Client::show'
  }

  # Allows watchers to be added via RT_Client::add_watcher
  # You need to pass :id, :addr, and optionally :type
  def add_watcher(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.add_watcher(struct)
    rt = nil
    val
  end

  # Gets a list of attachments via RT_Client::attachments
  # You need to pass :id, and optionally :unnamed
  def attachments(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    rt = RT_Client.new
    val = rt.attachments(struct)
    rt = nil
    val
  end

  # Adds comments to tickets via RT_Client::comment
  def comment(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.comment(struct)
    rt = nil
    val
  end

  # Allows new tickets to be created via RT_Client::correspond
  def correspond(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.correspond(struct)
    rt = nil
    val
  end

  # Allows new tickets to be created via RT_Client::create
  def create(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.create(struct)
    rt = nil
    val
  end

  # Allows new users to be created via RT_Client::create_user
  def create_user(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.create_user(struct)
    rt = nil
    val
  end

  # Find RT user details from email address via RT_Cleint::usersearch
  def usersearch(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.usersearch(struct)
    rt = nil
    val
  end

  # Allows new users to be edited or created if they don't exist
  def edit_or_create_user(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.edit_or_create_user(struct)
    rt = nil
    val
  end

  # Allows existing ticket to be modified via RT_Client::edit
  def edit(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.edit(struct)
    rt = nil
    val
  end

  # Retrieves attachments via RT_Client::get_attachment
  def get_attachment(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.get_attachment(struct)
    rt = nil
    val
  end

  # Gets the history of a ticket via RT_Client::history
  def history(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.history(struct)
    rt = nil
    val
  end

  # Gets a single history item via RT_Client::history_item
  def history_item(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.history_item(struct)
    rt = nil
    val
  end

  # Gets a list of tickets via RT_Client::list
  def list(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.list(struct)
    rt = nil
    val
  end

  # Gets a list of tickets via RT_Client::query
  def query(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.query(struct)
    rt = nil
    val
  end

  # Gets detail (minus history/attachments) via RT_Client::show
  def show(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
    else
      rt = RT_Client.new
    end
    val = rt.show(struct)
    rt = nil
    val
  end
  
end # class TicketSrv

pid = fork do
  Signal.trap('HUP','IGNORE')
  # set up a log file
  logfile = File.dirname(__FILE__) + "/ticketsrv.log"
  accfile = File.dirname(__FILE__) + "/access.log"
  acc = File.open(accfile,"a+")
  $stderr.reopen acc # redirect $stderr to the log as well
  # determine the IP address to listen on and create the server
  sock = Socket.getaddrinfo(Socket.gethostname,PORT,Socket::AF_INET,Socket::SOCK_STREAM)
  $s = XMLRPC::Server.new(sock[0][1], sock[0][3], MAX_CONN, logfile)
  $s.set_parser(XMLRPC::XMLParser::XMLStreamParser.new)
  $s.add_handler(TicketSrv::INTERFACE, TicketSrv.new)
  $s.add_introspection
  $s.serve  # start serving
  $stderr.reopen STDERR
  acc.close
end
Process.detach(pid)
                              