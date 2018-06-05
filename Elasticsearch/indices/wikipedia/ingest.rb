require 'csv'
require 'date'
require 'elasticsearch'

MAX_BULK_BODY_SIZE = 1000
FILE_PATHS = %w[./data/web_data_management_public_article.csv
                ./data/web_data_management_public_elections.csv
                ./data/web_data_management_public_revision_talk.csv
                ./data/web_data_management_public_revision_user_talk.csv
                ./data/web_data_management_public_user.csv
                ./data/web_data_management_public_votes.csv].freeze
INDEX = 'wikipedia'.freeze
DOC_TYPE = 'document'.freeze
TYPES = %w[article election talkrevision usertalkrevision user vote].freeze

@client = Elasticsearch::Client.new host: 'localhost:5000'

@client.transport.reload_connections!
@client.cluster.health

document = {}
@bulk_body = []
@documents_processed = 0

def process_document(document)
  @documents_processed += 1
  @bulk_body << { create:
                          {
                            _index: INDEX,
                            _type: DOC_TYPE,
                            _id: @documents_processed,
                            data: document
                          } }
end

def bulk_update
  @client.bulk body: @bulk_body
  @bulk_body = []
  puts @documents_processed.to_s
end

FILE_PATHS.each_with_index do |path, index|
  CSV.foreach(path,
              liberal_parsing: true,
              headers: true,
              quote_char: '|') do |row|

    document = row.to_hash

    document['promoted'] = document['promoted'] == 'true' if document['promoted']
    document['article_id'] = document['article_id'].to_i if document['article_id']
    document['word_count'] = document['word_count'].to_i if document['word_count']
    document['minor'] = document['minor'].to_i if document['minor']
    document['election_id'] = document['election_id'].to_i if document['election_id']
    document['vote'] = document['vote'] == '1' if document['vote']
    document['timestamp'] = Date.parse(document['timestamp']) if document['timestamp']

    document['type'] = TYPES[index]
    process_document(document)

    bulk_update if @bulk_body.size >= MAX_BULK_BODY_SIZE
  end
end

bulk_update
