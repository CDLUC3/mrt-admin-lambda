# frozen_string_literal: true

class CollectionInfoQuery < AdminQuery
  def initialize(query_factory, path, myparams, _col)
    super(query_factory, path, myparams)
    @coll = get_param('coll', '')
  end

  def get_params
    [@coll, @coll]
  end

  def get_title
    "Collection Information for #{@coll}"
  end

  def get_sql
    %{
      select
        name,
        ark,
        mnemonic,
        concat(mnemonic, '_content') as profile,
        id,
        (
          select
            count(*)
          from
            inv.inv_collections_inv_objects icio
          where
            c.id = icio.inv_collection_id
        ) as obj,
        mnemonic as ldap,
        id as snodes
      from
        inv.inv_collections c
      where
        id = ? or mnemonic = ?
    }
  end

  def get_headers(_results)
    ['Name', 'Ark', 'Mnemonic', 'Profile', 'File Info', 'Obj Count', 'LDAP', 'Nodes']
  end

  def get_types(_results)
    %w[name ark mnemonic profile coll dataint ldapcoll snodes]
  end

  def get_alternative_queries
    [
      {
        label: "File counts for collection #{@coll}",
        url: "path=collection_details&coll=#{@coll}",
        class: 'graph'
      }
    ]
  end
end
