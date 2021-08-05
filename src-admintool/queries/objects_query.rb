class ObjectsQuery < AdminQuery
  def initialize(query_factory, path, myparams, sort='id')
    super(query_factory, path, myparams)
    if sort == 'created'
      @sort = 'o.created desc'
    elsif sort == 'modified'
        @sort = 'o.modified desc'
    else
      @sort = 'o.id asc'
    end
  end

  def get_title
    "Object Query"
  end

  def get_where
    ""
  end

  def get_sql
    %{
      select
        o.id,
        o.ark,
        o.erc_what,
        substr(o.erc_who,1,200),
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
    } + get_obj_limit_query
  end

  # disable the following if limit has already been applied
  def get_obj_limit_query
    %{
      limit #{get_limit} offset #{get_offset};
    }
  end

  def get_headers(results)
    ['Object Id','Ark', 'Title', 'Author', 'Local Id', 'Version', 'Coll Id', 'Collection', 'File Count', 'Billable Size', 'Modified']
  end

  def get_types(results)
    ['', 'ark', 'name', '', '', '', 'coll', 'mnemonic', 'dataint', 'bytes', 'datetime']
  end

  def get_alternative_queries
    get_alternative_limit_queries
  end

  def page_size
    get_limit
  end

end
