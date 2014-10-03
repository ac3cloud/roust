require 'spec_helper'
require 'roust'

describe Roust do
  include_context 'credentials'

  before do
    mocks_path = Pathname.new(__FILE__).parent.parent.join('mocks')

    stub_request(:get, "http://rt.example.org/REST/1.0/search/ticket?format=s&orderby=%2Bid&query=id%20=%201%20or%20id%20=%202")
       .to_return(:status  => 200,
                  :body    => mocks_path.join('ticket-search-1-or-2.txt').read,
                  :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/search/ticket?format=l&orderby=%2Bid&query=id%20=%201%20or%20id%20=%202")
       .to_return(:status  => 200,
                  :body    => mocks_path.join('ticket-search-1-or-2-long.txt').read,
                  :headers => {})

    %w(s l).each do |format|
      stub_request(:get, "http://rt.example.org/REST/1.0/search/ticket?format=#{format}&orderby=%2Bid&query=subject%20=%20%22a%20ticket%20that%20does%20not%20exist%22")
         .to_return(:status => 200,
                    :body    => mocks_path.join('ticket-search-that-does-not-exist.txt').read,
                    :headers => {})
    end

    stub_request(:get, 'http://rt.example.org/REST/1.0/ticket/1/history?format=s')
       .to_return(:status  => 200,
                  :body    => mocks_path.join('ticket-1-history-short.txt').read,
                  :headers => {})

    stub_request(:get, 'http://rt.example.org/REST/1.0/ticket/1/history?format=l')
       .to_return(:status  => 200,
                  :body    => mocks_path.join('ticket-1-history-long.txt').read,
                  :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/ticket/3/links")
       .to_return(:status  => 200,
                  :body    => mocks_path.join('ticket-3-links.txt').read,
                  :headers => {})

    stub_request(:post, "http://rt.example.org/REST/1.0/ticket/new")
       .with(:body => "content=id%3A%20ticket%2Fnew%0ASubject%3A%20test%20ticket%0AQueue%3A%20sales")
       .to_return(:status => 200,
                  :body    => mocks_path.join('ticket-create.txt').read,
                  :headers => {})

    stub_request(:get, 'http://rt.example.org/REST/1.0/ticket/99/show')
      .to_return(:status  => 200,
                 :body    => mocks_path.join('ticket-99-show.txt').read,
                 :headers => {})

    stub_request(:post, "http://rt.example.org/REST/1.0/ticket/100/edit")
      .with { |request|
        query = WebMock::Util::QueryMapper.query_to_values(request.body)
        require 'pry'

        true
      }.to_return(:status => 200,
                  :body    => mocks_path.join('ticket-100-update.txt').read,
                  :headers => {})

    stub_request(:get, 'http://rt.example.org/REST/1.0/ticket/100/show')
      .to_return(:status  => 200,
                 :body    => mocks_path.join('ticket-100-show.txt').read,
                 :headers => {})

    @rt = Roust.new(credentials)
    expect(@rt.authenticated?).to eq(true)
  end

  describe 'tickets' do
    it 'can list tickets matching a query' do
      results = @rt.search(:query => 'id = 1 or id = 2')
      expect(results.size).to eq(2)
      results.each do |result|
        expect(result.size).to eq(2)
      end
    end

    it 'can list no tickets when there are no search results' do
      results = @rt.search(:query => 'subject = "a ticket that does not exist"')
      expect(results.size).to eq(0)

      results = @rt.search(:query => 'subject = "a ticket that does not exist"', :verbose => true)
      expect(results.size).to eq(0)
    end

    it 'can verbosely list tickets matching a query' do
      results = @rt.search(:query => 'id = 1 or id = 2', :verbose => true)
      expect(results.size).to eq(2)

      attrs = %w(id Subject Queue) +
              %w(Requestors Cc AdminCc Owner Creator) +
              %w(Resolved Status) +
              %w(Starts Started TimeLeft Due TimeWorked TimeEstimated) +
              %w(LastUpdated Created Told) +
              %w(Priority FinalPriority InitialPriority)

      results.each do |result|
        attrs.each do |attr|
          expect(result[attr]).to_not eq(nil), "#{attr} key doesn't exist"
        end
      end
    end

    it 'can fetch metadata on individual tickets' do
      ticket = @rt.show('1')
      expect(ticket).to_not eq(nil)

      attrs = %w(id Subject Queue) +
              %w(Requestors Cc AdminCc Owner Creator) +
              %w(Resolved Status) +
              %w(Starts Started TimeLeft Due TimeWorked TimeEstimated) +
              %w(LastUpdated Created Told) +
              %w(Priority FinalPriority InitialPriority)

      attrs.each do |attr|
        expect(ticket[attr]).to_not eq(nil), "#{attr} key doesn't exist"
      end

      %w(Requestors Cc AdminCc).each do |field|
        expect(ticket[field].size).to be > 1
      end
    end

    it 'can fetch transactions on individual tickets' do
      short = @rt.history('1', :format => 'short')

      expect(short.size).to be > 1
      short.each do |txn|
        expect(txn.size).to eq(2)
        expect(txn.first).to match(/^\d+$/)
        expect(txn.last).to match(/^\w.*\w$/)
      end

      attrs = %w(ticket data oldvalue timetaken) +
              %w(id type field newvalue content description)

      long = @rt.history('1', :format => 'long')
      expect(long.size).to be > 0
      long.each do |txn|
        attrs.each do |attr|
          expect(txn[attr]).to_not eq(nil), "#{attr} key doesn't exist"
        end
      end
    end

    it 'can list linked tickets on individual tickets' do
      links = @rt.ticket_links('3')

      expect(links['id']).to eq('3')

      %w(Members MemberOf RefersTo ReferredToBy DependsOn DependedOnBy).each do |key|
        expect(links).to include(key)
        expect(links[key]).to_not be_empty
      end
    end

    it 'can create tickets' do
      attrs = {
        'Subject' => 'test ticket',
        'Queue'   => 'sales',
      }
      ticket = @rt.ticket_create(attrs)

      attrs.each do |k, v|
        expect(ticket[k]).to eq(v)
      end
    end

    it 'transforms attribute case when manipulating principals' do
      attrs = {
        'requestors' => 'alice@them.example,bob@them.example',
        'cc'         => 'charlie@them.example',
        'admincc'    => 'daisy@us.example,eleanor@us.example',
      }
      ticket = @rt.ticket_update(100, attrs)

      expect(WebMock).to have_requested(:post, "rt.example.org/REST/1.0/ticket/100/edit")
        .with { |request|
          query = WebMock::Util::QueryMapper.query_to_values(request.body)
          query['content'] =~ /Requestors:/ &&
          query['content'] =~ /Cc:/ &&
          query['content'] =~ /AdminCc:/
        }
    end
  end
end
