# The name of this view in Looker is "Custom Dimensions"
view: custom_dimensions {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `google_analytics_4.custom_dimensions` ;;

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
    # This dimension will be called "Description" in Explore.

  dimension: description {
    type: string
    sql: ${TABLE}.description ;;
  }

  dimension: disallow_ads_personalization {
    type: yesno
    sql: ${TABLE}.disallow_ads_personalization ;;
  }

  dimension: display_name {
    type: string
    sql: ${TABLE}.display_name ;;
  }

  dimension: name {
    type: string
    sql: ${TABLE}.name ;;
  }

  dimension: parameter_name {
    type: string
    sql: ${TABLE}.parameter_name ;;
  }

  dimension: scope {
    type: string
    sql: ${TABLE}.scope ;;
  }
  measure: count {
    type: count
    drill_fields: [name, parameter_name, display_name]
  }
}
