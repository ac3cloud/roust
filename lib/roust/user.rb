class Roust
  module User
    # id can be numeric (e.g. 28) or textual (e.g. john)
    def user_show(id)
      response = self.class.get("/user/#{id}")

      body, _ = explode_response(response)
      if body =~ /No user named/
        nil
      else
        body.gsub!(/\n\s*\n/, "\n") # remove blank lines for Mail
        message = Mail.new(body)
        Hash[message.header.fields.map { |header|
          key   = header.name.to_s.downcase
          value = header.value.to_s
          [ key, value ]
        }]
      end
    end

    def user_update(id, attrs)
      content = compose_content('user', id, attrs)

      response = self.class.post(
        "/user/#{id}/edit",
        :body => {
          :content => content
        }
      )

      body, _ = explode_response(response)

      case body
      when /^# User (.+) updated/
        id = $1
        user_show(id)
      when /^# You are not allowed to modify user \d+/
        raise Unauthorized, body
      when /^# Syntax error/
        raise SyntaxError, body
      else
        raise UnhandledResponse
      end
    end

    # Requires RT > 3.8.0
    def user_create(attrs)
      default_attrs = {
        'id' => 'user/new'
      }
      attrs = default_attrs.merge(attrs).stringify_keys!

      content = compose_content('user', attrs['id'], attrs)

      response = self.class.post(
        '/user/new',
        :body => {
          :content => content
        }
      )

      body, _ = explode_response(response)

      case body
      when /^# User (.+) created/
        id = $1
        # Return the whole user, not just the id.
        user_show(id)
      when /^# Could not create user/
        raise BadRequest, body
      when /^# Syntax error/
        raise SyntaxError, body
      else
        raise UnhandledResponse, body
      end
    end

    alias_method :user, :user_show
  end
end
