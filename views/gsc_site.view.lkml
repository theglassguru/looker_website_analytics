view: gsc_site {
  label: "Search Console - Site"

  # -------------------------------------------------
  #                 DERIVED TABLE (BQ)
  # -------------------------------------------------
  #
  # Site-wide Search Console totals for www.theglassguru.com.
  # Source: google_search_console.site_report_by_page (Fivetran).
  # Grain: date x search_type x country x device.
  #
  # These are COMPLETE totals and match the Search Console UI.
  # Page and query views capture only ~53% of clicks; use this view
  # for network totals.
  #
  # As of yesterday: today is excluded (partial day).

  derived_table: {
    sql:
      SELECT
        date,
        search_type,
        country,
        device,
        clicks,
        impressions,
        position,
        position * impressions AS position_x_impressions
      FROM `fivetran-the-glass-guru-wareho.google_search_console.site_report_by_page`
      WHERE site = 'https://www.theglassguru.com/'
        AND date < CURRENT_DATE('America/Chicago')
    ;;
  }

  # -------------------------------------------------
  #                   PRIMARY KEY
  # -------------------------------------------------

  dimension: pk {
    primary_key: yes
    hidden: yes
    description: "date | search_type | country | device. Verified unique 2026-11-02."
    type: string
    sql: CONCAT(CAST(${TABLE}.date AS STRING), '|', ${TABLE}.search_type, '|', IFNULL(${TABLE}.country, '~'), '|', IFNULL(${TABLE}.device, '~')) ;;
  }

  # -------------------------------------------------
  #                     DATES
  # -------------------------------------------------

  dimension_group: date {
    label: "Search"
    group_label: "📅 | Search Date"
    description: "Search Console reporting date. Date only; the source has no timestamps."
    type: time
    datatype: date
    convert_tz: no
    timeframes: [raw, date, week, month, month_name, quarter, year]
    sql: ${TABLE}.date ;;
  }

  # -------------------------------------------------
  #                   DIMENSIONS
  # -------------------------------------------------

  dimension: search_type {
    label: "Search Type"
    description: "Google search surface: web, image, video, news, discover, googleNews. Explores default to web."
    type: string
    sql: ${TABLE}.search_type ;;
  }

  dimension: country {
    label: "Country"
    description: "Searcher country (ISO 3166-1 alpha-3, e.g. usa)."
    type: string
    sql: ${TABLE}.country ;;
  }

  dimension: device {
    label: "Device"
    description: "Searcher device: DESKTOP, MOBILE, TABLET."
    type: string
    sql: ${TABLE}.device ;;
  }

  # -------------------------------------------------
  #                ALL-TIME MEASURES
  # -------------------------------------------------

  measure: clicks {
    label: "Clicks #"
    group_label: "⏳ | Search"
    description: "Clicks from Google search to the site."
    type: sum
    sql: ${TABLE}.clicks ;;
    value_format_name: decimal_0
  }

  measure: impressions {
    label: "Impressions #"
    group_label: "⏳ | Search"
    description: "Times the site appeared in Google search results."
    type: sum
    sql: ${TABLE}.impressions ;;
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
    description: "Helper: SUM(position x impressions) for impression-weighted position."
    type: sum
    sql: ${TABLE}.position_x_impressions ;;
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
  #            DYNAMIC MEASURES (CP / PP)
  # -------------------------------------------------

  measure: clicks_cp {
    label: "Clicks # (CP)"
    group_label: "⚡ | Search"
    description: "Clicks in the current period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.clicks END ;;
    value_format_name: decimal_0
  }

  measure: clicks_pp {
    label: "Clicks # (PP)"
    group_label: "⚡ | Search"
    description: "Clicks in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.clicks END ;;
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
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.impressions END ;;
    value_format_name: decimal_0
  }

  measure: impressions_pp {
    label: "Impressions # (PP)"
    group_label: "⚡ | Search"
    description: "Impressions in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.impressions END ;;
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
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.position_x_impressions END ;;
  }

  measure: position_x_impressions_pp {
    hidden: yes
    description: "Helper: position x impressions in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.position_x_impressions END ;;
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
}
