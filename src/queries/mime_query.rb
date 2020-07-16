class MimeQuery < AdminQuery
  def get_title
    "Mime Groups (Producer Files)"
  end

  def get_filter_col
    1
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
        mime_group as g,
        max('-- Total --') as t,
        sum(count_files),
        sum(billable_size)
      from
        mime_use_details
      where
        source = 'producer'
      group by
        g
      union
      select
        max('ZZ Merritt System') as g,
        max('-- Special Total --') as t,
        sum(count_files),
        sum(billable_size)
      from
        mime_use_details
      where
        source != 'producer'
      union
      select
        max('ZZZ') as g,
        max('-- Grand Total --') as t,
        sum(count_files),
        sum(billable_size)
      from
        mime_use_details
      order by
        g,
        t;
    }
  end

  def get_headers(results)
    ['Mime Group', 'Mime Type', 'File Count', 'Billable Size']
  end

  def get_types(results)
    ['gmime', 'mime', 'dataint', 'dataint']
  end

end
