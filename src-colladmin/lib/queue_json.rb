require_relative 'merritt_json'

class QueueJson < MerrittJson

  def get_queue_path(requeue = false)
    st = getValue(:qstatus, '')
    if (st == "Consumed")
      st = "consume"
    elsif (st == "Completed")
      return "" if requeue
      st = "complete"
    elsif (st == "Failed")
      st = "fail"
    else
      return ""
    end
    "#{getValue(:queueNode, '')}/#{getValue(:queueId, '')}/#{st}"
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
    "#{getValue(:queueNode, '')}/#{getValue(:queueId, '')}"
  end

end