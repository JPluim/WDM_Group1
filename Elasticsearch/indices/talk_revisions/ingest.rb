require 'elasticsearch'
require 'csv'

SEPARATOR = ' '
REVISION_SEPARATOR = "\n"
LOG_MARK = '#'
MAX_BULK_BODY_SIZE = 1000
FILE_PATH = './data/web_data_management_public_revision_talk.csv'
REVISION_TYPE = 'talk'

@client = Elasticsearch::Client.new host: 'localhost:5000'

@client.transport.reload_connections!
@client.cluster.health

revision = Hash.new
@bulk_body = []
@revisions_processed = 0

def set_revision_type(revision)
  revision['type'] = REVISION_TYPE
  revision
end

def process_revision(revision)
  revision = set_revision_type(revision)
  @revisions_processed += 1
  @bulk_body << { create: { _index: 'talk_revisions', _type: 'revision', _id: revision["id"], data: { doc: revision } } }
end

def bulk_update
  @client.bulk body: @bulk_body
  @bulk_body = []
  puts @revisions_processed.to_s
end

CSV.foreach(FILE_PATH, liberal_parsing: true, headers: true, quote_char: '|') do |row|
  revision = row.to_hash
 
  process_revision(revision)

  if @bulk_body.size >= MAX_BULK_BODY_SIZE
      bulk_update
  end
end

bulk_update
