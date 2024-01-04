# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ObjectsVersionClobberQuery < ObjectsQuery
  def get_title
    'Objects with Version Clobber'
  end

  def get_where
    %{
      where o.id in (
        select
          distinct inv_object_id
        from (
          #{sqlfrag_version_clobber}
        ) as clobber
      )
    }
  end
end
