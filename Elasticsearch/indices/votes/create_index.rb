require 'elasticsearch'

INDEX = 'votes'.freeze

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
                                "vote": {
                                    "properties": {
                                        "id": { "type": "integer" },
                                        "election_id": { "type": "integer" },
                                        "vote": { "type": "boolean" },
                                        "user_id": { "type": "integer" },
                                        "vote_time": { "type": "date" },
                                        "screen_name": { "type": "keyword" },
                                    }
                                }
                            }
                        }