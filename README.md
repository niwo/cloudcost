# cloudscale.ch Cost Explorer

A CLI-tool which helps you exploring costs on [cloudscale.ch](https://www.cloudscale.ch).

Resources are fetched from the [API](https://www.cloudscale.ch/en/api/v1) and costs calculated using prices defined in `data/pricing.yml`.

## Setup

Ruby is required, install dependencies using bundler:

```sh
bundle install
```

## Configure API Key(s)

cloudscale_cost_explorer does support the same auth configuration options as [cloudscale-cli](https://cloudscale-ch.github.io/cloudscale-cli/).

You can manage multiple profiles using `cloudscale.ini` files ([see here](https://cloudscale-ch.github.io/cloudscale-cli/auth/) for instructions). 


Otherwise you can export a `CLOUDSCALE_API_TOKEN` in your environment:

```sh
export CLOUDSCALE_API_TOKEN=HELPIMTRAPPEDINATOKENGENERATOR
```

**NOTE:** The API_TOKEN does only require read access.


## Usage

Display help:

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
bundle exec bin/cloudscale_cost_explorer servers --name "^k8s.*"

# exclude different name patterns
bundle exec bin/cloudscale_cost_explorer servers --name "^[^ocp|^k8s|^rancher|^ocp|^lightning].*"
```

Filter servers by tag:

```sh
bundle exec bin/cloudscale_cost_explorer servers --tag "pitc_service=ocp4"
```
