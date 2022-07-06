class ConsistencyObjectsQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @copies = get_param('copies', '2').to_i
  end

  def report_name
    "#{@path}.#{@copies}copies"
  end

  def get_title
    "Objects with only #{@copies} copies"
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
            select -1 /*id from inv.inv_objects where ark = '...'*/
          ) 
            then '...'
          when c.name = 'Merritt curatorial classes'
            then 'Stage Exception'
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
          when #{@copies.to_i} = 3 then 'PASS'
          when #{@copies.to_i} = 4 and c.mnemonic = 'cdl_dryad' then 'INFO'
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
              when c.mnemonic = 'oneshare_dataup' then 'INFO'
              when c.mnemonic = 'dataone_dash' then 'INFO'
              when ifnull(c.mnemonic, '') = '' then 'INFO'
              when #{@copies.to_i} != 2 then 'FAIL'
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
            #{sqlfrag_object_copies(@copies)}
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
    ['Category', 'Object Count', '> 2 days', '1-2 days', '< 1 day', 'Status']
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
        label: "Object List - #{@copies} copies of an object, Older than 2 days", 
        url: "path=object_copies_needed&copies=#{@copies}&days=2&limit=500"
      }
    ]
  end

end
