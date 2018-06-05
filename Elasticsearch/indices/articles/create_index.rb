require 'elasticsearch'

INDEX = 'articles'.freeze

client = Elasticsearch::Client.new host: 'localhost:5000', log: true

client.transport.reload_connections!
client.cluster.health
client.indices.delete index: INDEX

client.indices.create index: INDEX,
                        body: {
                            settings: {
                                number_of_shards: 1,
                                number_of_replicas: 1
                            },
                            mappings: {
                                "article": {
                                    "properties": {
                                        "id": { "type": "integer" },
                                        "title": { "type": "keyword" },
                                    }
                                }
                            }
                        }