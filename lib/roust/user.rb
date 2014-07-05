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
        id = body[/^# User (.+) updated/, 1]
        user_show(id)
      when /^# You are not allowed to modify user \d+/
        raise Unauthorized, body
      when /^# Syntax error/
        raise SyntaxError, body
      else
        raise UnhandledResponse
      end
    end

    # TODO(auxesis): add method for creating a user

    alias_method :user, :user_show
  end
end
