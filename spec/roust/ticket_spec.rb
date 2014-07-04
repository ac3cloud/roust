require 'spec_helper'
require 'roust'

describe Roust do
  include_context 'credentials'

  before do
    mocks_path = Pathname.new(__FILE__).parent.parent.join('mocks')

    stub_request(:get, 'http://rt.example.org/REST/1.0/search/ticket?format=s&orderby=%2Bid&query%5Bquery%5D=id%20=%201%20or%20id%20=%202')
       .to_return(:status  => 200,
                  :body    => mocks_path.join('ticket-search-1-or-2.txt').read,
                  :headers => {})

    stub_request(:get, 'http://rt.example.org/REST/1.0/ticket/1/history?format=s')
       .to_return(:status  => 200,
                  :body    => mocks_path.join('ticket-1-history-short.txt').read,
                  :headers => {})

    stub_request(:get, 'http://rt.example.org/REST/1.0/ticket/1/history?format=l')
       .to_return(:status  => 200,
                  :body    => mocks_path.join('ticket-1-history-long.txt').read,
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
  end
end
