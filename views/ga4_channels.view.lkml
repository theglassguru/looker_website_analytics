view: ga4_channels {
  label: "GA4 - Channels"

  # -------------------------------------------------
  #                 DERIVED TABLE (BQ)
  # -------------------------------------------------
  #
  # Site traffic by default channel grouping.
  # Source: google_analytics_4.traffic_acquisition_session_default_channel_grouping_report
  # Property: All Locations (properties/384050813), the full-site
  # property. Location properties are NOT used (9 mirror the whole site,
  # the rest carry only WhatConverts events).
  # Grain: date x channel. Dates are in the property time zone
  # (America/Denver).
  #
  # Do not join to other GA4 report views: each report is a separate
  # cut of the same totals.
  #
  # As of yesterday: today is excluded (partial day).

  derived_table: {
    sql:
      SELECT
        property,
        date,
        _fivetran_id,
        session_default_channel_grouping AS channel,
        sessions,
        engaged_sessions,
        user_engagement_duration
      FROM `fivetran-the-glass-guru-wareho.google_analytics_4.traffic_acquisition_session_default_channel_grouping_report`
      WHERE property = 'properties/384050813'
        AND date < CURRENT_DATE('America/Chicago')
    ;;
  }

  # -------------------------------------------------
  #                   PRIMARY KEY
  # -------------------------------------------------

  dimension: pk {
    primary_key: yes
    hidden: yes
    description: "property | date | _fivetran_id. Verified unique 2026-11-02."
    type: string
    sql: CONCAT(${TABLE}.property, '|', CAST(${TABLE}.date AS STRING), '|', ${TABLE}._fivetran_id) ;;
  }

  # -------------------------------------------------
  #                     DATES
  # -------------------------------------------------

  dimension_group: date {
    label: "Visit"
    group_label: "📅 | Visit Date"
    description: "GA4 reporting date (property time zone, America/Denver). Date only."
    type: time
    datatype: date
    convert_tz: no
    timeframes: [raw, date, week, month, month_name, quarter, year]
    sql: ${TABLE}.date ;;
  }

  # -------------------------------------------------
  #                   DIMENSIONS
  # -------------------------------------------------

  dimension: channel {
    label: "Channel"
    description: "GA4 default channel grouping (Organic Search, Paid Search, Direct, Email, etc.)."
    type: string
    sql: ${TABLE}.channel ;;
  }

  # -------------------------------------------------
  #                ALL-TIME MEASURES
  # -------------------------------------------------

  measure: sessions {
    label: "Sessions #"
    group_label: "⏳ | Traffic"
    description: "Visits to the site."
    type: sum
    sql: ${TABLE}.sessions ;;
    value_format_name: decimal_0
  }

  measure: engaged_sessions {
    label: "Engaged Sessions #"
    group_label: "⏳ | Traffic"
    description: "Visits lasting 10+ seconds, with 2+ page views, or with a key event (GA4 definition)."
    type: sum
    sql: ${TABLE}.engaged_sessions ;;
    value_format_name: decimal_0
  }

  measure: engagement_rate {
    label: "Engagement Rate %"
    group_label: "⏳ | Traffic"
    description: "Engaged Sessions / Sessions."
    type: number
    sql: ${engaged_sessions} / NULLIF(${sessions}, 0) ;;
    value_format_name: percent_1
  }

  measure: engagement_seconds {
    hidden: yes
    description: "Helper: total user engagement time in seconds."
    type: sum
    sql: ${TABLE}.user_engagement_duration ;;
  }

  measure: avg_engagement_time_per_session {
    label: "Avg Engagement Time / Session (sec)"
    group_label: "⏳ | Traffic"
    description: "Total engagement time / Sessions, in seconds."
    type: number
    sql: ${engagement_seconds} / NULLIF(${sessions}, 0) ;;
    value_format_name: decimal_0
  }

  # -------------------------------------------------
  #            DYNAMIC MEASURES (CP / PP)
  # -------------------------------------------------

  measure: sessions_cp {
    label: "Sessions # (CP)"
    group_label: "⚡ | Traffic"
    description: "Sessions in the current period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.sessions END ;;
    value_format_name: decimal_0
  }

  measure: sessions_pp {
    label: "Sessions # (PP)"
    group_label: "⚡ | Traffic"
    description: "Sessions in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.sessions END ;;
    value_format_name: decimal_0
  }

  measure: sessions_cp_vs_pp_var {
    label: "Sessions Δ"
    group_label: "⚡ | Traffic"
    description: "Sessions CP - PP."
    type: number
    sql: COALESCE(${sessions_cp}, 0) - COALESCE(${sessions_pp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: sessions_cp_vs_pp_var_percent {
    label: "Sessions Δ%"
    group_label: "⚡ | Traffic"
    description: "Sessions (CP - PP) / PP."
    type: number
    sql: (COALESCE(${sessions_cp}, 0) - COALESCE(${sessions_pp}, 0)) / NULLIF(${sessions_pp}, 0) ;;
    value_format_name: percent_1
  }

  measure: engaged_sessions_cp {
    label: "Engaged Sessions # (CP)"
    group_label: "⚡ | Traffic"
    description: "Engaged sessions in the current period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.engaged_sessions END ;;
    value_format_name: decimal_0
  }

  measure: engaged_sessions_pp {
    label: "Engaged Sessions # (PP)"
    group_label: "⚡ | Traffic"
    description: "Engaged sessions in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.engaged_sessions END ;;
    value_format_name: decimal_0
  }

  measure: engaged_sessions_cp_vs_pp_var {
    label: "Engaged Sessions Δ"
    group_label: "⚡ | Traffic"
    description: "Engaged sessions CP - PP."
    type: number
    sql: COALESCE(${engaged_sessions_cp}, 0) - COALESCE(${engaged_sessions_pp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: engaged_sessions_cp_vs_pp_var_percent {
    label: "Engaged Sessions Δ%"
    group_label: "⚡ | Traffic"
    description: "Engaged sessions (CP - PP) / PP."
    type: number
    sql: (COALESCE(${engaged_sessions_cp}, 0) - COALESCE(${engaged_sessions_pp}, 0)) / NULLIF(${engaged_sessions_pp}, 0) ;;
    value_format_name: percent_1
  }

  measure: engagement_rate_cp {
    label: "Engagement Rate % (CP)"
    group_label: "⚡ | Traffic"
    description: "Engaged Sessions / Sessions in the current period."
    type: number
    sql: ${engaged_sessions_cp} / NULLIF(${sessions_cp}, 0) ;;
    value_format_name: percent_1
  }

  measure: engagement_rate_pp {
    label: "Engagement Rate % (PP)"
    group_label: "⚡ | Traffic"
    description: "Engaged Sessions / Sessions in the prior period."
    type: number
    sql: ${engaged_sessions_pp} / NULLIF(${sessions_pp}, 0) ;;
    value_format_name: percent_1
  }

  measure: engagement_rate_cp_vs_pp_var {
    label: "Engagement Rate Δ (pts)"
    group_label: "⚡ | Traffic"
    description: "Engagement rate CP - PP, in percentage points."
    type: number
    sql: ${engagement_rate_cp} - ${engagement_rate_pp} ;;
    value_format_name: percent_1
  }

  measure: engagement_seconds_cp {
    hidden: yes
    description: "Helper: engagement seconds in the current period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.user_engagement_duration END ;;
  }

  measure: engagement_seconds_pp {
    hidden: yes
    description: "Helper: engagement seconds in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.user_engagement_duration END ;;
  }

  measure: avg_engagement_time_per_session_cp {
    label: "Avg Engagement Time / Session (sec) (CP)"
    group_label: "⚡ | Traffic"
    description: "Engagement seconds / Sessions in the current period."
    type: number
    sql: ${engagement_seconds_cp} / NULLIF(${sessions_cp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: avg_engagement_time_per_session_pp {
    label: "Avg Engagement Time / Session (sec) (PP)"
    group_label: "⚡ | Traffic"
    description: "Engagement seconds / Sessions in the prior period."
    type: number
    sql: ${engagement_seconds_pp} / NULLIF(${sessions_pp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: avg_engagement_time_per_session_cp_vs_pp_var {
    label: "Avg Engagement Time / Session Δ (sec)"
    group_label: "⚡ | Traffic"
    description: "Avg engagement time per session CP - PP, in seconds."
    type: number
    sql: ${avg_engagement_time_per_session_cp} - ${avg_engagement_time_per_session_pp} ;;
    value_format_name: decimal_0
  }
}
