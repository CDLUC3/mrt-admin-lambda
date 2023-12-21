# frozen_string_literal: true

require_relative 'forward_to_ingest_action'

# Collection Admin Task class - see config/actions.yml for description
class IngestQueueProfileCountAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams, 'admin/queues')
  end

  def get_title
    'List Ingest Queue Profile Counts'
  end

  def table_headers
    [
      'Profile',
      'Queue Status',
      'Filter',
      'Counts',
      'Status'
    ]
  end

  def table_types
    %w[
      fprofile
      fstatus
      fprofilestatus
      dataint
      status
    ]
  end

  def table_rows(body)
    queueList = QueueList.new(get_ingest_server, body)
    arr = []
    queueList.profiles.keys.sort.each do |k|
      ka = k.split(',')
      qs = ka[1]
      profile = ka[0]
      list = queueList.profiles[k]
      count = list.length
      status = 'PASS'
      status = 'FAIL' if qs == 'Failed'
      status = 'WARN' if qs == 'Held'
      arr.append([profile, qs, "#{profile};#{qs};#{count}", count, status])
    end
    arr
  end

  def hasTable
    true
  end

  def init_status
    :PASS
  end

  def get_filter_col
    3
  end

  def get_group_col
    0
  end
end
