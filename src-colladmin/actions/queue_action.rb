require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/http_post_json'

class QueueAction < PostToIngestAction 
  def initialize(config, path, myparams, endpoint)
    qp = CGI.unescape(myparams.fetch('queue-path', 'na'))
    super(config, path, myparams, "#{endpoint}#{qp}")
  end
end
