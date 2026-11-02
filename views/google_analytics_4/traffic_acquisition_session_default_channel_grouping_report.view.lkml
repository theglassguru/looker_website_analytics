# The name of this view in Looker is "Traffic Acquisition Session Default Channel Grouping Report"
view: traffic_acquisition_session_default_channel_grouping_report {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `google_analytics_4.traffic_acquisition_session_default_channel_grouping_report` ;;

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

  dimension: engaged_sessions {
    type: number
    sql: ${TABLE}.engaged_sessions ;;
  }

  dimension: engagement_rate {
    type: number
    sql: ${TABLE}.engagement_rate ;;
  }

  dimension: event_count {
    type: number
    sql: ${TABLE}.event_count ;;
  }

  dimension: events_per_session {
    type: number
    sql: ${TABLE}.events_per_session ;;
  }

  dimension: key_events {
    type: number
    sql: ${TABLE}.key_events ;;
  }

  dimension: property {
    type: string
    sql: ${TABLE}.property ;;
  }

  dimension: session_default_channel_grouping {
    type: string
    sql: ${TABLE}.session_default_channel_grouping ;;
  }

  dimension: sessions {
    type: number
    sql: ${TABLE}.sessions ;;
  }

  dimension: total_revenue {
    type: number
    sql: ${TABLE}.total_revenue ;;
  }

  dimension: total_users {
    type: number
    sql: ${TABLE}.total_users ;;
  }

  dimension: user_engagement_duration {
    type: number
    sql: ${TABLE}.user_engagement_duration ;;
  }
  measure: count {
    type: count
  }
}
