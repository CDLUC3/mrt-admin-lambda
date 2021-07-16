class ObjectsMultipleCollQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams, 'modified')
  end

  def get_title
    "Objects linked to multiple collections"
  end

  def get_where
    %{
      where o.id in (
        select
          inv_object_id
        from 
          inv.inv_collections_inv_objects
        group by
          inv_object_id
        having 
          count(*) > 1
      )
    }
  end

  def get_sql
    %{
      select
        o.id,
        o.ark,
        o.erc_what,
        o.erc_who,
        o.erc_where,
        o.version_number,
        (
          select 
            group_concat(inv_collection_id) 
          from 
            inv.inv_collections_inv_objects 
          where 
            inv_object_id = o.id
        ) as collection_id,
        (
          select 
            group_concat(mnemonic)
          from
            inv.inv_collections 
          where 
            id in (
              select
                inv_collection_id
              from 
                inv.inv_collections_inv_objects 
              where 
                inv_object_id = o.id    
            )
        ) as mnemonic,
        (
          select
            count(f.id)
          from
            inv.inv_files f
          where
            f.inv_object_id=o.id
        ) as obj_count,
        (
          select
            sum(f.billable_size)
          from
            inv.inv_files f
          where
            f.inv_object_id=o.id
        ) as billable_size,
        o.modified as modified
      from
        inv.inv_objects o
    } + get_where +
    %{  
      order by #{@sort}
      limit #{get_limit} offset #{get_offset};
    }
  end

  def evaluate_status(types, data)
    if data.length > 0
      @report_status = :WARN
    end
  end

  def page_size
    get_limit
  end

end
