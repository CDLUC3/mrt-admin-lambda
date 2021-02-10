require 'httpclient'
require_relative 'action'
require_relative 'forward_to_ingest_action'

class IngestProfileAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    super(config, path, myparams, 'admin/profiles')
  end

  def get_title
    "List Ingest Profiles"
  end

  def table_headers
    [
      'Profile'
    ]
  end

  def table_types
    [
      ''
    ]
  end

  def table_rows(body)
    data = JSON.parse(body)
    data = data.fetch('pros:profilesState', {})
    data = data.fetch('pros:profiles', {})
    data = data.fetch('pros:profileFile', [])
    rows = []
    data.each do |r|
      rows.append(
        [
          r.fetch('pros:file', '')
        ]
      )
    end
    rows
  end

  def hasTable
    true
  end
end
