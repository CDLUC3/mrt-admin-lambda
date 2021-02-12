class IdlistQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @fields = myparams.fetch('fields', '')
  end

  def get_title
    "Id List Query for #{get_params.length} ids"
  end

  def get_placeholders
    buf = []
    get_params.each do |ark|
      buf.append('?')
    end
    buf.join(',')
  end

  def get_params
    @myparams['idlist'].split(',')
  end

  def get_where
    %{
      where ... in (
    } + get_placeholders +
    %{
      )    
    }
  end

  def get_sql
    sql = %{
select 
  trim(substring_index(o.erc_where, ';', -1)) doi,
  o.ark,
  date(created),
} 

  if @fields == 'summary'
    sql = sql + %{
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
  ) as psize,
  }
  end

  if @fields == 'metadata'
    sql = sql + %{
  erc_what,
  erc_who,
  erc_when
  }
  end

  sql = sql + %{
  ''
from
  inv.inv_objects o
} + get_where +
%{
order by doi, created
;
  }
  sql
end

def get_headers(results)
  arr = ['Parsed erc_where', 'Ark', 'Created']
  if @fields == 'summary'
    ['Num Ver', 'Num File', 'Producer Files', 'File Size', 'Producer Size'].each do |r|
      arr.append(r)
    end
  elsif @fields == 'metadata'
    ['Title', 'Author', 'Date'].each do |r|
      arr.append(r)
    end
  end
  arr.append('')
  arr
end

def get_types(results)
  arr = ['localid', 'ark', 'date']
  if @fields == 'summary'
    ['data', 'data', 'data', 'data', 'data'].each do |r|
      arr.append(r)
    end
  elsif @fields == 'metadata'
    ['name', 'name', ''].each do |r|
      arr.append(r)
    end
  end
  arr.append('na')
  arr
end

end