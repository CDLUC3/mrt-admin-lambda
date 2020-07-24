class ObjectsRecentQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams, 'created')
  end

  def get_title
    "Recently Created Objects"
  end

end
