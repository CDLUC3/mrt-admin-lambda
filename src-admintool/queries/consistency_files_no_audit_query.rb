class ConsistencyFilesNoAuditQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @days = CGI.unescape(get_param('days', '0')).to_i
  end

  def report_name
    "#{@path}.#{@days}days"
  end

  def get_title
    "Files missing from the audit table, older than #{@days} days"
  end

  def get_sql
    %{
      select 
        count(*),
        case
          when count(*) = 0 then 'PASS'
          when #{@days} = 0 then 'SKIP'
          when #{@days} = 1 then 'WARN'
          when #{@days} >= 2 then 'FAIL'
          else 'SKIP'
        end as status
      from 
        inv.inv_files f
      where
        billable_size > 0
      and
        created < date_add(now(), INTERVAL -#{@days} DAY)
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
    ['File Count', 'Status']
  end

  def get_types(results)
    ['dataint', 'status']
  end

  def get_alternative_queries
    [
      {
        label: "files not in audit table", 
        url: "path=con_no_audit&days=0"
      },
      {
        label: "files not in audit table, older than 1 day", 
        url: "path=con_no_audit&days=1"
      },
      {
        label: "files not in audit table, older than 2 days", 
        url: "path=con_no_audit&days=2"
      },
    ]
  end
  
  def init_status
    :PASS
  end

end
