require_relative 'merritt_json'

class QueueJson < MerrittJson

  def get_queue_node
    getValue(:queueNode, '')
  end

  def get_queue_path(requeue = false)
    st = getValue(:qstatus, '')
    if (st == "Consumed")
      st = "consume"
    elsif (st == "Held")
      return "" if requeue
      st = "held"
    elsif (st == "Completed")
      return "" if requeue
      st = "complete"
    elsif (st == "Failed")
      st = "fail"
    else
      return ""
    end
    "#{get_queue_node}/#{getValue(:queueId, '')}/#{st}"
  end

  def get_hold_path(release = false)
    st = getValue(:qstatus, '')
    if (st == "Held" && release)
      st = "release"
    elsif (st == "Pending" && !release)
      st = "hold"
    else
      return ""
    end
    "#{get_queue_node}/#{getValue(:queueId, '')}"
  end

end