class Roust
  module Queue
    # id can be numeric (e.g. 28) or textual (e.g. sales)
    def queue_show(id)
      response = self.class.get("/queue/#{id}")

      body, _ = explode_response(response)
      if body =~ /No queue named/
        nil
      else
        body_to_hash(body)
      end
    end

    alias_method :queue, :queue_show
  end
end
