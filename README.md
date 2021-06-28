# cloudscale.ch Cost Explorer

A CLI-tool which helps you explore costs on [cloudscale.ch](https://www.cloudscale.ch).

Resources are fetched from the [API](https://www.cloudscale.ch/en/api/v1) and costs calculated using prices defined in `data/pricing.yml`.

Please note that costs are always calculated based on the current usage.
Your actual bills are based on the effective usage over time and may include additional service fees, i.e. for data transfer or discounts.  

## Setup

Ruby is required, install dependencies using bundler:

```sh
bundle install
```

## Configure API-Auth

cloudscale_cost_explorer does support the same auth configuration options as [cloudscale-cli](https://cloudscale-ch.github.io/cloudscale-cli/).

You can manage multiple profiles using `cloudscale.ini` files ([see here](https://cloudscale-ch.github.io/cloudscale-cli/auth/) for instructions). 


Otherwise you can export a `CLOUDSCALE_API_TOKEN` in your environment:

```sh
export CLOUDSCALE_API_TOKEN=HELPIMTRAPPEDINATOKENGENERATOR
```

or you can directly pass a token as a argument to the command: `--api-token HELPIMTRAPPEDINATOKENGENERATOR`

**NOTE:** The API_TOKEN does only require read access.

## Usage

### Help

Display help:

```sh
bundle exec bin/cloudscale_cost_explorer help
```

Describe the server command:

```sh
bundle exec bin/cloudscale_cost_explorer help server
```

### Servers

List all servers from the given environment:

```sh
bundle exec bin/cloudscale_cost_explorer servers
```

Only show summarized usage:

```sh
bundle exec bin/cloudscale_cost_explorer servers --summary
```

Output in CSV format instead of a table: 

```sh
bundle exec bin/cloudscale_cost_explorer servers --csv
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
