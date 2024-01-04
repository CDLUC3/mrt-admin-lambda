# frozen_string_literal: true

# Query class - see config/reports.yml for description
class OwnerQuery < AdminQuery
  def get_title
    'File Counts by Owner'
  end

  def get_filter_col
    2
  end

  def get_group_col
    0
  end

  def get_sql
    %{
      select
        ogroup,
        inv_owner_id as owner_id,
        own_name,
        sum(count_files) files,
        sum(billable_size) size
      from
        owner_coll_mime_use_details
      group by
        ogroup,
        owner_id,
        own_name
      order by
        ogroup,
        own_name
    }
  end

  def get_headers(_results)
    ['Group', 'Owner Id', 'Owner', 'File Count', 'Billable Size']
  end

  def get_types(_results)
    %w[ogroup own name dataint bytes]
  end
end
