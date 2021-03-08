require_relative 'action'
require_relative 'forward_to_ingest_action'

class IngestQueueAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    super(config, path, myparams, 'admin/queues')
  end

  def get_title
    "List Ingest Queues"
  end

  def table_headers
    [
      'Batch',
      'Job',
      'Profile',
      'Date',
      'User',
      'Title',
      'Type',
      'Status',
      'Name',
      'Queue Id'
    ]
  end

  def table_types
    [
      'qbatch',
      'qjob',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ]
  end

  def table_rows(body)
    data = JSON.parse(body)
    data = data.fetch('que:queueState', {})
    data = data.fetch('que:queueEntries', {})
    # Ingest currently returns "" when empty
    data = {} if data == ""
    data = data.fetch('que:queueEntryState', [])
    # Ingest currently returns a hash when only one item is found
    data = [data] if data.instance_of?(Hash)
    rows = []
    data.each do |r|
      batch = r.fetch('que:batchID', '')
      job = r.fetch('que:jobID', '')
      rows.append(
        [
          batch,
          "#{batch}/#{job}",
          r.fetch('que:profile', ''),
          r.fetch('que:date', ''),
          r.fetch('que:user', ''),
          r.fetch('que:objectTitle', ''),
          r.fetch('que:fileType', ''),
          r.fetch('que:status', ''),
          r.fetch('que:name', ''),
          r.fetch('que:iD', ''),
        ]
      )
    end
    rows
  end

  def hasTable
    true
  end

  def get_alternative_queries
    [
      {
        label: 'Completed Ingests', 
        url: 'index.html?path=recent_ingests'
      }
    ]
  end

end
