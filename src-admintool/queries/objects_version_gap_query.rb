# frozen_string_literal: true

class ObjectsVersionGapQuery < ObjectsQuery
  def get_title
    'Objects with Version Gap'
  end

  def get_where
    %{
      where o.id in (
        select
          distinct inv_object_id
        from (
          #{sqlfrag_version_gap}
        ) as clobber
      )
    }
  end
end
