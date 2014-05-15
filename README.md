Roust
=====

Roust is a Ruby client for [Request Tracker](http://www.bestpractical.com/rt/)'s REST API.

It is a complete fork of [rt-client](http://rubygems.org/gems/rt-client) by Tom Lahti, and shares little ancestry.

Features
--------

- Ticket querying using the full RT query language
- Fetching ticket metadata (id, subject, queue, etc)
- Fetching transactions on individual tickets (in long and short form)
- Fetching user details

Installing
----------

Ensure you have Ruby > 1.9 installed, then run:

```
gem install roust
```

Or add to your Gemfile:

``` ruby
gem 'roust', :git => 'git@github.com:bulletproofnetworks/roust.git'
```

Using
-----

``` ruby
require 'roust'

credentials = {
  :server   => 'http://rt.example.org',
  :username => 'admin'
  :password => 's3cr3t'
}

rt = Roust.new(credentials)
rt.authenticated? # => true

# Query RT
rt.search(:query => "id = 1 or id = 2") # => [["1", "A subject"], ["2", "Another subject"]]

# Fetch ticket metadata
rt.show("1") # => { {"cc"=>["dan@us.example", "dave@them.example"], "owner"=>"bob", "creator"=>"alice", "status"=>"open", … }

# Fetch ticket transactions
rt.history("1", :format => "short") # => [["1", "Ticket created by alice"], ["2", "Status changed from 'open' to 'resolved' by bob"]]
rt.history("1", :format => "long") # => [{"id"=>"1", "ticket"=>"1", "timetaken"=>"0", "type"=>"Create", "field"=>"", "oldvalue"=>"", "newvalue"=>"", "data"=>"", "description"=>"Ticket created by alice" }, … ]

# Fetch user details
rt.user("dan@us.example") # => {"id"=>"user/160000", "name"=>"dan", "password"=>"********", "emailaddress"=>"dan@us.example", "realname"=>"Dan Smith", "nickname"=>"dan", … }
```


Developing
----------

To get started, clone the Roust repository locally by running:

```
git clone git@github.com:bulletproofnetworks/roust.git
```

Then pull in the dependencies:

```
bundle
```

You're now ready to run the tests:

```
bundle exec rake
```

Roust has reasonable test coverage of the core features mentioned above. It has some other features that have been ported from the original rt-client implementation that are not tested (and are probably broken). See the TODO section for more details.


Releasing
---------

1. Bump the version in `lib/roust/version.rb`
2. Run a `bundle` to update any RubyGems dependencies.
3. git tag the version git tag X.Y.Z
4. Build the gem with `rake build`
5. Push the gem with `rake push`


TODO
----

- Links CRUD (linking tickets to one another)
- User CRUD (creating + updating + deleting users)
- Ticket comment + correspondence
- Attachment fetching
