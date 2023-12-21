# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ListCollectionsQuery < AdminQuery
  def get_title
    'List Collections'
  end

  def get_sql
    %(
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
    )
  end

  def get_headers(_results)
    %w[Group CollId mnemonic Collection]
  end

  def get_types(_results)
    %w[ogroup colllist mnemonic name]
  end
end
