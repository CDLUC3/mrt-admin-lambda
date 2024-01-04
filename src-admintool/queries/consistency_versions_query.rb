# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ConsistencyVersionsQuery < AdminQuery
  def get_title
    'Objects with version clobber'
  end

  def get_sql
    %{
      select
        'Version Clobber (Duplicate Version Num)',
        ifnull(count(distinct inv_object_id), 0),
        case
          when count(*) = 0 then 'PASS'
          else 'FAIL'
        end as status
      from (
        #{sqlfrag_version_clobber}
      ) as clobber
      union
      select
        'Version Number Gap',
        ifnull(count(distinct inv_object_id), 0),
        case
          when count(*) = 0 then 'PASS'
          else 'FAIL'
        end as status
      from (
        #{sqlfrag_version_gap}
      ) as gap
      ;
    }
  end

  def get_headers(_results)
    ['Category', 'Object Count', 'Status']
  end

  def get_types(_results)
    ['', 'dataint', 'status']
  end

  def init_status
    :PASS
  end

  def get_alternative_queries
    [
      {
        label: 'Object List - Version Clobber',
        url: 'path=obj_version_clobber',
        class: 'objects'
      },
      {
        label: 'Object List - Version Gap',
        url: 'path=obj_version_gap',
        class: 'objects'
      }
    ]
  end
end
