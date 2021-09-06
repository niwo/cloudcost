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
cloudscale_cost_explorer help
```

Describe the server command:

```sh
cloudscale_cost_explorer help server
```

### Servers

#### Detailed List

List all servers from the given environment:

```sh
cloudscale_cost_explorer servers
```

#### Summary

Only show summarized usage:

```sh
cloudscale_cost_explorer servers --summary
```

#### Output CSV

Output in CSV format instead of a table:

```sh
cloudscale_cost_explorer servers --output csv
```

#### Filter by name

Filter by servers by regex on name:

```sh
# only show servers which names include a k8s or rancher:
cloudscale_cost_explorer servers --name "k8s|rancher"

# exclude different name patterns
cloudscale_cost_explorer servers --name "^[^ocp|^k8s|^rancher].*"
```

#### Filter by tag

Filter servers by tag key:

```sh
cloudscale_cost_explorer servers --tag pitc_service
```

Filter servers by tag value:

```sh
cloudscale_cost_explorer servers --tag pitc_service=ocp4
```

### Server Tags

#### Show tags

Display a list of servers and show theire tags:

```sh
cloudscale_cost_explorer server-tags
```

Note thats the same filter options as with the `servers` command apply.

#### Show servers with missing tag

Only show servers which do NOT have a tag-key named "budget-group":

```sh
cloudscale_cost_explorer server-tags --missing-tag budget-group
```

Note that this option can also be combined with `set-tags` or any other option.

#### Set tags

```sh
cloudscale_cost_explorer server-tags --name ldap --set-tags owner=sys budget-group=base-infrastructure
```

#### Remove tags

```sh
cloudscale_cost_explorer server-tags --name ldap --remove-tags owner budget-group
```
