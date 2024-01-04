# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ObjectsByBatchQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @batch = CGI.unescape(get_param('batch', ''))
  end

  def get_title
    "Objects By Ingest Batch: #{@batch}"
  end

  def get_params
    [@batch]
  end

  def get_where
    'where exists (
      select
        1
      from
        inv.inv_ingests i
      where
        i.inv_object_id = o.id
      and
        i.batch_id=?
    )'
  end
end
