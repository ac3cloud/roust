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
  end

  describe 'authentication' do
    it "authenticates on instantiation" do
      rt = Roust.new(@credentials)
      rt.authenticated?.should be_true
    end
  end
end
