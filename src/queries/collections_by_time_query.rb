class CollectionsByTimeQuery < AdminQuery
  def initialize(client, path, myparams, col)
    super(client, path, myparams)
    @col = (col == 'count_files' || col == 'billable_size') ? col : 'count_files'
    @start=2013
    @end=Time.now.year
  end

  def get_filter_col
    2
  end

  def get_title
    "Collection #{@col} Over Time"
  end

  def get_sql
    sql = %{
      select distinct
        ogroup,
        inv_collection_id,
        collection_name,
    }
    for yr in @start..@end do
      sql += %{
        (
          select
            sum(#{@col})
          from
            owner_coll_mime_use_details ocmud2
          where
            ocmud2.inv_collection_id = ocmud.inv_collection_id
          and
            ocmud2.ogroup = ocmud.ogroup
          and
            date_added >= '#{yr}-01-01'
          and
            date_added <= '#{yr}-12-31'
        ) as yr#{yr},
      }
    end
    sql += %{
        (
          select
            sum(#{@col})
          from
            owner_coll_mime_use_details ocmud2
          where
            ocmud2.inv_collection_id = ocmud.inv_collection_id
          and
            ocmud2.ogroup = ocmud.ogroup
        ) as total
      from
        owner_coll_mime_use_details ocmud
      union
      select distinct
        ogroup,
        0 as inv_collection_id,
        '-- Total --' as collection_name,
    }
    for yr in @start..@end do
      sql += %{
        (
          select
            sum(#{@col})
          from
            owner_coll_mime_use_details ocmud2
          where
            ocmud2.ogroup = ocmud.ogroup
          and
            date_added >= '#{yr}-01-01'
          and
            date_added <= '#{yr}-12-31'
        ) as yr#{yr},
      }
    end
    sql += %{
        (
          select
            sum(#{@col})
          from
            owner_coll_mime_use_details ocmud2
          where
            ocmud2.ogroup = ocmud.ogroup
        ) as total
      from
        owner_coll_mime_use_details ocmud
      union
      select distinct
        'ZZ' as ogroup,
        0 as inv_collection_id,
        '-- Grand Total --' as collection_name,
    }
    for yr in @start..@end do
      sql += %{
        (
          select
            sum(#{@col})
          from
            owner_coll_mime_use_details ocmud2
          where
            date_added >= '#{yr}-01-01'
          and
            date_added <= '#{yr}-12-31'
        ) as yr#{yr},
      }
    end
    sql += %{
        (
          select
            sum(#{@col})
          from
            owner_coll_mime_use_details ocmud2
        ) as total
      from
        owner_coll_mime_use_details ocmud
      order by ogroup, inv_collection_id, collection_name
    }
    sql
  end

  def get_headers(results)
    heads = ['Group', 'Collection Id', 'Collection Name']
    for yr in @start..@end do
      heads.push(yr)
    end
    heads.push('Total')
    heads
  end

  def get_types(results)
    types = ['ogroup', 'coll', 'name']
    for yr in @start..@end+1 do
      types.push('dataint')
    end
    types
  end

end
