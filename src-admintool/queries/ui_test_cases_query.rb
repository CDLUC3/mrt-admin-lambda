# frozen_string_literal: true

# Query class - see config/reports.yml for description
class UITestCasesQuery < AdminQuery
  def get_title
    'UI Test Cases'
  end

  def get_sql
    sample = 3
    sql = ''.dup
    list = %w[merritt_demo escholarship ucb_lib_cal_cultures ucb_lib_dcpp ucb_lib_metcalf ucb_lib_jar ucb_lib_prechmat
              ucb_lib_stone_rubbings]
    list.each do |coll|
      sql << 'union ' unless sql.empty?
      sql << %{
        select
          'Long mime type' as category,
          q.mnemonic,
          q.ark ark,
          q.ark arkdev,
          q.erc_what
        from
        (
          select distinct
            f.inv_object_id,
            c.mnemonic,
            o.ark,
            o.erc_what
          from
            inv.inv_files f
          inner join inv.inv_objects o
            on f.inv_object_id = o.id
          inner join inv.inv_collections_inv_objects icio
            on o.id = icio.inv_object_id
          inner join inv.inv_collections c
            on icio.inv_collection_id = c.id
          where
            length(mime_type) > 70 and source = 'producer'
          and
            c.mnemonic = '#{coll}'
          limit #{sample}
        ) as q
        union
        select
          'Long pathname' as category,
          q.mnemonic,
          q.ark ark,
          q.ark arkdev,
          q.erc_what
        from
        (
          select distinct
            f.inv_object_id,
            c.mnemonic,
            o.ark,
            o.erc_what
          from
            inv.inv_files f
          inner join inv.inv_objects o
            on f.inv_object_id = o.id
          inner join inv.inv_collections_inv_objects icio
            on o.id = icio.inv_object_id
          inner join inv.inv_collections c
            on icio.inv_collection_id = c.id
          where
            length(SUBSTRING_INDEX(pathname,'/',-1)) > 80 and source = 'producer'
          and
            c.mnemonic = '#{coll}'
          limit #{sample}
        ) as q
        union
        select
          'Many files' as category,
          q.mnemonic,
          q.ark ark,
          q.ark arkdev,
          q.erc_what
        from
        (
          select distinct
            os.inv_object_id,
            c.mnemonic,
            o.ark,
            o.erc_what
          from
            billing.object_size os
          inner join inv.inv_objects o
            on os.inv_object_id = o.id
          inner join inv.inv_collections_inv_objects icio
            on o.id = icio.inv_object_id
          inner join inv.inv_collections c
            on icio.inv_collection_id = c.id
          where
            file_count > 500
          and
            c.mnemonic = '#{coll}'
          limit #{sample}
        ) as q
      }

      next unless coll == 'merritt_demo'

      sql << %{
        union
        select
          'Non Ascii pathname (demo only)' as category,
          q.mnemonic,
          q.ark ark,
          q.ark arkdev,
          q.erc_what
        from
        (
          select distinct
            f.inv_object_id,
            c.mnemonic,
            o.ark,
            o.erc_what
          from
            inv.inv_files f
          inner join inv.inv_objects o
            on f.inv_object_id = o.id
          inner join inv.inv_collections_inv_objects icio
            on o.id = icio.inv_object_id
          inner join inv.inv_collections c
            on icio.inv_collection_id = c.id
          where
            pathname <> CONVERT(pathname USING ASCII) and source = 'producer'
          and
            c.mnemonic = '#{coll}'
          limit #{sample}
        ) as q
        union
        select
          'Non Ascii erc_what (demo only)' as category,
          q.mnemonic,
          q.ark ark,
          q.ark arkdev,
          q.erc_what
        from
        (
          select distinct
            o.id,
            c.mnemonic,
            o.ark,
            o.erc_what
          from
            inv.inv_objects o
          inner join inv.inv_collections_inv_objects icio
            on o.id = icio.inv_object_id
          inner join inv.inv_collections c
            on icio.inv_collection_id = c.id
          where
            erc_what <> CONVERT(erc_what USING ASCII)
          and
            c.mnemonic = '#{coll}'
          limit #{sample}
        ) as q
      }
    end
    sql
  end

  def get_headers(_results)
    ['Category', 'Mnemonic', 'Ark', 'Dev Ark', 'Title']
  end

  def get_types(_results)
    %w['' '' ark arkdev name]
  end
end
