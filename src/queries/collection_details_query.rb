class CollectionDetailsQuery < AdminQuery
  def initialize(query_factory, path, myparams, col)
    super(query_factory, path, myparams)
    @coll = get_param('coll', '')
    @col = (col == 'inv_collection_id' || col == 'ogroup') ? col : 'inv_collection_id'
  end

  def get_params(total = true)
    if total
      [@coll, @coll, @coll, @coll]
    else
      [@coll]
    end
  end

  def get_filter_col
    1
  end

  def get_title
    "Collection Details for #{@col} #{@coll}"
  end

  def get_base_sql
    %{
      select
        mime_group,
        mime_type,
        sum(count_files),
        sum(billable_size)
      from
        owner_coll_mime_use_details
      where
        source = 'producer'
      and
        #{@col} = ?
      group by
        mime_group, mime_type
    }
  end

  def get_union_sql
    %{
      union
      select
        mime_group,
        max('-- Total --') as mime_type,
        sum(count_files),
        sum(billable_size)
      from
        owner_coll_mime_use_details
      where
        source = 'producer'
      and
        #{@col} = ?
      group by
        mime_group
      union
      select
        max('ZZ Merritt System') as mime_group,
        max('-- Special Total --') as mime_type,
        sum(count_files),
        sum(billable_size)
      from
        owner_coll_mime_use_details
      where
        source != 'producer'
      and
        #{@col} = ?
      union
      select
        max('ZZZ') as mime_group,
        max('-- Grand Total --') as mime_type,
        sum(count_files),
        sum(billable_size)
      from
        owner_coll_mime_use_details
      where
        #{@col} = ?
    }
  end
  
  def get_order_sql
    %{
      order by
      mime_group, mime_type
    }
  end

  def get_headers(results)
    ['Mime Group', 'Mime Type', 'File Count', 'Billable Size']
  end

  def get_types(results)
    ['gmime', 'mime', 'dataint', 'dataint']
  end

end
