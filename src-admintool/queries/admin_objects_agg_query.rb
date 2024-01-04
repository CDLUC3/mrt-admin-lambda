# frozen_string_literal: true

# Query class - see config/reports.yml for description
class AdminObjectsAggQuery < AdminQuery
  def get_title
    'Admin Objects Aggregate'
  end

  def get_sql
    %{
      select
        ifnull(aggregate_role, 'Null_Value') as aggregate_role,
        count(*),
        case
          when aggregate_role is null and count(*) > 0 then 'INFO'
          else 'PASS'
        end as status
      from
        inv.inv_objects
      where
        aggregate_role != 'MRT-none'
      or
        aggregate_role is null
      group by
        aggregate_role
      ;
    }
  end

  def get_headers(_results)
    ['Aggregate Role', 'Count', 'Status']
  end

  def get_types(_results)
    %w[aggrole data status]
  end
end
