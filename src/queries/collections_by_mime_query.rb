class CollectionsByMimeQuery < AdminQuery
  def initialize(client, path, myparams, col)
    super(client, path, myparams)
    @mime = myparams.key?('mime') ? myparams['mime'].strip : ''
    @col = (col == 'mime_type' || col == 'mime_group') ? col : 'mime_type'
  end

  def get_params
    [@mime, @mime]
  end

  def get_filter_col
    3
  end

  def get_title
    "Collections for #{@col} #{@mime}"
  end

  def get_sql
    %{
      select
        ogroup,
        inv_collection_id,
        mnemonic,
        collection_name,
        sum(count_files),
        sum(billable_size)
      from
        owner_coll_mime_use_details
      where
        #{@col} = ?
      group by ogroup, inv_collection_id, mnemonic, collection_name
      union
      select
        max('ZZ'),
        max(0),
        max(''),
        max('-- Total --'),
        sum(count_files),
        sum(billable_size)
      from
        owner_coll_mime_use_details
      where
        #{@col} = ?
      order by ogroup, collection_name;
    }
  end

  def get_headers(results)
    ['Group', 'Collection Id', 'Mnemonic', 'Collection Name', 'File Count', 'Billable Size']
  end

  def get_types(results)
    ['ogroup', 'coll', 'mnemonic', 'name', 'dataint', 'dataint']
  end

end