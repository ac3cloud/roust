require 'spec_helper'
require 'rt/client'
require 'yaml'

describe "RT::Client" do
  before do
    @credentials = {
      :server   => 'http://rt.example.org',
      :username => 'admin',
      :password => 'password'
    }
    mocks_path = Pathname.new(__FILE__).parent.join('mocks')

    stub_request(:post, "http://rt.example.org/REST/1.0/").
      with(:body => {
            "user"=>"admin",
            "pass"=>"password",
           }).
      to_return(:status => 200, :body => "", :headers => {})


    stub_request(:get, "http://rt.example.org/REST/1.0/ticket/1/show").
      to_return(:status => 200,
                :body   => mocks_path.join('ticket-1-show.txt').read,
                :headers => {})
  end

  it "authenticates on instantiation" do
    rt = RT::Client.new(@credentials)
    rt.authenticated?.should be_true
  end

  it "can list tickets matching a query" do
    rt = RT::Client.new(@credentials)
    rt.authenticated?.should be_true

    results = rt.list(:query => "id = 1 or id = 2")
    results.size.should == 2
    results.each do |result|
      result.size.should == 2
    end
  end

  it "can fetch metadata on individual tickets" do
    rt = RT::Client.new(@credentials)
    rt.authenticated?.should be_true

    ticket = rt.show("1")
    ticket.should_not be_nil

    attrs = %w(id subject queue) +
            %w(requestors cc admincc owner creator) +
            %w(resolved status) +
            %w(starts started timeleft due timeworked timeestimated) +
            %w(lastupdated created told) +
            %w(priority finalpriority initialpriority)

    attrs.each do |attr|
      ticket[attr].should_not be_nil, "#{attr} key doesn't exist"
    end

    %w(requestors cc admincc).each do |field|
      ticket[field].size.should > 1
    end
  end

  it "can fetch transactions on individual tickets" do
    rt = RT::Client.new(@credentials)
    rt.authenticated?.should be_true

    #short = rt.history("1785760", :format => "short")
    short = rt.history("1", :format => "short")
    short.size.should > 0
    short.each do |txn|
      txn.size.should == 2
    end

    #attrs = %w(ticket data oldvalue creator timetaken) +
    #        %w(id type field newvalue content description) +
    #        %w(attachments created)
    attrs = %w(ticket data oldvalue timetaken) +
            %w(id type field newvalue content description)

    long = rt.history("1", :format => "long")
    long.size.should > 0
    long.each do |txn|
      attrs.each do |attr|
        #p txn unless txn[attr]
        txn[attr].should_not be_nil, "#{attr} key doesn't exist"
      end
    end
  end

  it "can find user details" do
    rt = RT::Client.new(@credentials)
    rt.authenticated?.should be_true

    attrs = %w(name realname gecos nickname emailaddress id lang password)

    user = rt.user("lindsay@bulletproof.net")
    attrs.each do |attr|
      user[attr].should_not be_nil, "#{attr} key doesn't exist"
    end
  end
end
