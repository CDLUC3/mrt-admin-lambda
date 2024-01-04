# frozen_string_literal: true

# Query class - see config/reports.yml for description
class AdminObjectsQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @aggrole = verify_aggregate_role(get_param('aggrole', 'Null_Value'))
  end

  def get_title
    "Admin Objects: #{@aggrole}"
  end

  def agg_table
    return 'inv.inv_owners' if @aggrole == 'MRT-owner'

    'inv.inv_collections'
  end

  def get_sql
    %{
      select
        o.id,
        o.ark,
        (select ark from #{agg_table} where inv_object_id=o.id) as altark,
        ifnull(own.name,'No name') as owner,
        own.ark as ownerark,
        (
          select
            group_concat(ifnull(c.mnemonic, ifnull(c.name, c.ark)))
          from
            inv.inv_collections c
          inner join
            inv.inv_collections_inv_objects icio
          on
            c.id = icio.inv_collection_id
          where
            icio.inv_object_id = o.id
        ) as colls,
        o.object_type,
        o.role,
        o.aggregate_role,
        erc_what,
        o.created,
        case
          when o.ark != ifnull((select ark from #{agg_table} where inv_object_id=o.id), '') then 'FAIL'
          when o.aggregate_role is null then 'INFO'
          else 'PASS'
        end as status
      from
        inv.inv_objects o
      inner join inv.inv_owners own
        on own.id = o.inv_owner_id
      where
        #{
          if @aggrole == 'Null_Value'
            'aggregate_role is null'
          else
            "aggregate_role = '#{verify_aggregate_role(@aggrole)}'"
          end
        }
      order by
        created desc
      ;
    }
  end

  def get_headers(_results)
    ['Obj Id', 'Obj Ark', 'Coll/Own Ark', 'Owner', 'OwnerArk', 'Collections', 'Type', 'Role', 'Aggregate Role', 'Name',
     'Created', 'Status']
  end

  def get_types(_results)
    ['objlist', 'ark', 'ark', '', '', 'list', '', '', '', 'name', 'datetime', 'status']
  end

  def get_alternative_queries
    [
      {
        label: 'Admin Object Counts by Aggegate Role',
        url: 'path=admin_obj_agg',
        class: 'graph'
      },
      {
        label: "Admin Object File List for #{@aggrole}",
        url: "path=admin_obj_files&aggrole=#{@aggrole}",
        class: 'files'
      }
    ]
  end
end
