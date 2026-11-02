# The name of this view in Looker is "Accounts"
view: accounts {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `google_analytics_4.accounts` ;;

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
    # This dimension will be called "Display Name" in Explore.

  dimension: display_name {
    type: string
    sql: ${TABLE}.display_name ;;
  }

  dimension: name {
    type: string
    sql: ${TABLE}.name ;;
  }

  dimension: region_code {
    type: string
    sql: ${TABLE}.region_code ;;
  }

  dimension_group: update {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.update_time ;;
  }
  measure: count {
    type: count
    drill_fields: [name, display_name]
  }
}
