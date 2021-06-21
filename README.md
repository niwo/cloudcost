# cloudscale.ch Cost Explorer

This handy tool helps you fetching servers from the cloudscale.ch API and calculating costs.

## Usage

Make sure you have exported your API_TOKEN in your environment:

```sh
export CLOUDSCALE_API_TOKEN=HELPIMTRAPPEDINATOKENGENERATOR
```

Ruby is required, install dependencies using bundler:

```sh
bundle install
```

Run it:

```sh
bundle exec cloudscale_cost_explorer.rb
```
