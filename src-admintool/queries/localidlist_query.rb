class LocalidListQuery < AdminQuery
  def get_title
    "Localid List Query for #{get_params.length} localids"
  end

  def get_placeholders
    buf = []
    get_params.each do |ark|
      buf.append('?')
    end
    buf.join(',')
  end

  def get_params
    @myparams['locallist'].split(',')
  end

  def get_sql
    %{
select 
  trim(substring_index(o.erc_where, ';', -1)) local,
  o.ark,
  date(created),
  (
    select count(*) 
    from inv.inv_versions v 
    where v.inv_object_id=o.id
  ) as vercount,
  (
    select count(*) 
    from inv.inv_files f 
    where f.inv_object_id=o.id
  ) as filecount,
  (
    select count(*) 
    from inv.inv_files f 
    where f.inv_object_id=o.id and source='producer'
  ) as pfilecount,
  (
    select sum(billable_size) 
    from inv.inv_files f 
    where f.inv_object_id=o.id
  ) as size,
  (
    select sum(billable_size) 
    from inv.inv_files f 
    where f.inv_object_id=o.id and source='producer'
  ) as psize
from
  inv.inv_objects o
where 
  o.ark in (
    select 
        inv_object_ark
      from 
        inv.inv_localids li
      where 
        li.local_id in (
  } + get_placeholders +
  %{
  ))
order by local, created
;
}
end

def get_headers(results)
  ['Parsed erc_where', 'Ark', 'Created', 'Num Ver', 'Num File', 'Producer Files', 'File Size', 'Producer Size']
end

def get_types(results)
  ['localid', 'ark', 'date', 'data', 'data', 'data', 'data', 'data']
end

end