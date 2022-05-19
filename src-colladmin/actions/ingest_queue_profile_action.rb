require_relative 'forward_to_ingest_action'

class IngestQueueProfileCountAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams, 'admin/queues')
  end

  def get_title
    "List Ingest Queue Profile Counts"
  end

  def table_headers
    [
      "Profile",
      "Status",
      "Counts"
    ]
  end

  def table_types
    [
      "",
      "",
      "dataint"
    ]
  end

  def table_rows(body)
    queueList = QueueList.new(get_ingest_server, body)
    arr = []
    queueList.profiles.each do |k, v|
      ka = k.split(",")
      arr.append([ka[0], ka[1], v.length])
    end
    arr
  end

  def hasTable
    true
  end

  def init_status
    :PASS
  end

end
