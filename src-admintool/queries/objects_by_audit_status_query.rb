class ObjectsAuditStatusQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams, 'modified')
    @status = get_param('status', '')
    @status = '' if @status == 'verified'
  end

  def get_title
    "Objects by Audit Status: #{@status}"
  end

  def get_params
    [@status]
  end

  def get_where
    %{
      where exists (
        select 
          1 
        from 
          inv.inv_audits a 
        where 
          a.status = ?
        and
          a.inv_object_id = o.id
      )
    }
  end

end
