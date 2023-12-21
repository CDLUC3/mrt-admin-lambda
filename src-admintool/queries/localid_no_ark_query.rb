# frozen_string_literal: true

# Query class - see config/reports.yml for description
class LocalidNoIdQuery < AdminQuery
  def get_title
    'Local Ids with No Ark Query'
  end

  def get_sql
    %{
      SELECT
        replace(loc.inv_owner_ark, '%2F', '/') as ownark,
        own.name,
        count(*),
        'INFO' as status
      FROM
        inv.inv_localids loc
      LEFT JOIN
        inv.inv_objects o ON o.ark = loc.inv_object_ark
      LEFT JOIN
        inv.inv_owners own ON replace(loc.inv_owner_ark, '%2F', '/') = own.ark
      WHERE
        o.ark IS null
      group by
        ownark, own.name
      ;
    }
  end

  def get_headers(_results)
    ['Owner Ark', 'Owner Name', 'Count', 'Status']
  end

  def get_types(_results)
    %w[owner name data status]
  end

  def init_status
    :PASS
  end
end
