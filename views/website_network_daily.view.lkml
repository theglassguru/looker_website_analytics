view: website_network_daily {
  label: "Website - Network"

  # -------------------------------------------------
  #              PERSISTED DERIVED TABLE (BQ)
  # -------------------------------------------------
  #
  # One row per day: the whole-site scorecard.
  #   Search  - gsc site_report_by_page, www site, web search (complete totals)
  #   Traffic - GA4 channel report, All Locations property
  #   Pages   - GA4 pages_path_report, All Locations property
  #   Visitors- GA4 events_report, page_view event total_users
  #
  # Daily visitors = people who viewed at least one page that day. Taken
  # from the page_view event so WhatConverts-imported call/form events
  # (which carry no page view) are not counted as visitors. Visitor
  # counts are valid PER DAY only; Avg Daily Visitors is valid for any
  # period. Never sum visitors across days.
  #
  # Sessions include ~12K/month 'Unassigned' sessions (source '(not set)',
  # relabeled '(unassigned imported)' from 2026-10-07) with ~1% engagement
  # and a business-hours pattern - consistent month to month.
  #
  # FULL OUTER JOIN on date so a day missing from one source still appears.
  # Validated 2026-11-02: Oct 2026 = 6,429 clicks / 57,368 sessions /
  # 74,370 page views / 1,307 avg daily visitors (matches base views).
  #
  # As of yesterday: today is excluded (partial day).

  derived_table: {
    datagroup_trigger: website_analytics_datagroup
    sql:
      WITH gsc AS (
        SELECT
          date,
          SUM(clicks) AS gsc_clicks,
          SUM(impressions) AS gsc_impressions,
          SUM(position * impressions) AS gsc_position_x_impressions
        FROM `fivetran-the-glass-guru-wareho.google_search_console.site_report_by_page`
        WHERE site = 'https://www.theglassguru.com/'
          AND search_type = 'web'
          AND date < CURRENT_DATE('America/Chicago')
        GROUP BY date
      ),
      ch AS (
        SELECT
          date,
          SUM(sessions) AS sessions,
          SUM(engaged_sessions) AS engaged_sessions,
          SUM(user_engagement_duration) AS engagement_seconds
        FROM `fivetran-the-glass-guru-wareho.google_analytics_4.traffic_acquisition_session_default_channel_grouping_report`
        WHERE property = 'properties/384050813'
          AND date < CURRENT_DATE('America/Chicago')
        GROUP BY date
      ),
      pg AS (
        SELECT
          date,
          SUM(screen_page_views) AS page_views
        FROM `fivetran-the-glass-guru-wareho.google_analytics_4.pages_path_report`
        WHERE property = 'properties/384050813'
          AND date < CURRENT_DATE('America/Chicago')
        GROUP BY date
      ),
      vis AS (
        SELECT
          date,
          SUM(total_users) AS visitors
        FROM `fivetran-the-glass-guru-wareho.google_analytics_4.events_report`
        WHERE property = 'properties/384050813'
          AND event_name = 'page_view'
          AND date < CURRENT_DATE('America/Chicago')
        GROUP BY date
      )
      SELECT
        COALESCE(gsc.date, ch.date, pg.date, vis.date) AS date,
        gsc.gsc_clicks,
        gsc.gsc_impressions,
        gsc.gsc_position_x_impressions,
        ch.sessions,
        ch.engaged_sessions,
        ch.engagement_seconds,
        pg.page_views,
        vis.visitors
      FROM gsc
      FULL OUTER JOIN ch ON ch.date = gsc.date
      FULL OUTER JOIN pg ON pg.date = COALESCE(gsc.date, ch.date)
      FULL OUTER JOIN vis ON vis.date = COALESCE(gsc.date, ch.date, pg.date)
    ;;
  }

  # -------------------------------------------------
  #                   PRIMARY KEY
  # -------------------------------------------------

  dimension: pk {
    primary_key: yes
    hidden: yes
    description: "date. One row per day."
    type: string
    sql: CAST(${TABLE}.date AS STRING) ;;
  }

  # -------------------------------------------------
  #                     DATES
  # -------------------------------------------------

  dimension_group: date {
    label: "Activity"
    group_label: "📅 | Activity Date"
    description: "Reporting date. GA4 uses the property time zone (America/Denver); Search Console uses its own reporting day. Date only."
    type: time
    datatype: date
    convert_tz: no
    timeframes: [raw, date, week, month, month_name, quarter, year]
    sql: ${TABLE}.date ;;
  }

  # -------------------------------------------------
  #           ALL-TIME MEASURES - SEARCH
  # -------------------------------------------------

  measure: clicks {
    label: "Clicks #"
    group_label: "⏳ | Search"
    description: "Clicks from Google search to the site (complete totals, web search)."
    type: sum
    sql: ${TABLE}.gsc_clicks ;;
    value_format_name: decimal_0
  }

  measure: impressions {
    label: "Impressions #"
    group_label: "⏳ | Search"
    description: "Times the site appeared in Google search results (web search)."
    type: sum
    sql: ${TABLE}.gsc_impressions ;;
    value_format_name: decimal_0
  }

  measure: ctr {
    label: "CTR %"
    group_label: "⏳ | Search"
    description: "Clicks / Impressions."
    type: number
    sql: ${clicks} / NULLIF(${impressions}, 0) ;;
    value_format_name: percent_2
  }

  measure: position_x_impressions {
    hidden: yes
    description: "Helper: SUM(position x impressions)."
    type: sum
    sql: ${TABLE}.gsc_position_x_impressions ;;
  }

  measure: avg_position {
    label: "Avg Position"
    group_label: "⏳ | Search"
    description: "Impression-weighted average ranking position. Lower is better."
    type: number
    sql: ${position_x_impressions} / NULLIF(${impressions}, 0) ;;
    value_format_name: decimal_1
  }

  # -------------------------------------------------
  #           ALL-TIME MEASURES - TRAFFIC
  # -------------------------------------------------

  measure: sessions {
    label: "Sessions #"
    group_label: "⏳ | Traffic"
    description: "Visits to the site (All Locations property)."
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
    description: "Helper: total engagement seconds."
    type: sum
    sql: ${TABLE}.engagement_seconds ;;
  }

  measure: avg_engagement_time_per_session {
    label: "Avg Engagement Time / Session (sec)"
    group_label: "⏳ | Traffic"
    description: "Engagement seconds / Sessions."
    type: number
    sql: ${engagement_seconds} / NULLIF(${sessions}, 0) ;;
    value_format_name: decimal_0
  }

  measure: page_views {
    label: "Page Views #"
    group_label: "⏳ | Traffic"
    description: "Total page views across the site."
    type: sum
    sql: ${TABLE}.page_views ;;
    value_format_name: decimal_0
  }

  measure: daily_visitors {
    label: "Daily Visitors #"
    group_label: "⏳ | Traffic"
    description: "People who viewed at least one page. VALID ONLY WHEN GROUPED BY DAY - summing across days double-counts returning visitors. Use Avg Daily Visitors for periods."
    type: sum
    sql: ${TABLE}.visitors ;;
    value_format_name: decimal_0
  }

  measure: days_with_visitors {
    hidden: yes
    description: "Helper: days with a visitor count."
    type: count_distinct
    sql: CASE WHEN ${TABLE}.visitors IS NOT NULL THEN ${TABLE}.date END ;;
  }

  measure: avg_daily_visitors {
    label: "Avg Daily Visitors #"
    group_label: "⏳ | Traffic"
    description: "Average people per day who viewed at least one page. Valid for any period."
    type: number
    sql: ${daily_visitors} / NULLIF(${days_with_visitors}, 0) ;;
    value_format_name: decimal_0
  }

  # -------------------------------------------------
  #        DYNAMIC MEASURES (CP / PP) - SEARCH
  # -------------------------------------------------

  measure: clicks_cp {
    label: "Clicks # (CP)"
    group_label: "⚡ | Search"
    description: "Clicks in the current period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.gsc_clicks END ;;
    value_format_name: decimal_0
  }

  measure: clicks_pp {
    label: "Clicks # (PP)"
    group_label: "⚡ | Search"
    description: "Clicks in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.gsc_clicks END ;;
    value_format_name: decimal_0
  }

  measure: clicks_cp_vs_pp_var {
    label: "Clicks Δ"
    group_label: "⚡ | Search"
    description: "Clicks CP - PP."
    type: number
    sql: COALESCE(${clicks_cp}, 0) - COALESCE(${clicks_pp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: clicks_cp_vs_pp_var_percent {
    label: "Clicks Δ%"
    group_label: "⚡ | Search"
    description: "Clicks (CP - PP) / PP."
    type: number
    sql: (COALESCE(${clicks_cp}, 0) - COALESCE(${clicks_pp}, 0)) / NULLIF(${clicks_pp}, 0) ;;
    value_format_name: percent_1
  }

  measure: impressions_cp {
    label: "Impressions # (CP)"
    group_label: "⚡ | Search"
    description: "Impressions in the current period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.gsc_impressions END ;;
    value_format_name: decimal_0
  }

  measure: impressions_pp {
    label: "Impressions # (PP)"
    group_label: "⚡ | Search"
    description: "Impressions in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.gsc_impressions END ;;
    value_format_name: decimal_0
  }

  measure: impressions_cp_vs_pp_var {
    label: "Impressions Δ"
    group_label: "⚡ | Search"
    description: "Impressions CP - PP."
    type: number
    sql: COALESCE(${impressions_cp}, 0) - COALESCE(${impressions_pp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: impressions_cp_vs_pp_var_percent {
    label: "Impressions Δ%"
    group_label: "⚡ | Search"
    description: "Impressions (CP - PP) / PP."
    type: number
    sql: (COALESCE(${impressions_cp}, 0) - COALESCE(${impressions_pp}, 0)) / NULLIF(${impressions_pp}, 0) ;;
    value_format_name: percent_1
  }

  measure: ctr_cp {
    label: "CTR % (CP)"
    group_label: "⚡ | Search"
    description: "Clicks / Impressions in the current period."
    type: number
    sql: ${clicks_cp} / NULLIF(${impressions_cp}, 0) ;;
    value_format_name: percent_2
  }

  measure: ctr_pp {
    label: "CTR % (PP)"
    group_label: "⚡ | Search"
    description: "Clicks / Impressions in the prior period."
    type: number
    sql: ${clicks_pp} / NULLIF(${impressions_pp}, 0) ;;
    value_format_name: percent_2
  }

  measure: ctr_cp_vs_pp_var {
    label: "CTR Δ (pts)"
    group_label: "⚡ | Search"
    description: "CTR CP - PP, in percentage points."
    type: number
    sql: ${ctr_cp} - ${ctr_pp} ;;
    value_format_name: percent_2
  }

  measure: position_x_impressions_cp {
    hidden: yes
    description: "Helper: position x impressions in the current period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.gsc_position_x_impressions END ;;
  }

  measure: position_x_impressions_pp {
    hidden: yes
    description: "Helper: position x impressions in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.gsc_position_x_impressions END ;;
  }

  measure: avg_position_cp {
    label: "Avg Position (CP)"
    group_label: "⚡ | Search"
    description: "Impression-weighted position in the current period. Lower is better."
    type: number
    sql: ${position_x_impressions_cp} / NULLIF(${impressions_cp}, 0) ;;
    value_format_name: decimal_1
  }

  measure: avg_position_pp {
    label: "Avg Position (PP)"
    group_label: "⚡ | Search"
    description: "Impression-weighted position in the prior period. Lower is better."
    type: number
    sql: ${position_x_impressions_pp} / NULLIF(${impressions_pp}, 0) ;;
    value_format_name: decimal_1
  }

  measure: avg_position_cp_vs_pp_var {
    label: "Avg Position Δ"
    group_label: "⚡ | Search"
    description: "Position CP - PP. Negative = ranking improved."
    type: number
    sql: ${avg_position_cp} - ${avg_position_pp} ;;
    value_format_name: decimal_1
  }

  # -------------------------------------------------
  #        DYNAMIC MEASURES (CP / PP) - TRAFFIC
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

  measure: page_views_cp {
    label: "Page Views # (CP)"
    group_label: "⚡ | Traffic"
    description: "Page views in the current period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.page_views END ;;
    value_format_name: decimal_0
  }

  measure: page_views_pp {
    label: "Page Views # (PP)"
    group_label: "⚡ | Traffic"
    description: "Page views in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.page_views END ;;
    value_format_name: decimal_0
  }

  measure: page_views_cp_vs_pp_var {
    label: "Page Views Δ"
    group_label: "⚡ | Traffic"
    description: "Page views CP - PP."
    type: number
    sql: COALESCE(${page_views_cp}, 0) - COALESCE(${page_views_pp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: page_views_cp_vs_pp_var_percent {
    label: "Page Views Δ%"
    group_label: "⚡ | Traffic"
    description: "Page views (CP - PP) / PP."
    type: number
    sql: (COALESCE(${page_views_cp}, 0) - COALESCE(${page_views_pp}, 0)) / NULLIF(${page_views_pp}, 0) ;;
    value_format_name: percent_1
  }

  measure: visitors_cp_sum {
    hidden: yes
    description: "Helper: summed daily visitors in the current period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.visitors END ;;
  }

  measure: visitors_pp_sum {
    hidden: yes
    description: "Helper: summed daily visitors in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.visitors END ;;
  }

  measure: visitor_days_cp {
    hidden: yes
    description: "Helper: days with visitors in the current period."
    type: count_distinct
    sql: CASE WHEN ${TABLE}.visitors IS NOT NULL AND ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.date END ;;
  }

  measure: visitor_days_pp {
    hidden: yes
    description: "Helper: days with visitors in the prior period."
    type: count_distinct
    sql: CASE WHEN ${TABLE}.visitors IS NOT NULL AND ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.date END ;;
  }

  measure: avg_daily_visitors_cp {
    label: "Avg Daily Visitors # (CP)"
    group_label: "⚡ | Traffic"
    description: "Average daily visitors in the current period."
    type: number
    sql: ${visitors_cp_sum} / NULLIF(${visitor_days_cp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: avg_daily_visitors_pp {
    label: "Avg Daily Visitors # (PP)"
    group_label: "⚡ | Traffic"
    description: "Average daily visitors in the prior period."
    type: number
    sql: ${visitors_pp_sum} / NULLIF(${visitor_days_pp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: avg_daily_visitors_cp_vs_pp_var {
    label: "Avg Daily Visitors Δ"
    group_label: "⚡ | Traffic"
    description: "Avg daily visitors CP - PP."
    type: number
    sql: ${avg_daily_visitors_cp} - ${avg_daily_visitors_pp} ;;
    value_format_name: decimal_0
  }

  measure: avg_daily_visitors_cp_vs_pp_var_percent {
    label: "Avg Daily Visitors Δ%"
    group_label: "⚡ | Traffic"
    description: "Avg daily visitors (CP - PP) / PP."
    type: number
    sql: (${avg_daily_visitors_cp} - ${avg_daily_visitors_pp}) / NULLIF(${avg_daily_visitors_pp}, 0) ;;
    value_format_name: percent_1
  }
}
