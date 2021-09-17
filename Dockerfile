FROM ruby:3.0-alpine

ARG INFLUX_RELEASE=influxdb2-client-2.1.0-linux-amd64.tar.gz

RUN apk --no-cache add wget \
    && gem install cloudcost \
    && wget https://dl.influxdata.com/influxdb/releases/$INFLUX_RELEASE \
    && tar xvfz $INFLUX_RELEASE -C /usr/local/bin --strip-components=1 \
    && rm -f $INFLUX_RELEASE

ENTRYPOINT [ "cloudcost" ]
CMD [ "help" ]