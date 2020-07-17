class ObjectsRecentQuery < ObjectsQuery
  def initialize(client, path, myparams)
    super(client, path, myparams, 'created')
  end

  def get_title
    "Recently Created Objects"
  end

end
