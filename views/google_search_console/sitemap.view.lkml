# The name of this view in Looker is "Sitemap"
view: sitemap {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `google_search_console.sitemap` ;;

  # No primary key is defined for this view. In order to join this view in an Explore,
  # define primary_key: yes on a dimension that has no repeated values.

  # Dates and timestamps can be represented in Looker using a dimension group of type: time.
  # Looker converts dates and timestamps to the specified timeframes within the dimension group.

  dimension_group: _fivetran_synced {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}._fivetran_synced ;;
  }
    # Here's what a typical dimension looks like in LookML.
    # A dimension is a groupable field that can be used to filter query results.
    # This dimension will be called "Errors" in Explore.

  dimension: errors {
    type: number
    sql: ${TABLE}.errors ;;
  }

  dimension: indexed {
    type: number
    sql: ${TABLE}.indexed ;;
  }

  dimension_group: last_downloaded {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.last_downloaded ;;
  }

  dimension_group: last_submitted {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.last_submitted ;;
  }

  dimension: path {
    type: string
    sql: ${TABLE}.path ;;
  }

  dimension: site {
    type: string
    sql: ${TABLE}.site ;;
  }

  dimension: submitted {
    type: number
    sql: ${TABLE}.submitted ;;
  }

  dimension: type {
    type: string
    sql: ${TABLE}.type ;;
  }

  dimension: warnings {
    type: number
    sql: ${TABLE}.warnings ;;
  }
  measure: count {
    type: count
  }
}
