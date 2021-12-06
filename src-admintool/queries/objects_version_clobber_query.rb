class ObjectsVersionClobberQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Objects with Version Clobber"
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
