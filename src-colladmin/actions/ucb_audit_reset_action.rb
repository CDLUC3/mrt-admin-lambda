# frozen_string_literal: true

require_relative 'action'

# Collection Admin Task class - see config/actions.yml for description
class UCBAuditResetAction < AdminAction
  def get_title
    "UCB Audit Reset"
  end

  def table_headers
    %w[ObjectID Ark Modified Status]
  end

  def table_types
    %w[objidlist ark datetime status]
  end

  def table_rows(_body)
    sql = %{
      select distinct
        o.id, o.ark, o.modified, 'PASS' as status
      from 
        inv.inv_objects o
      inner join
        inv.inv_audits a 
      on 
        a.inv_object_id = o.id 
      and 
        a.inv_node_id = 16 /*sdsc node*/
      where 
        o.inv_owner_id=14 /*ucb owner*/
      and 
        o.modified > date_add(now(), interval -7 day)
      and
        ifnull(verified, o.modified) < date_add(o.modified, interval 1 day)
      and 
        o.modified < date_add(now(), interval -1 day)
      and 
        a.status = 'verified'
      order by o.modified
      limit 2
      ;
    }
    data = MerrittQuery.new(@config).run_query(sql)
    data.each do |r|
      objid = r[0]
      MerrittQuery.new(@config).run_update(
        %(
          update
            inv_audits
          set
            verified = null,
            status = 'unknown'
          where
            inv_object_id = ?
          and
            inv_node_id = ?
        ),
        [objid, 16],
        'Audit reset for object'
      )
    end
    data
  end

  def perform_action
    convert_json_to_table({}.to_json)
  end

  def has_table
    true
  end

  def init_status
    :PASS
  end

end
