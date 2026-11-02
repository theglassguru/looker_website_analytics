# The name of this view in Looker is "Conversion Events"
view: conversion_events {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `google_analytics_4.conversion_events` ;;

  # No primary key is defined for this view. In order to join this view in an Explore,
  # define primary_key: yes on a dimension that has no repeated values.

  # Dates and timestamps can be represented in Looker using a dimension group of type: time.
  # Looker converts dates and timestamps to the specified timeframes within the dimension group.

  dimension_group: _fivetran_synced {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}._fivetran_synced ;;
  }

  dimension_group: create {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.create_time ;;
  }
    # Here's what a typical dimension looks like in LookML.
    # A dimension is a groupable field that can be used to filter query results.
    # This dimension will be called "Custom" in Explore.

  dimension: custom {
    type: yesno
    sql: ${TABLE}.custom ;;
  }

  dimension: deletable {
    type: yesno
    sql: ${TABLE}.deletable ;;
  }

  dimension: event_name {
    type: string
    sql: ${TABLE}.event_name ;;
  }

  dimension: name {
    type: string
    sql: ${TABLE}.name ;;
  }
  measure: count {
    type: count
    drill_fields: [name, event_name]
  }
}
