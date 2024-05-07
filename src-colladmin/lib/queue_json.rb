# frozen_string_literal: true

require_relative 'merritt_json'

# representation of data in a Merritt zookeeper queue node
class QueueJson < MerrittJson
  def get_queue_node
    get_value(:queueNode, '')
  end

  def get_queue_path(requeue: false)
    st = get_value(:qstatus, '')
    case st
    when 'Consumed'
      st = 'consume'
    when 'Held'
      return '' if requeue

      st = 'held'
    when 'Completed'
      return '' if requeue

      st = 'complete'
    when 'Failed'
      st = 'fail'
    else
      return ''
    end
    "#{get_queue_node}/#{get_value(:queueId, '')}/#{st}"
  end

  def get_queue_path_m1(requeue: false)
    case get_value(:qstatus, '')
    when 'Consumed'
      # no action
    when 'Held'
      return '' if requeue

    when 'Completed'
      return '' if requeue

    when 'Failed'
      # no action
    else
      return ''
    end
    get_value(:queueId, '')
  end

  def get_hold_path(release: false)
    st = get_value(:qstatus, '')
    if st == 'Held' && release
      'release'
    elsif st == 'Pending' && !release
      'hold'
    else
      return ''
    end
    "#{get_queue_node}/#{get_value(:queueId, '')}"
  end

  def get_hold_path_m1(release: false)
    st = get_value(:qstatus, '')
    if st == 'Held' && release
      'release'
    elsif st == 'Pending' && !release
      'hold'
    else
      return ''
    end
    get_value(:queueId, '')
  end
end
