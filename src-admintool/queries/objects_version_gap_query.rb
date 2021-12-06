class ObjectsVersionGapQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Objects with Version Gap"
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
