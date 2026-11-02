# The name of this view in Looker is "Google Ads Links"
view: google_ads_links {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `google_analytics_4.google_ads_links` ;;

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
    # This dimension will be called "Ads Personalization Enabled" in Explore.

  dimension: ads_personalization_enabled {
    type: yesno
    sql: ${TABLE}.ads_personalization_enabled ;;
  }

  dimension: can_manage_clients {
    type: yesno
    sql: ${TABLE}.can_manage_clients ;;
  }

  dimension_group: create {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.create_time ;;
  }

  dimension: creator_email_address {
    type: string
    sql: ${TABLE}.creator_email_address ;;
  }

  dimension: customer_id {
    type: string
    sql: ${TABLE}.customer_id ;;
  }

  dimension: name {
    type: string
    sql: ${TABLE}.name ;;
  }

  dimension_group: update {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.update_time ;;
  }
  measure: count {
    type: count
    drill_fields: [name]
  }
}
