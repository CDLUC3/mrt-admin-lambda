# frozen_string_literal: true

# Query class - see config/reports.yml for description
class AuditNewUCBQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super
    @days = get_param('days', 7).to_i
    @wait_hours = get_param('wait_hours', 24).to_i
  end

  def get_title
    "Audit Status for UCB Objects Modified in the Last #{@days} Days; #{@wait_hours} wait_hours"
  end

  def get_sql
    %{
      select distinct
        o.id,
        o.ark,
        o.modified,
        count(a.id) as files_count,
        max(a.verified) as verified,
        a.status as audit_status,
        case
          when a.status in ('size-mismatch','digest-mismatch', 'unverified') then 'Audit Failed'
          when ifnull(verified, o.modified) < date_add(o.modified, interval #{@wait_hours} hour) and o.modified > date_add(now(), interval -#{@wait_hours} hour) then 'Reset Later'
          when a.status = 'verified' and ifnull(verified, o.modified) < date_add(o.modified, interval #{@wait_hours} hour) then 'Reset Needed'
          when a.status = 'verified' then 'Audited'
          else 'In Progress'
        end as category,
        case
          when a.status in ('size-mismatch','digest-mismatch', 'unverified') then 'FAIL'
          when ifnull(verified, o.modified) < date_add(o.modified, interval #{@wait_hours} hour) and o.modified > date_add(now(), interval -#{@wait_hours} hour) then 'INFO'
          when a.status = 'verified' and ifnull(verified, o.modified) < date_add(o.modified, interval #{@wait_hours} hour) then 'WARN'
          when a.status = 'verified' then 'PASS'
          else 'INFO'
        end as status
      from 
        inv.inv_objects o
      right join
        inv.inv_audits a 
      on 
        a.inv_object_id = o.id 
      and 
        a.inv_node_id = 16 /*sdsc node*/
      where 
        o.inv_owner_id=14 /*ucb owner*/
      and 
        o.modified > date_add(now(), interval -#{@days.to_i} day)
      group by
        o.id,
        o.ark,
        o.modified,
        a.status
      order by
        o.modified desc
      ;
    }
  end

  def get_headers(_results)
    ['Object Id', 'Ark', 'Obj Modified', 'Files', 'Verified', 'Audit Status', 'Category', 'Status']
  end

  def get_types(_results)
    %w[objlist ark datetime dataint datetime '' '' status]
  end

  def get_alternative_queries
    [
      {
        label: 'Last 7 days',
        url: 'path=audit_ucb&days=7',
        class: 'graph'
      },
      {
        label: 'Last 14 days',
        url: 'path=audit_ucb&days=14',
        class: 'graph'
      },
      {
        label: 'Last 30 days',
        url: 'path=audit_ucb&days=30',
        class: 'graph'
      }
    ]
  end

  def init_status
    :PASS
  end
end
