# frozen_string_literal: true

require_relative 'forward_to_ingest_action'

# Collection Admin Task class - see config/actions.yml for description
class IngestQueueProfileCountAction < IngestQueueZookeeperAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams, {})
    @profiles = {}
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

  def register_item(item)
    super
    k = "#{item.profile},#{item.qstatus}"
    @profiles[k] = @profiles.fetch(k, [])
    @profiles[k].append(item)
  end

  def table_rows(_body)
    arr = []
    @profiles.keys.sort.each do |k|
      ka = k.split(',')
      qs = ka[1]
      profile = ka[0]
      list = @profiles[k]
      count = list.length
      status = 'PASS'
      status = 'FAIL' if qs == 'Failed'
      status = 'WARN' if qs == 'Held'
      arr.append([profile, qs, "#{profile};#{qs};#{count}", count, status])
    end
    arr
  end

  def has_table
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

# Collection Admin Task class - see config/actions.yml for description
class IngestQueueBatchProfileCountAction < IngestQueueZookeeperAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams, {})
    @profiles = {}
  end

  def get_title
    'List Ingest Queue Batch Profile Counts'
  end

  def table_headers
    [
      'Profile',
      'Batch',
      'Queue Status',
      'Filter',
      'Counts',
      'Status'
    ]
  end

  def table_types
    %w[
      fprofile
      fbatch
      fstatus
      fbatchstatus
      dataint
      status
    ]
  end

  def register_item(item)
    super
    k = "#{item.profile},#{item.bid},#{item.qstatus}"
    @profiles[k] = @profiles.fetch(k, [])
    @profiles[k].append(item)
  end

  def table_rows(_body)
    arr = []
    @profiles.keys.sort.each do |k|
      ka = k.split(',')
      bid = ka[1]
      qs = ka[2]
      profile = ka[0]
      list = @profiles[k]
      count = list.length
      status = 'PASS'
      status = 'FAIL' if qs == 'Failed'
      status = 'WARN' if qs == 'Held'
      arr.append([profile, bid, qs, "#{bid};#{qs};#{count}", count, status])
    end
    arr
  end

  def has_table
    true
  end

  def init_status
    :PASS
  end

  def get_filter_col
    4
  end

  def get_group_col
    0
  end
end
