# frozen_string_literal: true

require_relative 'action'

# Collection Admin Task class - see config/actions.yml for description
class UCBAuditResetAction < AdminAction
  def initialize(config, action, path, myparams)
    @days = myparams.fetch('days', '7').to_i
    @wait_hours = myparams.fetch('wait_hours', '24').to_i
    @limit = myparams.fetch('limit', '50').to_i
    super(config, action, path, myparams)
  end

  def get_title
    "UCB Audit Reset: Last #{@days} days. Wait #{@wait_hours} wait_hours. Limit #{@limit}."
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
        o.modified > date_add(now(), interval -#{@days} day)
      and
        ifnull(verified, o.modified) < date_add(o.modified, interval #{@wait_hours} hour)
      and 
        o.modified < date_add(now(), interval -#{@wait_hours} hour)
      and 
        a.status = 'verified'
      order by o.modified
      limit #{@limit}
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
