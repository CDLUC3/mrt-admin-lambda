# frozen_string_literal: true

# Query class - see config/reports.yml for description
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
    get_params.each do |_ark|
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
      sql += %{
  (
    select count(*)
    from inv.inv_versions v
    where v.inv_object_id=o.id
  ) as vercount,
  (
    select count(*)
    from inv.inv_files f
    where f.inv_object_id=o.id
      and billable_size = full_size
  ) as filecount,
  (
    select count(*)
    from inv.inv_files f
    where f.inv_object_id=o.id and source='producer'
      and billable_size = full_size
  ) as pfilecount,
  (
    select group_concat(substr(f.pathname,10))
    from inv.inv_files f
    where f.inv_object_id=o.id and source='producer'
      and billable_size = full_size
  ),
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
      sql += %(
  erc_what,
  erc_who,
  erc_when
  )
    end

    sql + %(
  ''
from
  inv.inv_objects o
) + get_where +
      %(
    order by doi, created
    ;
      )
  end

  def get_headers(_results)
    arr = ['Parsed erc_where', 'Ark', 'Created']
    if @fields == 'summary'
      ['Num Ver', 'Num File', 'Producer Files', 'Files', 'File Size', 'Producer Size'].each do |r|
        arr.append(r)
      end
    elsif @fields == 'metadata'
      %w[Title Author Date].each do |r|
        arr.append(r)
      end
    end
    arr.append('')
    arr
  end

  def get_types(_results)
    arr = %w[localid ark date]
    if @fields == 'summary'
      %w[data data data list data data].each do |r|
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
