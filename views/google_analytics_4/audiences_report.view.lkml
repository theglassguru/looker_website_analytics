# The name of this view in Looker is "Audiences Report"
view: audiences_report {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `google_analytics_4.audiences_report` ;;

  # No primary key is defined for this view. In order to join this view in an Explore,
  # define primary_key: yes on a dimension that has no repeated values.

    # Here's what a typical dimension looks like in LookML.
    # A dimension is a groupable field that can be used to filter query results.
    # This dimension will be called " Fivetran ID" in Explore.

  dimension: _fivetran_id {
    type: string
    sql: ${TABLE}._fivetran_id ;;
  }
  # Dates and timestamps can be represented in Looker using a dimension group of type: time.
  # Looker converts dates and timestamps to the specified timeframes within the dimension group.

  dimension_group: _fivetran_synced {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}._fivetran_synced ;;
  }

  dimension: active_users {
    type: number
    sql: ${TABLE}.active_users ;;
  }

  dimension: audience_name {
    type: string
    sql: ${TABLE}.audience_name ;;
  }

  dimension: average_session_duration {
    type: number
    sql: ${TABLE}.average_session_duration ;;
  }

  dimension_group: date {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.date ;;
  }

  dimension: new_users {
    type: number
    sql: ${TABLE}.new_users ;;
  }

  dimension: property {
    type: string
    sql: ${TABLE}.property ;;
  }

  dimension: screen_page_views_per_session {
    type: number
    sql: ${TABLE}.screen_page_views_per_session ;;
  }

  dimension: sessions {
    type: number
    sql: ${TABLE}.sessions ;;
  }

  dimension: total_revenue {
    type: number
    sql: ${TABLE}.total_revenue ;;
  }
  measure: count {
    type: count
    drill_fields: [audience_name]
  }
}
