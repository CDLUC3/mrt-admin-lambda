# frozen_string_literal: true

# Query class - see config/reports.yml for description
class MimeQuery < AdminQuery
  def get_title
    'Mime Groups (Producer Files)'
  end

  def get_filter_col
    1
  end

  def get_group_col
    0
  end

  def get_sql
    %{
      select
        mime_group as g,
        mime_type as t,
        sum(count_files),
        sum(billable_size)
      from
        mime_use_details
      where
        source = 'producer'
      group by
        g,
        t
      union
      select
        max('ZZ Merritt System Files') as g,
        max('') as t,
        sum(count_files),
        sum(billable_size)
      from
        mime_use_details
      where
        source != 'producer'
      order by
        g,
        t;
    }
  end

  def get_headers(_results)
    ['Mime Group', 'Mime Type', 'File Count', 'Billable Size']
  end

  def get_types(_results)
    %w[gmime mime dataint bytes]
  end
end
