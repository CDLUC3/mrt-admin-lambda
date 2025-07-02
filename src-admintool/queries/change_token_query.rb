# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ChangeTokenQuery < AdminQuery
  def get_title
    'Change Token Report'
  end

  def get_sql
    %{
      select
        c.mnemonic as mnemonic,
        min(date(f.created)) as processed_min,
        max(date(f.created)) as processed_max,
        min(date(i.submitted)) as submitted_min,
        max(date(i.submitted)) as submitted_max,
        count(f.inv_object_id) as obj_count,
        sum(os.billable_size) as billable_size
      from
        inv.inv_files f
      inner join inv.inv_collections_inv_objects icio
        on icio.inv_object_id = f.inv_object_id
      inner join inv.inv_collections c
        on c.id = icio.inv_collection_id
      left join object_size os
        on f.inv_object_id = os.inv_object_id
      left join inv.inv_ingests i
        on f.inv_object_id = i.inv_object_id
      where
        f.pathname = 'system/provenance_manifest.xml'
      group by
        c.mnemonic
      ;
    }
  end

  def get_headers(_results)
    ['Mnemonic', 'Processed Min', 'Processed Max', 'Ingest Min', 'Ingest Max', 'Obj Count', 'New Billable Size']
  end

  def get_types(_results)
    %w[mnemonic datetime datetime datetime datetime dataint bytes]
  end
end
