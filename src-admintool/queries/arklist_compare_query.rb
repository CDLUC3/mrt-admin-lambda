class ArklistCompareQuery < IdlistCompareQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Arklist Compare Query for #{get_params.length} arks"
  end

  def get_params
    @myparams['arklist'].split(',')
  end

  def get_where
    %{
      where 
      o.ark in (
      } + get_placeholders +
      %{
      )    
    }
  end
end