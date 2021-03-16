class CollectionDetailsQuery < AdminQuery
  def initialize(query_factory, path, myparams, col)
    super(query_factory, path, myparams)
    @coll = get_param('coll', '')
    @col = (col == 'inv_collection_id' || col == 'ogroup') ? col : 'inv_collection_id'
  end

  def get_params
    [@coll, @coll]
  end

  def get_filter_col
    1
  end

  def get_group_col
    0
  end

  def get_title
    "Collection Details for #{@col} #{@coll}"
  end

  def get_sql
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
      union
      select
        max('ZZ Merritt System Files') as mime_group,
        max('') as mime_type,
        sum(count_files),
        sum(billable_size)
      from
        owner_coll_mime_use_details
      where
        source != 'producer'
      and
        #{@col} = ?
      order by
      mime_group, mime_type
    }
  end

  def get_headers(results)
    ['Mime Group', 'Mime Type', 'File Count', 'Billable Size']
  end

  def get_types(results)
    ['gmime', 'mime', 'dataint', 'bytes']
  end

end
