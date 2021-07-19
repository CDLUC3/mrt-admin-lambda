class ConsistencyFilesNoAuditQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def report_name
    "#{@path}"
  end

  def get_title
    "Files missing from the audit table"
  end

  def get_sql
    %{
      select 
        count(*),
        ifnull(
          sum(
            case
              when created < date_add(now(), INTERVAL -2 DAY)
                then 1
              else 0
            end
          ),
          0
        ),
        ifnull(
          sum(
            case
              when created < date_add(now(), INTERVAL -2 DAY)
                then 0
              when created < date_add(now(), INTERVAL -1 DAY) 
                then 1
              else 0
            end
          ),
          0
        ),
        ifnull(
          sum(
            case
              when created < date_add(now(), INTERVAL -2 DAY)
                then 0
              when created < date_add(now(), INTERVAL -1 DAY) 
                then 0
              else 1
            end
          ),
          0
        ),   
        case
          when count(*) = 0 then 'PASS'
          when count(created < date_add(now(), INTERVAL -2 DAY)) > 0 then 'FAIL'
          when count(created < date_add(now(), INTERVAL -1 DAY)) > 0 then 'WARN'
          else 'PASS'
        end as status
      from 
        inv.inv_files f
      where
        billable_size > 0
      and not exists (
        select 
          1
        from
          inv.inv_audits a
        where 
          f.id = a.inv_file_id
      )
      ; 
    }
  end

  def get_headers(results)
    ['File Count', '> 2 days', '1-2 days', '< 1 day', 'Status']
  end

  def get_types(results)
    ['dataint', 'dataint', 'dataint', 'dataint', 'status']
  end
 
  def init_status
    :PASS
  end

end
