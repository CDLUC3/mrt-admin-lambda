# frozen_string_literal: true

# Query class - see config/reports.yml for description
class CollectionsByOwnerQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super
    @own = get_param('own', '')
  end

  def get_params
    [@own]
  end

  def get_title
    "Counts by Owner #{@own}"
  end

  def get_sql
    %{
      select
        c.id,
        c.mnemonic,
        c.name,
        sum(dmud.count_files),
        sum(dmud.billable_size)
      from
        inv.inv_collections c
      inner join daily_mime_use_details dmud
        on dmud.inv_collection_id = c.id
      where
        dmud.inv_owner_id = ?
      group by
        c.id,
        c.mnemonic,
        c.name
      order by
        c.name
    }
  end

  def get_headers(_results)
    ['Collection Id', 'Mnemonic', 'Collection Name', 'File Count', 'Billable Size']
  end

  def get_types(_results)
    ['coll', 'mnemonic', '', 'dataint', 'bytes']
  end
end
