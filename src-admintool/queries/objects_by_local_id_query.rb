# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ObjectsByLocalIdQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @localid = CGI.unescape(get_param('localid', ''))
  end

  def get_title
    "Objects By Local Id Query: #{@localid}"
  end

  def get_params
    [@localid]
  end

  def get_where
    %{
    where o.ark = (
      select
        inv_object_ark
      from
        inv.inv_localids li
      where
        li.local_id = ?
    )
  }
  end
end
