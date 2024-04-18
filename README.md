# apsystems-ez1-loki-grafana

Scraper and Grafana Dashboard for ApSystems EZ1 Solar Inverter

# Description

The APsystems EZ1 Microinverter has a nice Rest API, which you can use
to scrape power output data. There's a [neat python library
available](https://github.com/SonnenladenGmbH/APsystems-EZ1-API), but
I couldn't use it because my old Raspberry Pi doesn't have support for
the latest python version, which is
[required](https://github.com/SonnenladenGmbH/APsystems-EZ1-API/issues/22)
by this library.

So, I wrote a simple shell script to scrape the API, which is simple
enough. All you need is [curl](https://github.com/curl/curl) and
[jq](https://github.com/jqlang/jq).

I then upload the collected data to a cloud node where I happen to run
a [Grafana](https://github.com/grafana/grafana) instance. I feed the
generated logs into [Loki](https://github.com/grafana/loki) and
visualze it then in a nice dashboard:

![Screenshot](https://github.com/TLINDEN/apsystems-ez1-loki-grafana/blob/main/dashboard-screenshot.png)

# Installation

## Setup the Microinverter

The [python
library README](https://github.com/SonnenladenGmbH/APsystems-EZ1-API)
contains good advice how to enable the API on your inverter. Just
follow it precisely.

## Setup a static ip address for your inverter

This step is important. Connect to your router and configure the
current DHCP ip address to be static. Refer to the router
documentation on how to do this.

## Get some Raspberry Pi or similar up as collector

This is not part of this documetation. You'll need some system, which
runs 24/7 on your home network. I use a Raspberry Pi, but any unix
like system will do. Just make sure you have SSH access and it has
`curl` and `jq` installed and `crond` is enabled. No root permissions
are required.

## Copy the scraper script to the collector device

Copy the file
[scrape-inverter.sh](https://github.com/TLINDEN/apsystems-ez1-loki-grafana/blob/main/scrape-inverter.sh)
to the collector device. Ensure it is executable:

`chmod 755 scrape-inverter.sh`

## Customize the script

Now edit the script and set the ip address accordingly.

## Test the script

If all is prepared, just execute the script. The output should look
something like this:

```shell
you@pi: % ./scrape-inverter.sh 
ts=2024-04-18T17:55:14+01:00 p1=97 p2=97 ip=192.168.128.117 version=1.7.0 deviceid=E07000000807 ssid=FOO minpower=30 maxpower=800
```

## Setup the cronjob

Now it's up to you how you want to collect the logs. You may append
the output to a log file and transfer it to somewhere else or you may
just run Loki and Grafana on the same system.

I modified the script like this (at the end):

```sh
if test -n "$p1" -a -n "$ip"; then
    echo "ts=$ts p1=$p1 p2=$p2 ip=$ip version=$version deviceid=$deviceid ssid=$ssid minpower=$minpower maxpower=$maxpower" | ssh uber "cat >> /var/log/solar.metric"
else
    echo "$ts got invalid data!"
fi
```

This sends the log to the cloud machine and appends it over there.

## Loki config

I use promtail (which is part of Loki) to feed the logs into
Loki. Here's the relevant part of the promtail config:

```yaml
scrape_configs:
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      __path__: /var/log/*metric
```

To check if the logs actually show up, try the following query in the
explorer, make sure to set the source to Loki:

```default
{﻿filename﻿=﻿"/var/log/solar.metric"﻿}﻿ |= ﻿`p1`﻿ ﻿|﻿ ﻿logfmt﻿
```

It should look like this:

![Screenshot](https://github.com/TLINDEN/apsystems-ez1-loki-grafana/blob/main/lokiexplore.png)

## Install the Grafana dashboard

If the logs show up in Loki, create a new dashboard. Import the file
[apsystems-ez1-loki-dashboard.json](https://github.com/TLINDEN/apsystems-ez1-loki-grafana/blob/main/apsystems-ez1-loki-dashboard.json)
as JSON.

You may modify the queries to match the filename you are using for
your logfile or course.


# Report bugs

[Please open an issue](https://github.com/TLINDEN/apsystems-ez1-loki-grafana/issues). Thanks!

# License

This work is licensed under the terms of the BSD license.

# Author

Copyleft (c) 2024 Thomas von Dein
