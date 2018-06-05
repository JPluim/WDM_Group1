require 'elasticsearch'
require 'csv'

MAX_BULK_BODY_SIZE = 1000
FILE_PATH = './data/web_data_management_public_elections.csv'
INDEX = 'elections'
DOC_TYPE = 'election'

@client = Elasticsearch::Client.new host: 'localhost:5000'

@client.transport.reload_connections!
@client.cluster.health

document = Hash.new
@bulk_body = []
@documents_processed = 0

def process_document(document)
  @documents_processed += 1
  @bulk_body << { create: { _index: INDEX, _type: DOC_TYPE, _id: document["id"], data: { doc: document } } }
end

def bulk_update
  @client.bulk body: @bulk_body
  @bulk_body = []
  puts @documents_processed.to_s
end

CSV.foreach(FILE_PATH, liberal_parsing: true, headers: true, quote_char: '|') do |row|
  document = row.to_hash
 
  process_document(document)

  if @bulk_body.size >= MAX_BULK_BODY_SIZE
      bulk_update
  end
end

bulk_update
