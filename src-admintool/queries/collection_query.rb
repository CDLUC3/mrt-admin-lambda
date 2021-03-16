class CollectionQuery < AdminQuery
  def get_title
    "File Counts by Collection"
  end

  def get_filter_col
    3
  end

  def get_group_col
    0
  end

  def get_sql
    %{
      select
        ogroup,
        inv_collection_id,
        mnemonic,
        collection_name,
        sum(count_files) files,
        sum(billable_size) size
      from
        owner_coll_mime_use_details
      group by ogroup, inv_collection_id, mnemonic, collection_name
      order by ogroup, collection_name
    }
  end

  def get_headers(results)
    ['Group', 'Collection Id', 'Mnemonic', 'Name', 'File Count', 'Billable Size']
  end

  def get_types(results)
    ['ogroup', 'coll', 'mnemonic', 'name', 'dataint', 'bytes']
  end

end
