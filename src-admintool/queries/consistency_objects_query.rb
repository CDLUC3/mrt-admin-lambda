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
      from (
        select 
          inio.inv_object_id,
          min(created) as init_created
        from
          inv.inv_nodes_inv_objects inio
        inner join (
          select 
            inv_object_id, 
            count(*) 
          from 
            inv.inv_nodes_inv_objects 
          group by 
            inv_object_id 
          having 
            count(*) = ?
        ) as copies
          on copies.inv_object_id = inio.inv_object_id
        group by 
          inv_object_id 
        having
          min(created) < date_add(now(), INTERVAL -? DAY)
      ) as age
      ; 
    }
  end

  def get_params
    [ 
      @copies,
      @days
    ]
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
