require 'spec_helper'
require 'roust'

describe Roust do
  include_context 'credentials'

  describe 'authentication' do
    it 'authenticates on instantiation' do
      rt = Roust.new(credentials)
      expect { rt.authenticated? }.to be_true
    end

    it 'errors when credentials are incorrect' do
      mocks_path = Pathname.new(__FILE__).parent.parent.join('mocks')

      stub_request(:post, 'http://rt.example.org/index.html').
        with(:body => {
              'user'=>'admin',
              'pass'=>'incorrect',
             }).
        to_return(:status => 200, :body => '', :headers => {})

      stub_request(:get, 'http://rt.example.org/REST/1.0/ticket/1/show').
        to_return(:status  => 200,
                  :body    => mocks_path.join('ticket-1-show-unauthenticated.txt').read,
                  :headers => {})

      credentials.merge!({:username => 'admin', :password => 'incorrect'})

      expect { Roust.new(credentials) }.to raise_error(Unauthenticated)
    end
  end
end
