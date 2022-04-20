require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/http_post_json'

class QueueAction < PostToIngestAction 
  def initialize(config, action, path, myparams, endpoint)
    if endpoint =~ %r[coll$]
      coll = myparams.fetch("coll", "")
      endpoint = endpoint.gsub(%r[coll$], coll) unless coll.empty?
      super(config, action, path, myparams, "#{endpoint}")
    else
      qp = CGI.unescape(myparams.fetch('queue-path', 'na'))
      super(config, action, path, myparams, "#{endpoint}#{qp}")
    end
  end
end
