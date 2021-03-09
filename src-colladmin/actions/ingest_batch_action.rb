require_relative 'action'
require_relative 'forward_to_ingest_action'

class IngestBatchAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @batch = myparams.fetch('batch', '')
    super(config, path, myparams, "admin/bid/#{@batch}")
  end

  def get_title
    "Ingest Batch Detail"
  end

  def table_headers
    [
      'Key',
      'Job',
      'Data'
    ]
  end

  def table_types
    [
      '',
      'qjob',
      ''
    ]
  end

  def table_rows(body)
    data = JSON.parse(body)
    rows = []
    data = data.fetch('fil:batchFileState', {})
    bm  = data.fetch("fil:batchManifest", {})
    bmdata = bm.fetch("fil:manifest", "")
    
    rows.append(["Batch Manifest", "", bmdata]) unless bmdata.empty?
    
    bmdata = bm.fetch("fil:content", "")

    if !bmdata.empty? 
      arr = bmdata.split("&#10;")
      arr.each do |r|
        next if r[0] == '#'
        carr = r.split("|")
        rows.append(["Manifest File", "", carr[5]])
      end  
    end
    
    jf  = data.fetch("fil:jobFile", {})
    jbf = jf.fetch("fil:batchFile", [])
    jbf = [jbf] unless jbf.instance_of?(Array)

    jbf.each do |jfobj|
      jff = jfobj.fetch("fil:file", "")
      puts(jff)

      rows.append(["Job", "#{@batch}/#{jff}", ""])
    end
    rows
  end

  def hasTable
    true
  end

end
