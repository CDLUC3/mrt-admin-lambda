# frozen_string_literal: true

require_relative 'action'
require_relative 'forward_to_ingest_action'

# Collection Admin Task class - see config/actions.yml for description
class IngestStateAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams, 'state')
  end

  def get_title
    'Ingest State'
  end

  def table_headers
    %w[
      Key
      Value
    ]
  end

  def table_types
    [
      '',
      ''
    ]
  end

  def table_rows(body)
    data = JSON.parse(body)
    data = data.fetch('ing:ingestServiceState', {})
    rows = []
    data.each_key do |k|
      if k == 'ing:storageInstances'
        obj = data.fetch('ing:storageInstances', {})
        obj = {} if obj == ''
        rows.append([k, obj.fetch('ing:storageURL', {}).fetch('ing:uRL', '')])
      else
        rows.append([k, data.fetch(k, '')])
      end
    end
    rows
  end

  def get_locked_collections
    data = JSON.parse(get_body)
    data.fetch('ing:ingestServiceState', {}).fetch('ing:collectionSubmissionState', '').split(',')
  end

  def has_table
    true
  end
end
