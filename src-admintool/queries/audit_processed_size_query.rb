class AuditProcessedSizeQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @day = get_param('day', Time.new.strftime('%Y-%m-%d'))
  end

  def get_title
    "Audit Files Processed on #{@day}"
  end

  def get_iterative_sql
    sql = ""

    for i in 0..23
      sql = sql + %{ union } unless i == 0
      sql = sql + %{
        select
          concat(
            date_format(date_add('#{@day}', interval #{i} HOUR), '%H:00:00'),
            ' - ',
            date_format(date_add('#{@day}', interval #{i+1} HOUR), '%H:00:00')
          ),
          date_format(date_add('#{@day}', interval #{i} HOUR), '%Y-%m-%d %H:00:00'),
          date_format(date_add('#{@day}', interval #{i+1} HOUR), '%Y-%m-%d %H:00:00')
      }
    end

    sql
  end

  def get_sql
    %{
      select
        ? as title,
        count(a.id) as pcount,
        ifnull(
          sum(
            case 
              when a.inv_node_id in (select id from inv.inv_nodes where access_mode != 'on-line') 
                then 0
              else full_size
            end
          ), 
          0
        ) as online_bytes
      from
        inv.inv_audits a
      inner join inv.inv_files f
        on 
          f.id = a.inv_file_id
        and 
          f.inv_object_id = a.inv_object_id
        and
          f.inv_version_id = a.inv_version_id
      where
        verified >= ?
      and
        verified < ?
      ;
    }
  end

  def get_headers(results)
    ['Time Frame', 'Files Processed', 'On-line Bytes Processed']
  end

  def get_types(results)
    ['', 'dataint', 'bytes']
  end

  def bytes_unit
    "1000000000"
  end

  def get_alternative_queries
    [
      {
        label: 'Prior Day', 
        url: 'path=audit_processed_size&iterate=1&day=' + (Time.parse(@day) - 24*60*60).strftime('%Y-%m-%d')
      },
      {
        label: 'Next Day', 
        url: 'path=audit_processed_size&iterate=1&day=' + (Time.parse(@day) + 24*60*60).strftime('%Y-%m-%d')
      }
    ]
  end

  def show_iterative_total
    true
  end

end
