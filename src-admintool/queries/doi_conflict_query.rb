class DoiConflictQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "DOI Ark Conflict Query"
  end

  def get_sql
    %{
      select
        substring_index(erc_where, '; ', -1) doi,
        count(distinct ark) c,
        min(ark),
        min(created),
        max(ark),
        max(created)
      from
        inv.inv_objects
      where
        erc_where like '%; doi%'
      group by
        doi
      having
        c > 1
      and 
        min(inv_owner_id) = max(inv_owner_id)
      order by
        min(created)
      ; 
    }
  end

  def get_headers(results)
    ['DOI', 'Num Arks', 'Min Ark', 'First Update', 'Max Ark', 'Last Update']
  end

  def get_types(results)
    ['', '', 'ark', 'datetime', 'ark', 'datetime']
  end

end
