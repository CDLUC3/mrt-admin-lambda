class ConsistencyObjectsQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @copies = CGI.unescape(get_param('copies', '2')).to_i
    @days = CGI.unescape(get_param('days', '0')).to_i
  end

  def get_title
    "Objects with only #{@copies} copies, older than #{@days} days"
  end

  def get_sql
    %{
      select 
        count(*)
      #{sqlfrag_object_copies(@copies, @days)}
      ; 
    }
  end

  def get_headers(results)
    ['Object Count']
  end

  def get_types(results)
    ['dataint']
  end

  def get_alternative_queries
    [
      {
        label: "Object List - #{@copies} copies of an object", 
        url: "path=object_copies_needed&days=#{@days}&limit=500"
      },
      {
        label: "#{@copies} copies of an object", 
        url: "path=con_objects&copies=#{@copies}&days=0"
      },
      {
        label: "#{@copies} copies of an object, older than 1 day", 
        url: "path=con_objects&copies=#{@copies}&days=1"
      },
      {
        label: "#{@copies} copies of an object, older than 2 days", 
        url: "path=con_objects&copies=#{@copies}&days=2"
      },
    ]
  end

end