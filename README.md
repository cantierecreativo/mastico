# Mastico

Make common queries simple, and make **some** complex queries possible.

## Why does this exist?

Using a basic client, creating Elasticsearch queries requires specialist
knowledge or hours of comparing Stack Overflow posts.

Chewy makes managing and updating indexes simple, but the query interface
remains the same.

## Example 1:

Mastico creates queries based on a list of fields:

```ruby
query = FooIndex.query
query = Mastico::Query.new(
  fields: [:title, :description], query: "ciao"
).perform(query)
```

This creates a series of queries: `word`, `prefix`, `infix` and `fuzzy` matches
of the word `ciao` against the supplied fields.

## Example 2:

What if I want to block some words ("Stop words") of give more weight to others?

```ruby
def weight(word)
  case word
  when "information"
    0
  else
    1.0
  end
end

query = Mastico::Query.new(
  fields: [:title, description],
  word_weight: method(:weight),
  query: "Information is power"
).perform(query)
```

## Example 3:

What if I don't want all the different types of matching?

```ruby
query = Mastico::Query.new(
  fields: {title: {boost: 4.0, types: [:word]} },
  query: "Simple"
).perform(query)
```

This will return only the `word` type search (i.e. whole words) for the
attribute `title`.

The types of matching that are available are:

* `:word` - whole words,
* `:prefix` - the beginning of words,
* `:infix` - some part of a word,
* `:fuzzy` - similar words.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mastico'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mastico

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/cantierecreativo/mastico. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere
to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
