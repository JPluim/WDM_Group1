require 'elasticsearch'

INDEX = 'wikipedia'.freeze

client = Elasticsearch::Client.new host: 'localhost:5000', log: true

client.transport.reload_connections!
client.cluster.health

client.count index: INDEX

start_time = Time.now

admin_result = client.search index: INDEX,
                             body: {
                               query: {
                                 bool: {
                                   filter: [
                                     { term: { promoted: true } },
                                     { term: { type: 'election' } }
                                   ]
                                 }
                               },
                               _source: [
                                 'user_id'
                               ],
                               from: 0,
                               size: 10_000
                             }
admin_ids = admin_result['hits']['hits'].map { |r| r['_source']['user_id'] }

admin_major_result = client.search index: INDEX,
                                   body: {
                                     query: {
                                       bool: {
                                         filter: [
                                           { terms: { user_id: admin_ids } },
                                           { terms: { type: %w[talkrevision usertalkrevision] } },
                                           { term: { minor: 0 } }
                                         ]
                                       }
                                     },
                                     aggs: {
                                       users: {
                                         terms: { field: 'user_id', size: admin_ids.length + 1 }
                                       }

                                     },
                                     from: 0,
                                     size: 0
                                   }

admin_minor_result = client.search index: INDEX,
                                   body: {
                                     query: {
                                       bool: {
                                         filter: [
                                           { terms: { user_id: admin_ids } },
                                           { terms: { type: %w[talkrevision usertalkrevision] } },
                                           { term: { minor: 1 } }
                                         ]
                                       }
                                     },
                                     aggs: {
                                       users: {
                                         terms: { field: 'user_id', size: admin_ids.length + 1 }
                                       }

                                     },
                                     from: 0,
                                     size: 0
                                   }

admin_all_revisions = client.search index: INDEX,
                                    body: {
                                      query: {
                                        bool: {
                                          filter: [
                                            { terms: { user_id: admin_ids } },
                                            { terms: { type: %w[talkrevision usertalkrevision] } },
                                          ]
                                        }
                                      },
                                      aggs: {
                                        users: {
                                          terms: { field: 'user_id', size: admin_ids.length + 1 }
                                        }

                                      },
                                      from: 0,
                                      size: 0
                                    }

admin_ids_with_majors = admin_major_result['aggregations']['users']['buckets'].map { |k| k['key'] }
admin_major_edit_counts = {}
admin_major_result['aggregations']['users']['buckets'].each do |entry|
  admin_major_edit_counts[entry['key']] = entry["doc_count"]
end

admin_minor_edit_counts = {}
admin_minor_result['aggregations']['users']['buckets'].each do |entry|
  admin_minor_edit_counts[entry['key']] = entry["doc_count"]
end

admin_all_counts = {}
admin_all_revisions['aggregations']['users']['buckets'].each do |entry|
  admin_all_counts[entry['key']] = entry["doc_count"]
end

puts 'admin_major_edit_counts: ', admin_major_edit_counts
puts 'admin_minor_edit_counts: ', admin_minor_edit_counts
puts 'admin_all_counts: ', admin_all_counts

bigger_minor_ratio = []

admin_all_counts.each do |admin, total|
  minor_edits = admin_minor_edit_counts[admin] || 1
  major_edits = admin_major_edit_counts[admin] || 1

  bigger_minor_ratio << admin if minor_edits > major_edits
end

puts 'Admins with more minor than major edits: ', bigger_minor_ratio
puts 'Number of admins with more minor than major edits: ', bigger_minor_ratio.size

end_time = Time.now

puts 'Total time: ', end_time - start_time

user_elections = client.search index: INDEX,
                               body: {
                                 query: {
                                   bool: {
                                     filter: [
                                       { term: { type: 'election' } }
                                     ]
                                   }
                                 },
                                 _source: [
                                   'user_id'
                                 ],
                                 from: 0,
                                 size: 10_000
                               }

admin_result = client.search index: INDEX,
                             body: {
                               query: {
                                 bool: {
                                   filter: [
                                     { term: { type: 'election' } }
                                   ]
                                 }
                               },
                               _source: [
                                 'user_id'
                               ],
                               from: 0,
                               size: 10_000
                             }

user_election_ids = user_elections['hits']['hits'].map { |r| r['_source']['user_id'] }
admin_ids = admin_result['hits']['hits'].map { |r| r['_source']['user_id'] }

admin_all_revisions = client.search index: INDEX,
                                    body: {
                                      query: {
                                        bool: {
                                          filter: [
                                            { terms: { user_id: admin_ids } },
                                            { terms: { type: %w[usertalkrevision] } }
                                          ]
                                        }
                                      },
                                      aggs: {
                                        users: {
                                          terms: { field: 'user_id', size: admin_ids.length + 1 }
                                        }

                                      },
                                      from: 0,
                                      size: 0
                                    }

user_talk_pages_scroll_result = client.search index: INDEX,
                                              scroll: '5m',
                                              body: {
                                                query: {
                                                  bool: {
                                                    filter: [
                                                      { term: { title: 'User_talk:' } }
                                                    ]
                                                  }
                                                },
                                                _source: [
                                                  'id'
                                                ]
                                              }

user_talk_pages_result = client.scroll scroll: '5m',
                                       body: {
                                         scroll_id: user_talk_pages_scroll_result['_scroll_id']
                                       }

