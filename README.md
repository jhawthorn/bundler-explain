# bundler-explain

This project aims to give better explanations conflicts on bundle install.

Consider this Gemfile:

```
gem 'rails', '~> 5.0.0'
gem 'quiet_assets'
```

Running bundle update we get this error:

```
Bundler could not find compatible versions for gem "rails":
  In Gemfile:
    rails (~> 5.0.0)

Could not find gem 'rails (~> 5.0.0)' in any of the sources.

Bundler could not find compatible versions for gem "railties":
  In Gemfile:
    quiet_assets was resolved to 1.0.1, which depends on
      railties (~> 3.1)

    rails (~> 5.0.0) was resolved to 5.0.0, which depends on
      railties (= 5.0.0)
```

bundler has tried every version of `quiet_assets` and `rails`, and found that
none are compatible. However it's a little unclear from this.

Bundler can only report one of the many failed combinations it has tried (here
`rails 5.0.0` and `quiet_assets 1.0.1`, neither of which the most recent
version).

bundler-explain aims to show the user why there are no possible solutions:

```
Because quiet_assets 1.0.1 depends on railties ~> 3.1
  and quiet_assets <= 1.0.0 depends on rails ~> 3.1,
  quiet_assets <= 1.0.0 OR 1.0.1 requires railties ~> 3.1 or rails ~> 3.1.
And because quiet_assets >= 1.0.2 depends on railties < 5.0, >= 3.1,
  either railties < 5.0, >= 3.1 or rails ~> 3.1.
So, because rails >= 5.0.0, <= 5.0.7 depends on railties ~> 5.0.0
  and root depends on rails ~> 5.0.0,
  version solving has failed.
```

With more gems, bundler's output will be more verbose but bundler-explain will
only describe relevant gems. [See a more complex example](https://gist.github.com/jhawthorn/480dab06ade950161d3bd0db0018538e).

bundler-explain uses [PubGrub](https://github.com/jhawthorn/pub_grub) to
determine the cause of the failure.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bundler-explain'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bundler-explain

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jhawthorn/bundler-explain. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Bundler::Explain project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/jhawthorn/bundler-explain/blob/master/CODE_OF_CONDUCT.md).
