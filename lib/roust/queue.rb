module Roust::Queue
  # id can be numeric (e.g. 28) or textual (e.g. sales)
  def queue_show(id)
    response = self.class.get("/queue/#{id}")

    body, _ = explode_response(response)
    if body =~ /No queue named/
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

  alias_method :queue, :queue_show
end
