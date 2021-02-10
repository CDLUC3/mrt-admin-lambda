require 'httpclient'
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
      'Job',
      'Batch',
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
      '',
      '',
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
    data = {} if data == ""
    data = data.fetch('que:queueEntryState', [])
    rows = []
    data.each do |r|
      rows.append(
        [
          r.fetch('que:jobID', ''),
          r.fetch('que:batchID', ''),
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

  def convertJsonToTable(body)
    {
      format: 'report',
      title: get_title,
      headers: table_headers,
      types: table_types,
      data: table_rows(body),
      filter_col: nil,
      group_col: nil,
      show_grand_total: false,
      merritt_path: @merritt_path,
      alternative_queries: [
      ],
      iterate: false
    }.to_json
  end

end
