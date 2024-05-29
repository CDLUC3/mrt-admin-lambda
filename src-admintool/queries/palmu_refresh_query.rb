# frozen_string_literal: true

# Query class - see config/reports.yml for description - deprecated code
class PalmuRefreshQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super

    @files = {}
    @matched = 0
    @not_loaded = 0
    @not_in_inventory = 0
    @ignored = 0

    inventory = get_data_report('merritt-reports/palmu/inventory.txt')

    stmt = @client.prepare(files_sql)
    results = stmt.execute

    report = generate_report(inventory, results)

    save_data_report('merritt-reports/palmu/match.json', report)
  end

  def generate_report(inventory, results)
    rcount = 0
    results.each do |r|
      line = r.values[0]
      next if line.nil?

      rcount += 1
      tt = line
      tt = line.strip.split(%r{/})[-1] unless line =~ /conservation/
      @files[tt] = @files.fetch(tt, { key: tt })
      @files[tt][:loaded] = true
    end

    invcount = 0
    inventory.each_line do |line|
      next if line =~ %r{mods/}
      next unless line =~ %r{/}
      next if line =~ %r{/$}

      t = line.strip.split(%r{/})
      next if t[-1] =~ /^\._/

      invcount += 1
      tt = t.length > 3 ? t[2, t.length].join('/') : t[-1]
      tt = t[-1] unless tt =~ /conservation/
      @files[tt] = @files.fetch(tt, { key: tt })
      @files[tt][:inventory] = true
    end

    @data = []

    @files.keys.sort.each do |k|
      v = @files[k]
      m = k.match(%r{(^|/)(\d\d\d\d)\.\d\d\.})
      v[:ext] = 'Other'
      v[:ext] = 'Tiff' if k.downcase.match(/\.tiff?$/)
      v[:ext] = 'Jpeg' if k.downcase.match(/\.jpe?g$/)
      v[:ext] = 'PDF' if k.downcase.match(/\.pdf$/)
      if m
        v[:prefixg] = m[2]
        if v[:inventory] && v[:loaded]
          v[:status] = 'Matched'
          @matched += 1
        elsif v[:inventory]
          v[:status] = 'Not Loaded'
          @not_loaded += 1
        elsif v[:loaded]
          v[:status] = 'Not in inventory'
          @not_in_inventory += 1
        end
      else
        v[:prefixg] = 'Other'
        v[:status] = 'Ignored'
        @ignored += 1
      end
      v.delete(:inventory)
      v.delete(:loaded)
      @files[k] = v
      @data.push(v)
    end

    "const DATA = #{@data.to_json};"
  end

  def get_title
    'Pal Museum Inventory Refresh'
  end

  def run_query_sql
    get_result_json(nil)
  end

  def get_result_data(_results, _types)
    [
      [
        'Matched',
        @matched,
        @files.empty? ? -1 : 100 * @matched / @files.length
      ],
      [
        'Not Loaded',
        @not_loaded,
        @files.empty? ? -1 : 100 * @not_loaded / @files.length
      ],
      [
        'In Merritt, Not in Inventory',
        @not_in_inventory,
        @files.empty? ? -1 : 100 * @not_in_inventory / @files.length
      ],
      [
        'Ignored',
        @ignored,
        @files.empty? ? -1 : 100 * @ignored / @files.length
      ]
    ]
  end

  def files_sql
    %{
      select
        distinct substr(f.pathname, 10) as fname
      from
        inv.inv_collections c
      inner join inv.inv_collections_inv_objects icio
        on c.id = icio.inv_collection_id
      inner join inv.inv_objects o
        on o.id = icio.inv_object_id
      inner join inv.inv_files f
        on f.inv_object_id = o.id and source = 'producer'
      where
        c.mnemonic = 'ucla_pal_museum'
      order by fname;
    }
  end

  def get_headers(_results)
    %w[Status Count Percent]
  end

  def get_types(_results)
    ['', 'dataint', 'dataint']
  end

  def get_alternative_queries
    [
      {
        label: 'View Report',
        url: '/merritt-reports/palmu/index.html',
        class: 'batches'
      }
    ]
  end
end
