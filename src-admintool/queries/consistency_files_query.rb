class ConsistencyFilesQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @copies = CGI.unescape(get_param('copies', '2')).to_i
  end

  def report_name
    "#{@path}.#{@copies}copies"
  end

  def get_title
    "Files with only #{@copies} copies"
  end

  def get_sql
    %{
      select 
        case
          when c.mnemonic like 'cdl_dryad%'
            then 'Dryad'
          when c.mnemonic = 'oneshare_dataup'
            then 'DataOne'
          when c.mnemonic = 'dataone_dash'
            then 'DataOne'
          when ifnull(c.mnemonic, '') = ''
            then 'No Mnemonic'
          when age.inv_object_id = (
            select id from inv.inv_objects where ark = 'ark:/13030/m5q57br8'
          )
            then 'Wasabi Issue 477'
          when age.inv_object_id = (
            select id from inv.inv_objects where ark = 'ark:/13030/m5v45qp2'
          )
            then 'UCD Curatorial'
          else
            'Default'
        end as category,
        count(*),
        ifnull(
          sum(
            case
              when age.init_created < date_add(now(), INTERVAL -2 DAY)
                then 1
              else 0
            end
          ),
          0
        ),
        ifnull(
          sum(
            case
              when age.init_created < date_add(now(), INTERVAL -2 DAY)
                then 0
              when age.init_created < date_add(now(), INTERVAL -1 DAY) 
                then 1
              else 0
            end
          ),
          0
        ),
        ifnull(
          sum(
            case
              when age.init_created < date_add(now(), INTERVAL -2 DAY)
                then 0
              when age.init_created < date_add(now(), INTERVAL -1 DAY) 
                then 0
              else 1
            end
          ),
          0
        ),   
        case
          when count(*) = 0 then 'PASS'
          when #{@copies} = 3 then 'PASS'
          when ifnull(
            sum(
              case
                when age.init_created < date_add(now(), INTERVAL -2 DAY)
                  then 1
                else 0
              end
            ),
            0
          ) > 0 then 
            case
              when age.inv_object_id = (
                select id from inv.inv_objects where ark = 'ark:/13030/m5v45qp2'
              ) then 'WARN'
              when #{@copies} != 2 then 'FAIL'
              when c.mnemonic = 'oneshare_dataup' then 'WARN'
              when c.mnemonic = 'dataone_dash' then 'WARN'
              when ifnull(c.mnemonic, '') = '' then 'WARN'
              when age.inv_object_id = (
                select id from inv.inv_objects where ark = 'ark:/13030/m5q57br8'
              ) then 'WARN'
              else 'FAIL'
            end
          when ifnull(
            sum(
              case
                when age.init_created < date_add(now(), INTERVAL -2 DAY)
                  then 0
                when age.init_created < date_add(now(), INTERVAL -1 DAY) 
                  then 1
                else 0
              end
            ),
            0
          ) > 0 then 'WARN'
          else 'PASS'
        end as status
      #{sqlfrag_audit_files_copies(@copies)}
      inner join inv.inv_collections_inv_objects icio
        on age.inv_object_id = icio.inv_object_id
      inner join inv.inv_collections c
        on icio.inv_collection_id = c.id
      inner join inv.inv_objects o
        on c.inv_object_id = o.id and o.aggregate_role = 'MRT-collection'
      group by 
        category
      ; 
    }
  end

  def get_headers(results)
    ['Category', 'File Count', '> 2 days', '1-2 days', '< 1 day', 'Status']
  end

  def get_types(results)
    ['', 'dataint', 'dataint', 'dataint', 'dataint', 'status']
  end

  def init_status
    :PASS
  end

  def get_alternative_queries
    [
      {
        label: "Object List - File Copies Needed, Older than 2 days", 
        url: "path=file_copies_needed&copies=#{@copies}&days=2&limit=500"
      }
    ]
  end

end
