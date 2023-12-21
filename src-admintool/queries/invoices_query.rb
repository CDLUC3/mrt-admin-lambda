# frozen_string_literal: true

class InvoicesQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    # Fiscal year to report on.  Starting with FY2019, there are significant changes to the rate and adjustments for charge backs.
    @fy = get_param('fy', DateTime.now.next_day(-182).year).to_i
    @fy = 2019 if @fy < 2019

    # FY Start Date
    @dstart = "#{@fy}-07-01"

    # FY end date
    @dend = "#{@fy + 1}-07-01"

    # As of allows you to test the pro-rating logic by using only a portion of data for a FY
    @as_of = get_param('as_of', @dend)
    @campus = get_param('campus', '')
    @campusfilt = "#{@campus}%"

    # Compute the last day in a FY (at or before the as_of date) for which records exist
    sql = %{
      select
        max(billing_totals_date)
      from
        daily_billing
      where
        billing_totals_date <= ?
      and
        billing_totals_date < ?
    }
    stmt = @client.prepare(sql)
    results = stmt.execute(@as_of, @dend)

    # YTD year to date date determined by the last available billing record
    results.each do |r|
      @dytd = r.values[0].to_s
    end

    # Determine if the fiscal year is in the past
    @fypast = (Time.new.strftime('%Y-%m-%d') >= @dend)

    # Compute the charge rate.  Before FY19: $650/TB.  After: $150/TB.
    # rate = (dend <= '2019-07-01') ? 0.000000000001780822 : 0.000000000000410959
    # Using our published rate: https://github.com/CDLUC3/mrt-doc/wiki/Policies-and-Procedures#pricing
    # @rate = (@dend <= '2019-07-01') ? 0.00000000000178 : 0.000000000000410959
    @rate = 0.000000000000410959

    # Format the annual rate to 2 digits of precision
    @annrate = (@rate * 1_000_000_000_000 * 365).to_i
  end

  def get_title
    "#{@campus} Invoice by Collection for FY#{@fy}"
  end

  def get_filter_col
    3
  end

  def show_grand_total
    false
  end

  def get_params
    [
      @dstart, @dend, @dytd, @rate, @campusfilt,
      @dstart, @dend, @dytd, @rate, @campusfilt,
      @dstart, @dend, @dytd, @rate, @campusfilt
    ]
  end

  def get_sql
    libown = %(
      'UCSF Library',
      'UCI Library',
      'UCSC Library',
      'UCLA Library',
      'UCR Library',
      'UCB Library',
      'UCSB Library',
      'UCM Library',
      'UCSD Library',
      'UCD Library'
    )

    sqlfrag = %{
      /*
        The following query fragment will be used 3 times to create 3 levels of groupings.
        Compute usage at the campus/owner/collection level.
        - All Merritt objects have a collection and an owner object.
        - Generally, all objects in a collection have the same owner.
        - Some system collections have objects with differing ownership.
        As of June 2020, 37 "owner" objects exist in Merritt.
        "Campus" or "ogroup" is a logical grouping of the 37 objects to the 10 UC campuses + CDL.
      */
      select
        /* Select the query parameters to make them accessible to other calculations*/
        ? as dstart,
        ? as dend,
        ? as dytd,
        ? as rate,
        ogroup                          /* campus */,
        own_name                        /* Merritt ownership object.*/,
        inv_owner_id,
        collection_name,
        (
          select
            ifnull(avg(billable_size), 0)
          from
            daily_billing db
          where
            c.inv_collection_id = db.inv_collection_id
          and
            c.inv_owner_id = db.inv_owner_id
          and
            billing_totals_date = dstart
        ) as start_size                  /* usage on FY start date */,
        (
          select
            ifnull(avg(billable_size), 0)
          from
            daily_billing db
          where
            c.inv_collection_id = db.inv_collection_id
          and
            c.inv_owner_id = db.inv_owner_id
          and
            billing_totals_date = dytd
        ) as ytd_size                    /* usage on YTD date */,
        (
          select
            ifnull(avg(billable_size), 0)
          from
            daily_billing db
          where
            c.inv_collection_id = db.inv_collection_id
          and
            c.inv_owner_id = db.inv_owner_id
          and
            billing_totals_date = date_add(dend, interval -1 day)
        ) as end_size                    /* usage on FY end date */,
        (
          select ytd_size - start_size
        ) as diff_size                   /* YTD collection growth */,
        (
          select
            count(billable_size)
          from
            daily_billing db
          where
            c.inv_collection_id = db.inv_collection_id
          and
            c.inv_owner_id = db.inv_owner_id
          and
            billing_totals_date >= dstart
          and
            billing_totals_date <= dytd
        ) as days_available               /* number of billing day records in database */,
        (
          select if(datediff(dend, dytd) = 0, 0, datediff(dend, dytd) - 1)
        ) as days_projected               /* number of days to "project" to the end of the FY*/,
        (
          select
            avg(billable_size)
          from
            daily_billing db
          where
            c.inv_collection_id = db.inv_collection_id
          and
            c.inv_owner_id = db.inv_owner_id
          and
            billing_totals_date >= dstart
          and
            billing_totals_date <= dytd
        ) as average_available            /* YTD average size */,
        (
          select
            ((average_available * days_available) + (ytd_size * days_projected)) / datediff(dend, dstart)
        ) as daily_average_projected      /* Projected average for the FY */
      from
        owner_collections c
      where
        ogroup like ?
      and
        collection_name not like '% Dash'
    }

    %{
      /*
        Select campus/owner/collection level.
      */
      select
        dstart,
        ogroup                          /* campus */,
        own_name                        /* Merritt ownership object.*/,
        collection_name,
        start_size                  /* usage on FY start date */,
        ytd_size                    /* usage on YTD date */,
        end_size                    /* usage on FY end date */,
        diff_size                   /* YTD collection growth */,
        days_available               /* number of billing day records in database */,
        days_projected               /* number of days to "project" to the end of the FY*/,
        average_available            /* YTD average size */,
        daily_average_projected      /* Projected average for the FY */,
        null as cost,
        null as cost_adj
      from
      (
        #{sqlfrag}
      ) collq

      union

      /*
        Aggregated usage at the CAMPUS level.
        - FY19 and beyond: invoices will be produced at a "campus" level.
          - Each campus library will receive 10TB of free storage.
      */
      select
        max(dstart) as dstart,
        ogroup,
        max('-- Total --') as own_name,
        max('-- Total --') as collection_name,
        sum(start_size) as start_size,
        sum(ytd_size) as ytd_size,
        sum(end_size) as end_size,
        sum(diff_size) as diff_size,
        null as days_available,
        max(days_projected) as days_projected,
        null as average_available,
        sum(daily_average_projected) as daily_average_projected,
        sum(daily_average_projected) * rate * 365 as cost,
        (
          select
            case
              when ogroup = 'CDL' then 0
              when ogroup = 'Other' then sum(daily_average_projected) * rate * 365
              when sum(daily_average_projected) < 10000000000000 then 0
              else (sum(daily_average_projected) - 10000000000000) * rate * 365
            end
        ) as cost_adj
      from
      (
        #{sqlfrag}
      ) collq
      group by
        ogroup

      union

      /*
        Aggregated usage at the Merritt owner object level.
          - Each campus will receive 10TB of free storage -- this replaces the notion of "exempt" content.
      */
      select
        max(dstart) as dstart,
        ogroup,
        own_name,
        max('-- Special Total --') as collection_name,
        sum(start_size) as start_size,
        sum(ytd_size) as ytd_size,
        sum(end_size) as end_size,
        sum(diff_size) as diff_size,
        null as days_available,
        max(days_projected) as days_projected,
        null as average_available,
        sum(daily_average_projected) as daily_average_projected,
        sum(daily_average_projected) * rate * 365 as cost,
        (
          select
            case
              when ogroup = 'CDL' then 0
              when ogroup = 'Other' then sum(daily_average_projected) * rate * 365
              when own_name in (#{libown}) and sum(daily_average_projected) < 10000000000000 then 0
              when own_name in (#{libown}) then (sum(daily_average_projected) - 10000000000000) * rate * 365
              else sum(daily_average_projected) * rate * 365
            end
        ) as cost_adj
      from
      (
        #{sqlfrag}
      ) collq
      group by
        ogroup,
        own_name
      order by
        ogroup,
        own_name,
        collection_name
    }
  end

  def get_headers(_results)
    [
      '',
      'Group -- Campus.  This is an grouping applied to Merritt Owner objects within the billing script',
      'Owner -- Merritt Owner Object.  37 currently exist.',
      'Collection -- Merritt Collection Name',

      'FY Start -- Billable bytes on the first day of the FY',
      'FY YTD -- Billable bytes on the most recent reported day from the FY - applies when report is run mid year',
      'FY End -- Billable bytes on the last day of the FY',

      'Diff -- Bytes added since the start of the FY',
      'Days -- Days within the FY for which billable bytes were found for a collection',
      'Days Projected -- Number of days to the end of the FY.  The FY YTD amount will be presumed until the end of the FY',
      'Avg -- Average bytes found for the days in which content was found',

      'Daily Avg (Projected) (over whole year) -- Average bytes projected to the end of the year AND prorated for collections that were begun over the course of the FY',
      'Cost -- $150/TB.',
      'Adjusted Cost -- 10TB of complimentary storage are available to each campus library (remainder will apply to the campus)'
    ]
  end

  def get_types(_results)
    [
      'na',
      '', 'name', 'name',

      'bytes', # fy start
      @fypast ? 'na' : 'bytes', # ytd
      @fypast ? 'bytes' : 'na', # fy end

      'bytes', # difference
      'dataint', # days
      @fypast ? 'na' : 'dataint', # days projected
      'bytes', # average - particularly useful for partial year collections

      'bytes', # projected average
      'money', # adj cost
      'money' # adj cost
    ]
  end

  def bytes_unit
    '1000000000000'
  end

  def campus_params(campus)
    params = @myparams.clone
    params['campus'] = campus
    params
  end

  def get_alternative_queries
    queries = []
    campuses = @campus.empty? ? %w[UCB UCD UCI UCLA UCM UCR UCSB UCSC UCSD UCSF] : ['']
    campuses.each do |campus|
      queries.append({
        label: campus.empty? ? 'All Campuses' : campus,
        url: params_to_str(campus_params(campus)),
        class: 'campus'
      })
    end
    queries
  end
end
