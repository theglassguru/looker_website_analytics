# The name of this view in Looker is "Properties"
view: properties {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `google_analytics_4.properties` ;;

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
    # This dimension will be called "Account" in Explore.

  dimension: account {
    type: string
    sql: ${TABLE}.account ;;
  }

  dimension_group: create {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.create_time ;;
  }

  dimension: currency_code {
    type: string
    sql: ${TABLE}.currency_code ;;
  }

  dimension_group: delete {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.delete_time ;;
  }

  dimension: display_name {
    type: string
    sql: ${TABLE}.display_name ;;
  }

  dimension_group: expire {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.expire_time ;;
  }

  dimension: industry_category {
    type: string
    sql: ${TABLE}.industry_category ;;
  }

  dimension: name {
    type: string
    sql: ${TABLE}.name ;;
  }

  dimension: parent {
    type: string
    sql: ${TABLE}.parent ;;
  }

  dimension: property_type {
    type: string
    sql: ${TABLE}.property_type ;;
  }

  dimension: service_level {
    type: string
    sql: ${TABLE}.service_level ;;
  }

  dimension: time_zone {
    type: string
    sql: ${TABLE}.time_zone ;;
  }

  dimension_group: update {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.update_time ;;
  }
  measure: count {
    type: count
    drill_fields: [display_name, name]
  }
}
