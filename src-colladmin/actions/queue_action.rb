require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/http_post_json'

class QueueAction < PostToIngestAction 
  def initialize(config, action, path, myparams, endpoint)
    qp = CGI.unescape(myparams.fetch('queue-path', 'na'))
    super(config, action, path, myparams, "#{endpoint}#{qp}")
  end
end

class CollQueueAction < PostToIngestAction
  def initialize(config, action, path, myparams, endpoint)
    coll = myparams.fetch("coll", "")
    endpoint = endpoint.gsub(%r[coll$], coll) unless coll.empty?
    super(config, action, path, myparams, endpoint)
  end
end

class CollIterateQueueAction < PostToIngestAction
  def initialize(config, action, path, myparams, endpoint)
    coll = myparams.fetch("coll", "")
    @it_endpoint = endpoint.gsub(%r[coll$], coll) unless coll.empty?
    super(config, action, path, myparams, "admin/queues")
  end

  def perform_action
    resp = {status: 500}
    data = JSON.parse(get_body)
    data = data.fetch('ingq:ingestQueueNameState',{})
    data = data.fetch('ingq:ingestQueueName',{})
    data.fetch('ingq:ingestQueue',[]).each do |qjson|
      node = qjson.fetch('ingq:node', '')
      next if node.empty?
      begin
        resp = HttpPostJson.new(get_ingest_server, @it_endpoint.gsub("queue", node))
      rescue => e
        puts(e.message)
        puts(e.backtrace)
      end
    end
    { message: "queue release submitted" }.to_json
  end

end
