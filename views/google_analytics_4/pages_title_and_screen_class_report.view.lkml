# The name of this view in Looker is "Pages Title and Screen Class Report"
view: pages_title_and_screen_class_report {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `google_analytics_4.pages_title_and_screen_class_report` ;;

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

  dimension_group: date {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.date ;;
  }

  dimension: event_count {
    type: number
    sql: ${TABLE}.event_count ;;
  }

  dimension: key_events {
    type: number
    sql: ${TABLE}.key_events ;;
  }

  dimension: new_users {
    type: number
    sql: ${TABLE}.new_users ;;
  }

  dimension: property {
    type: string
    sql: ${TABLE}.property ;;
  }

  dimension: screen_page_views {
    type: number
    sql: ${TABLE}.screen_page_views ;;
  }

  dimension: total_revenue {
    type: number
    sql: ${TABLE}.total_revenue ;;
  }

  dimension: total_users {
    type: number
    sql: ${TABLE}.total_users ;;
  }

  dimension: unified_screen_class {
    type: string
    sql: ${TABLE}.unified_screen_class ;;
  }

  dimension: user_engagement_duration {
    type: number
    sql: ${TABLE}.user_engagement_duration ;;
  }
  measure: count {
    type: count
  }
}
