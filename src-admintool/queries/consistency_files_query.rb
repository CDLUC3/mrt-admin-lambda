class ConsistencyFilesQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @copies = CGI.unescape(get_param('copies', '2')).to_i
  end

  def get_title
    "Files with only #{@copies} copies"
  end

  def get_sql
    %{
      select 
        count(*) 
      from (
        select 
          inv_file_id, 
          count(*) 
        from 
          inv.inv_audits 
        group by 
          inv_file_id 
        having 
          count(*) = ?
      ) as foo;
      ; 
    }
  end

  def get_params
    [ 
      @copies
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
        label: 'One copy', 
        url: 'path=con_files&copies=1'
      },
      {
        label: 'Two copies', 
        url: 'path=con_files&copies=2'
      },
      {
        label: 'Four copies', 
        url: 'path=con_files&copies=4'
      },
    ]
  end

end
