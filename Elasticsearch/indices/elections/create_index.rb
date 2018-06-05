require 'elasticsearch'

INDEX = 'elections'.freeze

client = Elasticsearch::Client.new host: 'localhost:5000', log: true

client.transport.reload_connections!
client.cluster.health
# client.indices.delete index: INDEX

client.indices.create index: INDEX,
                        body: {
                            settings: {
                                number_of_shards: 1,
                                number_of_replicas: 1
                            },
                            mappings: {
                                "election": {
                                    "properties": {
                                        "id": { "type": "integer" },
                                        "user_id": { "type": "integer" },
                                        "promoted": { "type": "boolean" }
                                    }
                                }
                            }
                        }