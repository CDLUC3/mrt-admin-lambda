class ArklistQuery < AdminQuery
  def get_title
    "Arklist Query for #{get_params.length} arks"
  end

  def get_placeholders
    buf = []
    get_params.each do |ark|
      buf.append('?')
    end
    buf.join(',')
  end

  def get_params
    @myparams['arklist'].split(',')
  end

  def get_sql
    %{
select 
  trim(substring_index(o.erc_where, ';', -1)) doi,
  o.ark,
  date(created),
  (select count(*) from inv.inv_versions v where v.inv_object_id=o.id) as vercount,
  (select count(*) from inv.inv_files f where f.inv_object_id=o.id) as filecount
from
  inv.inv_objects o
where 
  o.ark in (
  } + get_placeholders +
  %{
  )
order by doi, created
;
}
end

def get_headers(results)
  ['DOI', 'Ark', 'Created', 'Num Ver', 'Num File']
end

def get_types(results)
  ['doi', 'ark', 'date', 'data', 'data']
end

end