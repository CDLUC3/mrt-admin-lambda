# frozen_string_literal: true

class UpdateBillingDatabaseQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    stmt = @client.prepare('call update_object_size()')
    stmt.execute
    stmt = @client.prepare('call update_node_counts()')
    stmt.execute
    return unless myparams.fetch('all-tables', '') == 'Y'

    stmt = @client.prepare('call update_billing_range()')
    stmt.execute
    stmt = @client.prepare('call update_audits_processed()')
    stmt.execute
    stmt = @client.prepare('call update_ingests_processed()')
    stmt.execute
  end

  def get_title
    'Update Billing Database Tables'
  end

  def get_sql
    %{
      select
        'Object Count', (select count(*) from object_size) as data
      union
      select
        'File Count - All nodes', (select sum(file_count) from node_counts) as data
      union
      select
        'Billable Size - All nodes', (select sum(billable_size) from node_counts) as data
      union
      select
        'Files added yesterday', (select sum(count_files) from daily_mime_use_details where date_added = date(date_add(now(), INTERVAL -1 DAY))) as data
      union
      select
        'Bytes added yesterday', (select sum(billable_size) from daily_mime_use_details where date_added = date(date_add(now(), INTERVAL -1 DAY))) as data
      union
      select
        'Online Files audited yesterday', (select sum(online_files) from audits_processed where audit_date = date(date_add(now(), INTERVAL -1 DAY))) as data
      union
      select
        'Online Bytes audited yesterday', (select sum(online_bytes) from audits_processed where audit_date = date(date_add(now(), INTERVAL -1 DAY))) as data
      union
      select
        'Objects ingested yesterday', (select sum(object_count) from ingests_completed where ingest_date = date(date_add(now(), INTERVAL -1 DAY))) as data
      ;
    }
  end

  def get_headers(_results)
    %w[Category Count]
  end

  def get_types(_results)
    ['', 'dataint']
  end
end
