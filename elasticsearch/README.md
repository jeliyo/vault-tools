# Setting up Elasticsearch for local development

This is one way to get Elasticsearch running with TLS to test vault's
elasticsearch plugin.

Based on this guide: https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-docker.html#get-started-docker-tls

``` shell
## generate the certs in the es_certs volume, and
## bring up elasticsearch and kibana
docker-compose -f create-certs.yml run --rm create_certs
docker-compose up -d

docker exec es01 /bin/bash -c "bin/elasticsearch-setup-passwords \
  auto --batch --url https://es01:9200"

## set the kibana_system user's password in .env KB_PASSWORD
## restart the containers
docker-compose stop
docker-compose up -d

## copy the certs out to be used in the vault config
docker cp es01:/usr/share/elasticsearch/config/certificates certs
```

At this point you should be able to login to kibana at
https://localhost:5601 with the `elastic` user. And you can test the
password with elasticsearch directly like this:

``` shell
$ curl -k --user elastic:lfRLQrb3c3oEVxryNbgk https://localhost:9200
{
  "name" : "es01",
  "cluster_name" : "es-docker-cluster",
  "cluster_uuid" : "u4OluVWwS3ydobC0PFkC3w",
  "version" : {
    "number" : "7.9.1",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "083627f112ba94dffc1232e8b42b73492789ef91",
    "build_date" : "2020-09-01T21:22:21.964974Z",
    "build_snapshot" : false,
    "lucene_version" : "8.6.2",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}

```

See the sample `custom.sh` in this directory for an example to use
with the local_dev.sh script in the elasticsearch plugin repo.

Copy it to `vault-plugin-database-elasticsearch/scripts/`, and set
`ES_PASSWORD` to the `elastic` user's password, and `ES_CERTS` to the
directory with the certs copied from es01.
