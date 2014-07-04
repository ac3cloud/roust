require 'spec_helper'
require 'roust'

describe "Roust" do
  before do
    @credentials = {
      :server   => 'http://rt.example.org',
      :username => 'admin',
      :password => 'password'
    }
    mocks_path = Pathname.new(__FILE__).parent.parent.join('mocks')

    stub_request(:post, "http://rt.example.org/index.html").
      with(:body => {
            "user"=>"admin",
            "pass"=>"password",
           }).
      to_return(:status => 200, :body => "", :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/ticket/1/show").
      to_return(:status  => 200,
                :body    => mocks_path.join('ticket-1-show.txt').read,
                :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/queue/13").
       to_return(:status => 200,
                 :body    => mocks_path.join('queue-13.txt').read,
                 :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/queue/nil").
       to_return(:status => 200,
                 :body    => mocks_path.join('queue-nil.txt').read,
                 :headers => {})

  end

  describe 'queue' do
    it "can lookup queue details" do
      rt = Roust.new(@credentials)
      rt.authenticated?.should be_true

      attrs = %w(id name description correspondaddress commentaddress) +
              %w(initialpriority finalpriority defaultduein)

      queue = rt.queue('13')
      attrs.each do |attr|
        queue[attr].should_not be_nil, "#{attr} key doesn't exist"
      end
    end

    it 'returns nil for unknown queues' do
      rt = Roust.new(@credentials)
      rt.authenticated?.should be_true

      queue = rt.queue('nil')
      queue.should be_nil
    end
  end
end
