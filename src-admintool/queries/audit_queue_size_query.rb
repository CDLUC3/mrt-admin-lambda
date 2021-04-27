class AuditQueueSizeQuery < AdminQuery
  def get_title
    "Audit Queue Size Query"
  end

  def get_sql
    %{
      select
        ifnull(sum(billable_size), 0),
        count(f.id) 
      from   
        inv.inv_files f 
      inner join inv.inv_audits a
        on f.id = a.inv_file_id 
      where   
        status='processing'
      and
        verified > date_add(now(), INTERVAL -1 DAY)
      ;
    }
  end

  def get_headers(results)
    ['Size of Processing Queue', 'Count in Processing Queue']
  end

  def get_types(results)
    ['dataint','dataint']
  end

end
