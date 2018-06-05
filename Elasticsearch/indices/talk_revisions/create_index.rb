require 'elasticsearch'

client = Elasticsearch::Client.new host: 'localhost:5000', log: true

client.transport.reload_connections!
client.cluster.health
client.indices.delete index: 'talk_revisions'

client.indices.create index: 'talk_revisions',
                        body: {
                            settings: {
                                number_of_shards: 1,
                                number_of_replicas: 1
                            },
                            mappings: {
                                "revision": {
                                    "properties": {
                                        "id": { "type": "integer" },
                                        "article_id": { "type": "integer" },
                                        "user_id": { "type": "keyword" },
                                        "comment": { "type": "text" },
                                        "timestamp": { "type": "date" },
                                        "word_count": { "type": "integer"},
                                        "related_pages": { "type": "text" },
                                        "category": { "type": "text" },
                                        "minor": { "type": "boolean" },
                                        "type": { "type": "keyword" }
                                    }
                                }
                            }
                        }