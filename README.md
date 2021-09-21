# cloudcost - cloudscale.ch Cost Explorer

A CLI-tool which helps you explore costs on [cloudscale.ch](https://www.cloudscale.ch).

Resources are fetched from the [API](https://www.cloudscale.ch/en/api/v1) and costs calculated using prices defined in `data/pricing.yml`.

Please note that costs are always calculated based on the current usage.
Your actual bills are based on the effective usage over time and may include additional service fees, i.e. for data transfer or discounts.  

## Installation

Install the gem:

```sh
gem install cloudcost
```

## Configure API-Auth

cloudcost does support the same auth configuration options as [cloudscale-cli](https://cloudscale-ch.github.io/cloudscale-cli/).

You can manage multiple profiles using `cloudscale.ini` files ([see here](https://cloudscale-ch.github.io/cloudscale-cli/auth/) for instructions).

Otherwise you can export a `CLOUDSCALE_API_TOKEN` in your environment:

```sh
export CLOUDSCALE_API_TOKEN=HELPIMTRAPPEDINATOKENGENERATOR
```

or you can directly pass a token as a argument to the command: `--api-token HELPIMTRAPPEDINATOKENGENERATOR`

## Usage

### Help

Display help:

```sh
cloudcost help
```

Describe the server command:

```sh
cloudcost help server
```

### Servers

#### Detailed List

List all servers from the given environment:

```sh
cloudcost servers
```

#### Summary

Only show summarized usage:

```sh
cloudcost servers --summary
```

#### Group and summarize by tag

By using the `--group-by` option, you can summarize usage by tag:

```sh
cloudcost servers --group-by budget-group
```

#### Influx Line Protocol output

The CLI also supports output in Influxdb Line Protocol format when using the `--group-by` option:

```sh
cloudcost servers --group-by budget-group --output influx
```

The output can directly ba pipped to the influxdb CLI:

```sh
cloudcost servers --group-by budget-group --profile prod | \
influx write --bucket my-bucket --org my-org --token my-super-secret-auth-token
```

Example Flux-Query for loading data from InfluxDB:

```sh
influx query --org my-org --token my-super-secret-auth-token \
'from(bucket:"my-bucket")
  |> range(start: -1d)
  |> filter(fn: (r) =>
    r._measurement == "cloudscaleServerCosts" and
    r._field == "cost_per_day") and
    r.profile == "prod" and 
    r.group == "my-budget-group"'
```

#### CSV Output

Output in CSV format instead of a table:

```sh
cloudcost servers --output csv
```

#### Filter by name

Filter by servers by regex on name:

```sh
# only show servers which names include a k8s or rancher:
cloudcost servers --name "k8s|rancher"

# exclude different name patterns
cloudcost servers --name "^[^ocp|^k8s|^rancher].*"
```

#### Filter by tag

Filter servers by tag key:

```sh
cloudcost servers --tag service
```

Filter servers by tag value:

```sh
cloudcost servers --tag service=ocp4
```

### Server Tags

#### Show tags

Display a list of servers and show theire tags:

```sh
cloudcost server-tags
```

Note thats the same filter options as with the `servers` command apply.

#### Show servers with missing tag

Only show servers which do NOT have a tag-key named "budget-group":

```sh
cloudcost server-tags --missing-tag budget-group
```

Note that this option can also be combined with `set-tags` or any other option.

#### Set tags

```sh
cloudcost server-tags --name ldap --set-tags owner=sys budget-group=base-infrastructure
```

#### Remove tags

```sh
cloudcost server-tags --name ldap --remove-tags owner budget-group
```

### Volumes

List all volumes:

```sh
cloudcost volumes
```

Only list volumes of type `bulk`

```sh
cloudcost volumes --type bulk
```

List volumes which are not attached to a server:

```sh
cloudcost volumes --no-attached
```

Filter volumes by names:

```sh
cloudcost volumes --name "pvc"
```

Output as InfluxDB Line Protocol:

```sh
cloudcost volumes --output influx --profile prod --no-attached
```

NOTE: The Line Protocol output includes a tag `state` which is either "attached", "unattached" or "all".
