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

    stub_request(:get, "http://rt.example.org/REST/1.0/user/dan@us.example").
       to_return(:status  => 200,
                 :body    => mocks_path.join('user-dan@us.example.txt').read,
                 :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/user/nil").
       to_return(:status  => 200,
                 :body    => mocks_path.join('user-nil.txt').read,
                 :headers => {})

    stub_request(:post, "http://rt.example.org/REST/1.0/user/dan@us.example/edit").
         with(:body => "content=id%3A%20user%2Fdan%40us.example%0ARealName%3A%20Daniel%20Smith").
         to_return(:status => 200,
                   :body   => mocks_path.join('user-dan@us.example-edit.txt').read,
                   :headers => {})

  end

  describe 'user' do
    it 'can lookup user details' do
      rt = Roust.new(@credentials)
      rt.authenticated?.should be_true

      attrs = %w(name realname gecos nickname emailaddress id lang password)

      user = rt.user_show('dan@us.example')
      attrs.each do |attr|
        user[attr].should_not be_nil, "#{attr} key doesn't exist"
      end
    end

    it 'returns nil for unknown users' do
      rt = Roust.new(@credentials)
      rt.authenticated?.should be_true

      queue = rt.user_show('nil')
      queue.should be_nil
    end

    it 'can modify an existing user' do
      mocks_path = Pathname.new(__FILE__).parent.parent.join('mocks')
      stub_request(:get, "http://rt.example.org/REST/1.0/user/dan@us.example").
         to_return(:status  => 200,
                   :body    => mocks_path.join('user-dan@us.example-after-edit.txt').read,
                   :headers => {})

      rt = Roust.new(@credentials)
      rt.authenticated?.should be_true

      attrs = { 'RealName' => 'Daniel Smith' }
      user  = rt.user_update('dan@us.example', attrs)

      user['realname'].should == 'Daniel Smith'
    end
  end
end
