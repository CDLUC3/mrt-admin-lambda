# frozen_string_literal: true

class AuditProcessedSizeIterativeQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @day = verify_day(get_param('day', Time.new.strftime('%Y-%m-%d')))
  end

  def get_title
    "Audit Files Processed by Hour for #{@day}"
  end

  def get_iterative_sql
    sql = ''

    24.times do |i|
      sql += %( union ) unless i.zero?
      sql += %{
        select
          concat(
            date_format(date_add('#{verify_day(@day)}', interval #{i} HOUR), '%H:00'),
            ' - ',
            date_format(date_add('#{verify_day(@day)}', interval #{i + 1} HOUR), '%H:00')
          ),
          date_format(date_add('#{verify_day(@day)}', interval #{i} HOUR), '%Y-%m-%d %H:00:00'),
          date_format(date_add('#{verify_day(@day)}', interval #{i + 1} HOUR), '%Y-%m-%d %H:00:00')
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
              else 1
            end
          ),
          0
        ) as online_files,
        ifnull(
          sum(
            case
              when a.inv_node_id in (select id from inv.inv_nodes where access_mode != 'on-line')
                then 0
              else full_size
            end
          ),
          0
        ) as online_bytes,
        ifnull(
          sum(
            case
              when a.inv_node_id in (select id from inv.inv_nodes where number in (5001, 3041, 3042))
                then 1
              else 0
            end
          ),
          0
        ) as s3_files,
        ifnull(
          sum(
            case
              when a.inv_node_id in (select id from inv.inv_nodes where number in (5001, 3041, 3042))
                then full_size
              else 0
            end
          ),
          0
        ) as s3_bytes,
        ifnull(
          sum(
            case
              when a.inv_node_id in (select id from inv.inv_nodes where access_mode != 'on-line')
                then 1
              else 0
            end
          ),
          0
        ) as glacier_files,
        ifnull(
          sum(
            case
              when a.inv_node_id in (select id from inv.inv_nodes where access_mode != 'on-line')
                then full_size
              else 0
            end
          ),
          0
        ) as glacier_bytes,
        ifnull(
          sum(
            case
              when a.inv_node_id in (select id from inv.inv_nodes where number in (2001, 2002))
                then 1
              else 0
            end
          ),
          0
        ) as sdsc_files,
        ifnull(
          sum(
            case
              when a.inv_node_id in (select id from inv.inv_nodes where number in (2001, 2002))
                then full_size
              else 0
            end
          ),
          0
        ) as sdsc_bytes,
        ifnull(
          sum(
            case
              when a.inv_node_id in (select id from inv.inv_nodes where number in (9501, 9502))
                then 1
              else 0
            end
          ),
          0
        ) as wasabi_files,
        ifnull(
          sum(
            case
              when a.inv_node_id in (select id from inv.inv_nodes where number in (9501, 9502))
                then full_size
              else 0
            end
          ),
          0
        ) as wasabi_bytes,
        ifnull(
          sum(
            case
              when a.inv_node_id in (select id from inv.inv_nodes where number in (5001, 3041, 3042))
                then 0
              when a.inv_node_id in (select id from inv.inv_nodes where access_mode != 'on-line')
                then 0
              when a.inv_node_id in (select id from inv.inv_nodes where number in (2001, 2002))
                then 0
              when a.inv_node_id in (select id from inv.inv_nodes where number in (9501, 9502))
                then 0
              else 1
            end
          ),
          0
        ) as other_files,
        ifnull(
          sum(
            case
              when a.inv_node_id in (select id from inv.inv_nodes where number in (5001, 3041, 3042))
                then 0
              when a.inv_node_id in (select id from inv.inv_nodes where access_mode != 'on-line')
                then 0
              when a.inv_node_id in (select id from inv.inv_nodes where number in (2001, 2002))
                then 0
              when a.inv_node_id in (select id from inv.inv_nodes where number in (9501, 9502))
                then 0
              else full_size
            end
          ),
          0
        ) as other_bytes
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

  def get_headers(_results)
    [
      'Time Frame',
      'Files Processed',
      'Online Files',
      'Online Bytes',
      'S3 Files',
      'S3 Bytes',
      'Glacier Files',
      'Glacier Bytes',
      'SDSC Files',
      'SDSC Bytes',
      'Wasabi Files',
      'Wasabi Bytes',
      'Other Files',
      'Other Bytes'
    ]
  end

  def get_types(_results)
    [
      '',
      'dataint',
      'dataint',
      'bytes',
      'dataint',
      'bytes',
      'dataint',
      'bytes',
      'dataint',
      'bytes',
      'dataint',
      'bytes',
      'dataint',
      'bytes'
    ]
  end

  def bytes_unit
    '1000000000'
  end

  def get_alternative_queries
    [
      {
        label: 'Prior Day',
        url: "path=audit_processed_hours&iterate=1&day=#{(Time.parse(@day) - (24 * 60 * 60)).strftime('%Y-%m-%d')}",
        class: 'graph'
      },
      {
        label: 'Next Day',
        url: "path=audit_processed_hours&iterate=1&day=#{(Time.parse(@day) + (24 * 60 * 60)).strftime('%Y-%m-%d')}",
        class: 'graph'
      }
    ]
  end

  def show_iterative_total
    true
  end
end
