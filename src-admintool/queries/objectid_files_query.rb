# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ObjectIdFilesQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super
    @id = myparams.fetch('id', 0).to_i
  end

  def get_title
    "Object File Listing for #{@id}"
  end

  def get_sql
    %{
      select
        o.ark,
        v.number,
        (
          select max(vv.number)
          from inv.inv_files ff
          inner join inv.inv_versions vv
            on ff.inv_version_id = vv.id
          where
            ff.inv_object_id = o.id
          and exists (
            select 1 where ff.pathname=f.pathname
          )
        ) as maxv,
        f.source,
        binary f.pathname,
        f.full_size,
        f.created,
        ifnull(group_concat(n.number), '') as nodelist,
        ifnull(
          group_concat(
            case
              when a.status = 'verified' then null
              else n.number
            end
          ),
          ''
        ) as unverified
      from
        inv.inv_objects o
      inner join inv.inv_versions v
        on o.id = v.inv_object_id
      inner join inv.inv_files f
        on o.id = f.inv_object_id
        and v.id = f.inv_version_id
      left join inv.inv_audits a
        on
          o.id = a.inv_object_id
        and
          f.id = a.inv_file_id
      left join inv.inv_nodes n
        on a.inv_node_id = n.id
      where
        o.id = ?
      and
        f.billable_size = f.full_size
      group by
        o.ark,
        v.number,
        f.source,
        binary f.pathname,
        f.full_size,
        f.created
      order by
        f.created desc,
        source,
        pathname
      limit 2000
      ;
    }
  end

  def get_params
    [@id]
  end

  def get_headers(_results)
    ['Ark', 'Version', 'MaxVer', 'Source', 'Path', 'File Size', 'Created', 'Nodes', 'Unverified']
  end

  def get_types(_results)
    ['ark', '', '', '', 'name', 'bytes', 'datetime', '', '']
  end

  def get_alternative_queries
    [
      {
        label: 'Storage Management for Object',
        url: "#{LambdaBase.colladmin_root_url}/web/storeObjectNodes.html?id=#{@id}",
        class: 'config'
      }
    ]
  end
end
