module Roust::Ticket
  def ticket_show(id)
    response = self.class.get("/ticket/#{id}/show")

    body, _ = explode_response(response)

    return nil if body =~ /^# (Ticket (\d+) does not exist\.)/

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
      body.gsub!(/^#{field}:(.+)^\n/m) do |m|
        m.strip.split(/,\s+/).join(', ').strip
      end
    end

    message = Mail.new(body)

    hash = Hash[message.header.fields.map { |header|
      key   = header.name.to_s
      value = header.value.to_s
      [ key, value ]
    }]

    %w(Requestors Cc AdminCc).each do |field|
      hash[field] = hash[field].split(', ') if hash[field]
    end

    hash['id'] = hash['id'].split('/').last

    hash
  end

  def ticket_create(attrs)
    default_attrs = {
      'id' => 'ticket/new'
    }
    attrs = default_attrs.merge(attrs).stringify_keys!

    error = create_invalid?(attrs)
    raise InvalidRecord, error if error

    attrs['Text'].gsub!(/\n/, "\n ") if attrs['Text'] # insert a space on continuation lines.

    # We can't set more than one AdminCc when creating a ticket. WTF RT.
    #
    # Delete it from the ticket we are creating, and we'll update the ticket
    # after we've created.
    admincc = attrs.delete('AdminCc')

    content = compose_content('ticket', attrs['id'], attrs)

    response = self.class.post(
      '/ticket/new',
      :body => {
        :content => content
      }
    )

    body, _ = explode_response(response)

    case body
    when /^# Ticket (\d+) created/
      id = body[/^# Ticket (\d+) created/, 1]
      # Add the AdminCc after the ticket is created, because we can't set it
      # on ticket creation.
      update(id, 'AdminCc' => admincc) if admincc

      # Return the whole ticket, not just the id.
      show(id)
    when /^# Could not create ticket/
      raise BadRequest, body
    when /^# Syntax error/
      raise SyntaxError, body
    else
      raise UnhandledResponse, body
    end
  end

  def ticket_update(id, attrs)
    content = compose_content('ticket', id, attrs)

    response = self.class.post(
      "/ticket/#{id}/edit",
      :body => {
        :content => content
      },
    )

    body, _ = explode_response(response)

    case body
    when /^# Ticket (\d+) updated/
      id = body[/^# Ticket (\d+) updated/, 1]
      show(id)
    when /^# You are not allowed to modify ticket \d+/
      raise Unauthorized, body
    when /^# Syntax error/
      raise SyntaxError, body
    else
      raise UnhandledResponse, body
    end
  end

  def ticket_search(query)
    params = {
      :query   => query,
      :format  => 's',
      :orderby => '+id'
    }
    response = self.class.get('/search/ticket', :query => params)
    # FIXME(auxesis) use explode_response here

    body, _ = explode_response(response)
    body.split("\n").map do |t|
      id, subject = t.split(': ', 2)
      {'id' => id, 'Subject' => subject}
    end
  end

  def ticket_history(id, opts = {})
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

    body, _ = explode_response(response)

    case format
    when 'short'
      parse_short_history(body, :comments => comments)
    when 'long'
      parse_long_history(body, :comments => comments)
    end
  end

  alias_method :create, :ticket_create
  alias_method :show, :ticket_show
  alias_method :update, :ticket_update
  alias_method :history, :ticket_history
  alias_method :search, :ticket_search

  private

  def create_invalid?(attrs)
    missing = %w(id Subject Queue).select { |k| !attrs.include?(k) }

    if missing.empty?
      return false
    else
      "Needs attributes: #{missing.join(', ')}"
    end
  end

  def parse_short_history(body, opts = {})
    comments = opts[:comments]
    regex    = comments ? '^\d+:' : '^\d+: [^Comments]'
    history  = body.split("\n").select { |l| l =~ /#{regex}/ }
    history.map { |l| l.split(': ', 2) }
  end

  def parse_long_history(body, opts = {})
    comments = opts[:comments]
    items = body.split("\n--\n")
    list = []
    items.each do |item|
      # Yes, this messes with the "content:" field but that's the one that's upsetting Mail.new
      item.gsub!(/\n\s*\n/, "\n") # remove blank lines for Mail
      history = Mail.new(item)
      next if not comments and history['type'].to_s =~ /Comment/ # skip comments
      reply = {}

      history.header.fields.each_with_index do |header, index|
        next if index == 0

        key   = header.name.to_s.downcase
        value = header.value.to_s

        attachments = []
        case key
        when 'attachments'
          temp = item.match(/Attachments:\s*(.*)/m)
          if temp.class != NilClass
            atarr = temp[1].split("\n")
            atarr.map { |a| a.gsub!(/^\s*/, '') }
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
            reply['attachments'] = attachments
          end
        when 'content'
          reply['content'] = value
        else
          reply["#{key}"] = value
        end
      end
      list << reply
    end

    list
  end
end
