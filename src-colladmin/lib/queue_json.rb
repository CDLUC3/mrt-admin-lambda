# frozen_string_literal: true

require_relative 'merritt_json'

# representation of data in a Merritt zookeeper queue node
class QueueJson < MerrittJson
  def get_queue_node
    getValue(:queueNode, '')
  end

  def get_queue_path(requeue = false)
    st = getValue(:qstatus, '')
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
    "#{get_queue_node}/#{getValue(:queueId, '')}/#{st}"
  end

  def get_hold_path(release = false)
    st = getValue(:qstatus, '')
    if st == 'Held' && release
      'release'
    elsif st == 'Pending' && !release
      'hold'
    else
      return ''
    end
    "#{get_queue_node}/#{getValue(:queueId, '')}"
  end
end
