class Roust
  module Ticket
    def ticket_show(id)
      response = self.class.get("/ticket/#{id}/show")

      body, _ = explode_response(response)

      return nil if body =~ /^# (Ticket (\d+) does not exist\.)/

      parse_ticket_attributes(body)
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
      key, admincc = attrs.detect {|k,v| k =~ /admincc/i }
      attrs.delete(key)

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
        id = $1
        # Add the AdminCc after the ticket is created, because we can't set it
        # on ticket creation.
        ticket_update(id, 'AdminCc' => admincc) if admincc

        # Return the whole ticket, not just the id.
        ticket_show(id)
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
          id = $1
          ticket_show(id)
        when /^# You are not allowed to modify ticket \d+/
          raise Unauthorized, body
        when /^# Syntax error/
          raise SyntaxError, body
        else
          raise UnhandledResponse, body
        end
    end

    def ticket_search(attrs)
      params = {
        :format  => 's',
        :orderby => '+id'
      }.merge(attrs)

      params[:format] = 'l' if verbose = params.delete(:verbose)

      # FIXME(auxesis): query should be an actual method argument
      raise ArgumentError, ":query not specified" unless params[:query]

      response = self.class.get('/search/ticket', :query => params)

      body, _ = explode_response(response)

      return [] if body =~ /^No matching results\./

      if verbose
        results = body.split("\n--\n\n")
        results.map do |result_body|
          parse_ticket_attributes(result_body)
        end
      else
        body.split("\n").map do |t|
          id, subject = t.split(': ', 2)
          {'id' => id, 'Subject' => subject}
        end
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

    def ticket_links_show(id)
      response = self.class.get("/ticket/#{id}/links")
      body, _ = explode_response(response)

      hash = body_to_hash(body)
      id = hash.delete('id').split('/')[1]
      cleaned_hash = hash.map do |k, v|
        ids = v.split(/\s*,\s*/).map do |url|
          url =~ /^fsck\.com\-/ ? url.split('/').last : url
        end
        [ k, ids ]
      end

      Hash[cleaned_hash].merge('id' => id)
    end

    # Add links on a ticket.
    #
    # @param id [Fixnum] the id of the ticket to add links on.
    # @param attrs [Hash] the links to add.
    # @return [Hash] all the links on the ticket after the add action.
    #
    # Example attrs:
    #
    #   {
    #     "RefersTo" => [
    #       "http://us.example",
    #       "http://them.example",
    #     ]
    #   }
    #
    def ticket_links_add(id, attrs)
      # Get the current links state
      current_links = ticket_links_show(id)
      current_links.delete('id')
      desired_links = Marshal.load(Marshal.dump(current_links))

      # Build up the desired link state
      attrs.each do |k,v|
        desired_links[k] ||= []
        v.each do |link|
          desired_links[k] << link
        end
        desired_links[k].uniq!
      end

      # Remove all links before we add any new ones. Fucking RT API.
      ticket_links_remove(id, current_links)

      # Work out how many times we'll need to make the same request until we
      # get the desired state.
      tries = desired_links.max_by {|k,v| v.size }.last.size

      tries.times do
        content = compose_content('ticket', id, desired_links)

        response = self.class.post(
          "/ticket/#{id}/links",
          :body => {
            :content => content
          }
        )

        body, _ = explode_response(response)

        case body
        when /^# Links for ticket (\d+) updated/
          id = $1
          #ticket_links_show(id)
        when /^# You are not allowed to modify ticket \d+/
          raise Unauthorized, body
        when /^# Syntax error/
          raise SyntaxError, body
        else
          raise UnhandledResponse, body
        end
      end

      ticket_links_show(id)
    end

    # Remove links on a ticket.
    #
    # @param id [Fixnum] the id of the ticket to remove links on.
    # @param attrs [Hash] the links to remove.
    # @return [Hash] all the links on the ticket after the remove action.
    #
    # Example attrs:
    #
    #   {
    #     "DependsOn" => [
    #       "http://us.example",
    #       "http://them.example",
    #     ],
    #     "RefersTo" => [
    #       "http://others.example",
    #     ],
    #   }
    #
    def ticket_links_remove(id, attrs)
      # Get the current links state
      current_links = ticket_links_show(id)
      desired_links = Marshal.load(Marshal.dump(current_links))

      # Build up the desired link state
      attrs.each do |k,v|
        v.each do |link|
          desired_links[k].delete(link) if desired_links[k]
        end
      end

      # Work out how many times we'll need to make the same request until we
      # get the desired state.
      tries = attrs.empty? ? 0 : attrs.max_by {|k,v| v.size }.last.size

      tries.times do
        content = compose_content('ticket', id, desired_links)

        response = self.class.post(
          "/ticket/#{id}/links",
          :body => {
            :content => content
          }
        )

        body, _ = explode_response(response)

        case body
        when /^# Links for ticket (\d+) updated/
          id = $1
        when /^# You are not allowed to modify ticket \d+/
          raise Unauthorized, body
        when /^# Syntax error/
          raise SyntaxError, body
        else
          raise UnhandledResponse, body
        end
      end

      ticket_links_show(id)
    end

    # TODO(auxesis): add method for listing ticket attachments
    # TODO(auxesis): add method for getting a ticket attachment
    # TODO(auxesis): add method for commenting on a ticket
    # TODO(auxesis): add method for replying on a ticket

    # To maintain backwards compatibility with previous versions (and rt-client),
    # alias these methods to their short form.
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

    # parse_ticket_attributes decodes a response body of ticket metadata.
    #
    # Used by ticket_show and verbose ticket_search.
    def parse_ticket_attributes(body)
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

      hash = body_to_hash(body)

      %w(Requestors Cc AdminCc).each do |field|
        hash[field] = hash[field].split(', ') if hash[field]
      end

      hash['id'] = hash['id'].split('/').last

      hash
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
end
