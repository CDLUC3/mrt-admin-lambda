# frozen_string_literal: true

# Query class - see config/reports.yml for description
class IdlistCompareQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @fields = myparams.fetch('fields', '')
  end

  def get_title
    "Id List Compare Query for #{get_params.length} ids"
  end

  def get_placeholders
    buf = []
    get_params.each do |_ark|
      buf.append('?')
    end
    buf.join(',')
  end

  def get_params
    @myparams['idlist'].split(',')
  end

  def get_where
    %{
      where ... in (
    } + get_placeholders +
      %{
        )
      }
  end

  def get_sql
    %{
select
  trim(substring_index(o.erc_where, ';', -1)) as compareid,
  v.number,
  f.pathname,
  f.digest_value,
  o.ark,
  o.created
from
  inv.inv_objects o
left join inv.inv_versions v
  on o.id = v.inv_object_id
left join inv.inv_files f
  on o.id = f.inv_object_id
  and v.id = f.inv_version_id
} + get_where +
      %(
      order by
        compareid,
        number,
        pathname,
        created
      ;
        )
  end

  def run_query_sql
    stmt = @client.prepare(get_sql)
    params = get_params

    results = stmt.execute(*params)
    types = get_types(results)
    data = get_result_data(results, types)

    localmap = {}
    pathmap = {}

    data.each do |r|
      localid = r[0]
      r[1]
      r[2]
      r[3]
      ark = r[4]
      created = r[5].to_s

      localmap[localid] = {} unless localmap.key?(localid)
      localmap[localid][created] = { ark: ark }
    end

    localmap.each_value do |lrec|
      i = 0
      lrec.keys.sort.each do |k|
        lrec[k][:pos] = i
        i += 1
      end
    end

    data.each do |r|
      localid = r[0]
      ver = r[1]
      fpath = r[2]
      dig = r[3]
      ark = r[4]
      created = r[5].to_s

      index = localmap[localid][created][:pos]

      path = "#{localid}/#{ver}/#{fpath}"
      pathmap[path] = { localid: localid, ver: ver, fpath: fpath, arks: [], digs: [] } unless pathmap.key?(path)
      pathmap[path][:arks][index] = ark
      pathmap[path][:digs][index] = dig
    end

    outdata = []

    pathmap.keys.sort.each do |path|
      rec = pathmap[path]
      cmpstatus = ''
      status = 'PASS'
      if rec[:arks].length > 2
        cmpstatus = 'More than 2'
        status = 'WARN'
      elsif rec[:arks][0].nil?
        cmpstatus = 'Right Only'
        if rec[:fpath] == 'producer/mrt-provenance.xml' ||
          rec[:fpath] == 'system/mrt-submission-manifest.txt' ||
          rec[:fpath] == 'system/mrt-delete.txt'
          status = 'WARN'
        else
          status =  'FAIL'
        end
      elsif rec[:arks][1].nil?
        cmpstatus = 'Left Only'
        if rec[:fpath] == 'system/mrt-delete.txt'
          status = 'WARN'
        else
          status = 'FAIL'
        end
      elsif rec[:digs][0] == rec[:digs][1]
        cmpstatus = 'Match'
      else
        cmpstatus = 'Mismatch'
        if rec[:fpath] == 'system/mrt-erc.txt' ||
          rec[:fpath] == 'system/mrt-ingest.txt' ||
          rec[:fpath] == 'system/mrt-membership.txt' ||
          rec[:fpath] == 'system/mrt-mom.txt' ||
          rec[:fpath] == 'system/mrt-object-map.ttl' ||
          rec[:fpath] == 'system/mrt-dc.xml' ||
          rec[:fpath] == 'system/mrt-owner.txt' ||
          rec[:fpath] == 'system/mrt-delete.txt'
          status = 'WARN'
        else
          status = 'FAIL'
        end
      end
      outdata.append(
        [
          rec[:localid],
          rec[:ver],
          rec[:fpath],
          cmpstatus,
          rec[:arks][0],
          rec[:arks][1],
          status
        ]
      )
    end

    format_result_json(types, outdata, get_headers(results))
  end

  def get_headers(_results)
    [
      'Local Id',
      'Version',
      'Path',
      'Compare Status',
      'Ark Left',
      'Ark Right',
      'Status'
    ]
  end

  def get_types(_results)
    [
      '',
      '',
      'name',
      '',
      '',
      '',
      'status'
    ]
  end

  def init_status
    :PASS
  end
end
