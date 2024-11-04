# frozen_string_literal: true

require_relative 'merritt_json'

# representation of data in a Merritt zookeeper queue node
class QueueJson < MerrittJson
  def get_queue_node
    get_value(:queueNode, '')
  end

  def path
    "#{get_queue_node}/#{get_value(:queueId, '')}"
  end

  def get_del_queue_path_m1
    st = get_value(:qstatus, '')
    return '' unless %w[Failed Held].include?(st)

    path
  end

  def get_del_batch_path
    st = get_value(:qstatus, '')
    return '' unless %w[Failed Held].include?(st)

    path
  end

  def get_update_batch_path
    st = get_value(:qstatus, '')
    return '' unless %w[Failed].include?(st)

    path
  end

  def get_acc_del_queue_path
    st = get_value(:qstatus, '').to_s
    return '' unless %w[Failed Completed].include?(st)

    path
  end

  def get_requeue_path_m1
    st = get_value(:qstatus, '')
    return '' unless %w[Consumed Failed].include?(st)

    path
  end

  def get_acc_requeue_path
    st = get_value(:qstatus, '').to_s
    return '' unless %w[Consumed Failed].include?(st)

    path
  end

  def get_hold_path_m1
    st = get_value(:qstatus, '')
    return '' unless %w[Pending].include?(st)

    path
  end

  def get_release_path_m1
    st = get_value(:qstatus, '')
    return '' unless %w[Held].include?(st)

    path
  end
end
