class ListCollectionsQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "List Collections"
  end

  def get_sql
    %{
      select
        distinct
        ogroup,
        inv_collection_id,
        mnemonic,
        collection_name
      from
        owner_collections
      order by
        ogroup,
        mnemonic
    }
  end

  def get_headers(results)
    ['Group', 'CollId', 'mnemonic', 'Collection']
  end

  def get_types(results)
    ['ogroup', 'colllist', 'mnemonic', 'name']
  end

end
