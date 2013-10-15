require 'spec_helper'
require 'rt/client'
require 'yaml'

describe "RT::Client" do
  before do
    filename     = Pathname.new(__FILE__).parent.parent.join('credentials.yaml')
    @credentials = YAML.load(File.read(filename))
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
  end

  it "can fetch transactions on individual tickets" do
    rt = RT::Client.new(@credentials)
    rt.authenticated?.should be_true

    short = rt.history("1", :format => "short")
    short.size.should > 0
    short.each do |txn|
      txn.size.should == 2
    end

    attrs = %w(ticket data oldvalue creator timetaken) +
            %w(id type field newvalue content description) +
            %w(attachments created)

    short = rt.history("1", :format => "long")
    short.size.should > 0
    short.each do |txn|
      attrs.each do |attr|
        txn[attr].should_not be_nil
      end
    end
  end
end
