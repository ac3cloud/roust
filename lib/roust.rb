require 'httparty'
require 'mail'
require 'active_support/core_ext/hash'

class Unauthenticated < Exception ; end

class Roust
  include HTTParty
  #debug_output

  def initialize(credentials)
    server   = credentials[:server]
    username = credentials[:username]
    password = credentials[:password]

    self.class.base_uri(server)

    response = self.class.post(
      '/index.html',
      :body => {
        :user => username,
        :pass => password
      }
    )

    if cookie = response.headers['set-cookie']
      self.class.headers['Cookie'] = cookie
    end

    self.class.base_uri "#{server}/REST/1.0"

    # - There is no way to authenticate against the API. The only way to log
    #   in is to fill out the same HTML form humans fill in, cache the cookies
    #   returned, and send them on every subsequent request.
    # - RT does not provide *any* indication that the authentication request
    #   has succeeded or failed. RT will always return a HTTP 200.
    # - The easiest way to programatically check if an authentication request
    #   succeeded is by doing a request for a ticket, and seeing if the API
    #   responds with some specific text ("401 Credentials required") that
    #   indicates authentication has previously failed.
    # - The authenticated? method will raise an Unauthenticated exception if
    #   it detects a response including this "401 Credentials required" string.
    authenticated?
  end

  def show(id)
    response = self.class.get("/ticket/#{id}/show")

    body, status = handle_response(response)

    if match = body.match(/^# (Ticket (\d+) does not exist\.)/)
      return { 'error' => match[1] }
    end

    # Replace CF spaces with underscores
    while body.match(/CF\.\{[\w_ ]*[ ]+[\w ]*\}/)
      body.gsub!(/CF\.\{([\w_ ]*)([ ]+)([\w ]*)\}/, 'CF.{\1_\3}')
    end

    # Sometimes the API returns requestors formatted like this:
    #
    #   Requestors: foo@example.org,
    #               bar@example.org, baz@example.org
    #               qux@example.org, quux@example.org,
    #               corge@example.org
    #
    # Turn it into this:
    #
    #   Requestors: foo@example.org, bar@example.org, baz@example.org, ...
    #
    body.gsub!(/\n\n/, "\n")

    %w(Requestors Cc AdminCc).each do |field|
      body.gsub!(/^#{field}:(.+)^\n/m) do |match|
        match.strip.split(/,\s+/).join(', ').strip
      end
    end

    message = Mail.new(body)

    hash = Hash[message.header.fields.map {|header|
      key   = header.name.to_s
      value = header.value.to_s
      [ key, value ]
    }]

    %w(Requestors Cc AdminCc).each do |field|
      hash[field] = hash[field].split(', ') if hash[field]
    end

    hash["id"] = hash["id"].split('/').last

    hash
  end

  def create(attrs)
    default_attrs = {
      'id' => 'ticket/new'
    }
    attrs = default_attrs.merge(attrs).stringify_keys!

    if error = create_invalid?(attrs)
      return {'error' => error }
    end

    attrs['Text'].gsub!(/\n/,"\n ") if attrs['Text'] # insert a space on continuation lines.

    # We can't set more than one AdminCc when creating a ticket. WTF RT.
    #
    # Delete it from the ticket we are creating, and we'll update the ticket
    # after we've created.
    admincc = attrs.delete("AdminCc")

    content = attrs.map { |k,v|
      # Don't lowercase strings if they're already camel cased.
      k = case
      when k.is_a?(Symbol)
        k.to_s
      when k == 'id'
        k
      when k =~ /^[a-z]/
        k.capitalize
      else
        k
      end

      v = v.join(', ') if v.respond_to?(:join)

      "#{k}: #{v}"
    }.join("\n")

    response = self.class.post(
      "/ticket/new",
      :body => {
        :content => content
      },
    )

    body, status = handle_response(response)

    case body
    when /^# Could not create ticket/
      false
    when /^# Syntax error/
      false
    when /^# Ticket (\d+) created/
      id = body[/^# Ticket (\d+) created/, 1]
      update(id, 'AdminCc' => admincc) if admincc
      show(id)
    else
      # We should never hit this, but if we do, just pass it through and
      # surprise the user (!!!).
      body
    end
  end

  def update(id, attrs)
    default_attrs = {
      'id' => "ticket/#{id}"
    }
    attrs = default_attrs.merge(attrs).stringify_keys!

    content = attrs.map { |k,v|
      # Don't lowercase strings if they're already camel cased.
      k = case
      when k.is_a?(Symbol)
        k.to_s
      when k == 'id'
        k
      when k =~ /^[a-z]/
        k.capitalize
      else
        k
      end

      v = v.join(', ') if v.respond_to?(:join)

      "#{k}: #{v}"
    }.join("\n")

    response = self.class.post(
      "/ticket/#{id}/edit",
      :body => {
        :content => content
      },
    )

    body, status = handle_response(response)

    case body
    when /^# You are not allowed to modify ticket \d+/
      { 'error' => body.strip }
    when /^# Syntax error/
      { 'error' => body.strip }
    when /^# Ticket (\d+) updated/
      id = body[/^# Ticket (\d+) updated/, 1]
      show(id)
    else
      # We should never hit this, but if we do, just pass it through and
      # surprise the user (!!!).
      body
    end
  end

  def authenticated?
    return true if show('1')
  end

  def search(query)
    params = {
      :query  => query,
      :format => 's',
      :orderby => '+id'
    }
    response = self.class.get("/search/ticket", :query => params)
    body = response.body
    body.gsub!(/RT\/\d+\.\d+\.\d+\s\d{3}\s.*\n\n/,"")

    body.split("\n").map do |t|
      id, subject = t.split(': ', 2)
      {'id' => id, 'Subject' => subject}
    end
  end

  def history(id, opts={})
    options = {
      :format   => 'short',
      :comments => false
    }.merge(opts)

    format   = options[:format]
    comments = options[:comments]
    params = {
      :format => format[0]
    }

    response = self.class.get("/ticket/#{id}/history", :query => params)

    body, status = handle_response(response)

    case format
    when 'short'
      parse_short_history(body, :comments => comments)
    when 'long'
      parse_long_history(body, :comments => comments)
    end
  end

  # id can be numeric (e.g. 28) or textual (e.g. john)
  def user(id)
    response = self.class.get("/user/#{id}")

    body, status = handle_response(response)
    case body
    when /No user named/
     nil
    else
      body.gsub!(/\n\s*\n/,"\n") # remove blank lines for Mail
      message = Mail.new(body)
      Hash[message.header.fields.map {|header|
        key   = header.name.to_s.downcase
        value = header.value.to_s
        [ key, value ]
      }]
    end
  end

  # id can be numeric (e.g. 28) or textual (e.g. sales)
  def queue(id)
    response = self.class.get("/queue/#{id}")

    body, status = handle_response(response)
    case body
    when /No queue named/
      nil
    else
      body.gsub!(/\n\s*\n/,"\n") # remove blank lines for Mail
      message = Mail.new(body)
      Hash[message.header.fields.map {|header|
        key   = header.name.to_s.downcase
        value = header.value.to_s
        [ key, value ]
      }]
    end
  end

  private
  def handle_response(response)
    body   = response.body
    status = body[/RT\/\d+\.\d+\.\d+\s(\d{3}\s.*)\n/, 1]

    body.gsub!(/RT\/\d+\.\d+\.\d+\s\d{3}\s.*\n/,"")
    body = body.empty? ? nil : body.lstrip

    raise Unauthenticated, "Invalid username or password" if status =~ /401 Credentials required/

    return body, status
  end

  def create_invalid?(attrs)
    missing = %w(id Subject Queue).find_all {|k| !attrs.include?(k) }

    if missing.empty?
      return false
    else
      "Needs attributes: #{missing.join(', ')}"
    end
  end

  def parse_short_history(body, opts={})
    comments = opts[:comments]
    regex    = comments ? '^\d+:' : '^\d+: [^Comments]'
    history  = body.split("\n").select { |l| l =~ /#{regex}/ }
    history.map { |l| l.split(": ", 2) }
  end

  def parse_long_history(body, opts={})
    comments = opts[:comments]
    items = body.split("\n--\n")
    list = []
    items.each do |item|
      # Yes, this messes with the "content:" field but that's the one that's upsetting Mail.new
      item.gsub!(/\n\s*\n/,"\n") # remove blank lines for Mail
      history = Mail.new(item)
      next if not comments and history['type'].to_s =~ /Comment/ # skip comments
      reply = {}

      history.header.fields.each_with_index do |header, index|
        next if index == 0

        key   = header.name.to_s.downcase
        value = header.value.to_s

        attachments = []
        case key
        when "attachments"
          temp = item.match(/Attachments:\s*(.*)/m)
          if temp.class != NilClass
            atarr = temp[1].split("\n")
            atarr.map { |a| a.gsub!(/^\s*/,"") }
            atarr.each do |a|
              i = a.match(/(\d+):\s*(.*)/)
              s = {
                :id   => i[1].to_s,
                :name => i[2].to_s
              }
              sz = i[2].match(/(.*?)\s*\((.*?)\)/)
              if sz.class == MatchData
                s[:name] = sz[1].to_s
                s[:size] = sz[2].to_s
              end
              attachments << s
            end
            reply["attachments"] = attachments
          end
        when "content"
          reply["content"] = value
        else
          reply["#{key}"] = value
        end
      end
      list << reply
    end

    return list
  end
end
