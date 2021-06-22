# cloudscale.ch Cost Explorer

A CLI tool which helps you fetching servers from the cloudscale.ch API and exploring costs.

## Setup

Make sure you have exported your API_TOKEN in your environment:

```sh
export CLOUDSCALE_API_TOKEN=HELPIMTRAPPEDINATOKENGENERATOR
```

NOTE: You only need read access to the API.

Ruby is required, install dependencies using bundler:

```sh
bundle install
```

## Usage

Diplay help:

```sh
bundle exec bin/cloudscale_cost_explorer
```

List all servers from the given environment:

```sh
bundle exec bin/cloudscale_cost_explorer servers
```

Filter by servers by regex on name:

```sh
# only show servers which names start with 'k8s'
bundle exec bin/cloudscale_cost_explorer servers --name-filter "^k8s.*"

# exclude different name patterns
bundle exec bin/cloudscale_cost_explorer servers --name-filter "^[^ocp|^k8s|^rancher|^ocp|^lightning].*"
```

Filter servers by tag:

```sh
bundle exec bin/cloudscale_cost_explorer servers --tag-filter "pitc_service=ocp4"
```
