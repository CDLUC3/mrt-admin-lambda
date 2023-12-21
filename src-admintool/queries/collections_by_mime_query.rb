# frozen_string_literal: true

class CollectionsByMimeQuery < AdminQuery
  def initialize(query_factory, path, myparams, col)
    super(query_factory, path, myparams)
    @mime = get_param('mime', '')
    @col = verify_mime_col(col)
  end

  def get_params
    [@mime]
  end

  def get_group_col
    0
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
        #{verify_mime_col(@col)} = ?
      group by ogroup, inv_collection_id, mnemonic, collection_name
      order by ogroup, collection_name;
    }
  end

  def get_headers(_results)
    ['Group', 'Collection Id', 'Mnemonic', 'Collection Name', 'File Count', 'Billable Size']
  end

  def get_types(_results)
    %w[ogroup coll mnemonic name dataint bytes]
  end
end
