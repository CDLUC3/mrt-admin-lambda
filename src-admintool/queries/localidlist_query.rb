# frozen_string_literal: true

# Query class - see config/reports.yml for description
class LocalidListQuery < IdlistQuery
  def get_title
    "Localid List Query for #{get_params.length} localids"
  end

  def get_params
    @myparams['locallist'].split(',')
  end

  def get_where
    %{
      where
      o.ark in (
        select
            inv_object_ark
          from
            inv.inv_localids li
          where
            li.local_id in (
    } + get_placeholders +
      %{
        ))
      }
  end
end
