require 'httparty'
require 'mail'
require 'active_support/core_ext/hash'
require 'roust/ticket'
require 'roust/queue'
require 'roust/user'
require 'roust/exceptions'

class Roust
  include HTTParty
  include Roust::Ticket
  include Roust::Queue
  include Roust::User

  def initialize(credentials)
    server   = credentials[:server]
    username = credentials[:username]
    password = credentials[:password]

    if server =~ /REST\/1\.0/
      raise ArgumentError, 'The supplied :server has REST in the URL. You only need to specify the base, e.g. http://rt.example.org/'
    end

    # - There is no way to authenticate against the API. The only way to log
    #   in is to fill out the same HTML form humans fill in, cache the cookies
    #   returned, and send them on every subsequent request.
    # - RT does not provide *any* indication that the authentication request
    #   has succeeded or failed. RT will always return a HTTP 200.

    self.class.base_uri(server)

    response = self.class.post(
      '/index.html',
      :body => {
        :user => username,
        :pass => password
      }
    )

    cookie = response.headers['set-cookie']
    self.class.headers['Cookie'] = cookie if cookie

    # Switch the base uri over to the actual REST API base uri.
    self.class.base_uri "#{server}/REST/1.0"

    # - The easiest way to programatically check if an authentication request
    #   succeeded is by doing a request for a ticket, and seeing if the API
    #   responds with some specific text ("401 Credentials required") that
    #   indicates authentication has previously failed.
    # - The authenticated? method will return false if an Unauthenticated
    #   exception bubbles up from response handling. We (dirtily) rethrow the
    #   exception.
    raise Unauthenticated unless authenticated?
  end

  def authenticated?
    begin
      return true if show('1')
    rescue Unauthenticated
      return false
    end
  end

  private

  # compose_content turns a Hash into an RFC2822 "key: value"-like header blob
  #
  # This is the fucked up format RT demands all content is sent and received in.
  def compose_content(type, id, attrs)
    default_attrs = {
      'id' => [ type, id ].join('/')
    }
    attrs = default_attrs.merge(attrs).stringify_keys!

    content = attrs.map do |k, v|
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
    end

    content.join("\n")
  end

  # explode_response separates RT's response content from the response status.
  #
  # All HTTP-level response codes from RT are a lie. The only way to check if
  # the request was successful is by inspecting the body of the content back
  # from RT, and separating the first line from the rest of the content.
  #
  # - The first line contains the status of the operation.
  # - All subsequent lines (if there are any) are the message body.
  def explode_response(response)
    body   = response.body
    status = body[/RT\/\d+\.\d+\.\d+\s(\d{3}\s.*)\n/, 1]

    body.gsub!(/RT\/\d+\.\d+\.\d+\s\d{3}\s.*\n/, '')
    body = body.empty? ? nil : body.lstrip

    raise Unauthenticated, 'Invalid username or password' if status =~ /401 Credentials required/

    return body, status
  end
end
