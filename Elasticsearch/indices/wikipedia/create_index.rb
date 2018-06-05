require 'elasticsearch'

client = Elasticsearch::Client.new host: 'localhost:5000', log: true

client.transport.reload_connections!
client.cluster.health
client.indices.delete index: 'wikipedia'

client.indices.create index: 'wikipedia',
                      body:
                        {
                          settings: {
                            index: {
                              number_of_shards: 1,
                              number_of_replicas: 0
                            }
                          },
                          mappings: {
                            document: {
                              properties: {
                                type: { type: 'keyword' },
                                id: { type: 'keyword' },
                                title: { type: 'keyword' },
                                user_id: { type: 'keyword' },
                                promoted: { type: 'boolean' },
                                article_id: { type: 'integer' },
                                comment: { type: 'text' },
                                timestamp: { type: 'date' },
                                word_count: { type: 'integer' },
                                related_pages: { type: 'text' },
                                category: { type: 'text' },
                                minor: { type: 'integer' },
                                username: { type: 'keyword' },
                                election_id: { type: 'integer' },
                                vote: { type: 'boolean' },
                                vote_time: { type: 'date' },
                                screen_name: { type: 'keyword' }
                              }
                            }
                          }
                        }
