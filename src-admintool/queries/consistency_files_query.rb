class ConsistencyFilesQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @copies = CGI.unescape(get_param('copies', '2')).to_i
    @days = CGI.unescape(get_param('days', '0')).to_i
  end

  def get_title
    "Files with only #{@copies} copies, older than #{@days} days"
  end

  def get_sql
    %{
      select 
        count(*)
      #{sqlfrag_audit_files_copies(@copies, @days)}
      ; 
    }
  end

  def get_headers(results)
    ['File Count']
  end

  def get_types(results)
    ['dataint']
  end

  def get_alternative_queries
    [
      {
        label: "Object List - File Copies Needed", 
        url: "path=file_copies_needed&days=#{@days}&limit=500"
      },
      {
        label: "#{@copies} copies of a file", 
        url: "path=con_files&copies=#{@copies}&days=0"
      },
      {
        label: "#{@copies} copies of a file, older than 1 day", 
        url: "path=con_files&copies=#{@copies}&days=1"
      },
      {
        label: "#{@copies} copies of a file, older than 2 days", 
        url: "path=con_files&copies=#{@copies}&days=2"
      },
    ]
  end

end
