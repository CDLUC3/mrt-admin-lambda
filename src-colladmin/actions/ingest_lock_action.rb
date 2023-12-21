# frozen_string_literal: true

require_relative 'forward_to_ingest_action'
require_relative '../lib/lock'

# Collection Admin Task class - see config/actions.yml for description
class IngestLockAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams, 'admin/lock/mrt.lock')
  end

  def get_title
    'List Ingest Locks'
  end

  def table_headers
    LockEntry.table_headers
  end

  def table_types
    LockEntry.table_types
  end

  def table_rows(body)
    lockList = LockList.new(get_ingest_server, body)
    lockList.to_table
  end

  def hasTable
    true
  end

  def init_status
    :PASS
  end
end
