# frozen_string_literal: true

class LocalidListCompareQuery < IdlistCompareQuery
  def get_title
    "Localid List Compare Query for #{get_params.length} localids"
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

  def is_saveable?
    false
  end
end
