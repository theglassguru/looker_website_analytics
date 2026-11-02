view: ga4_pages {
  label: "GA4 - Pages"

  # -------------------------------------------------
  #                 DERIVED TABLE (BQ)
  # -------------------------------------------------
  #
  # Page traffic by page path.
  # Source: google_analytics_4.pages_path_report
  # Property: All Locations (properties/384050813), the full-site property.
  # Grain: date x page_path. Dates in property time zone (America/Denver).
  #
  # This report has no sessions; page views are the unit.
  # Visitor counts are not exposed (non-additive across rows/days).
  #
  # Location attribution: /locations/<slug>/ pages (and sub-pages)
  # join location_slugs -> FIM franchise. Covers the 9 locations whose
  # own GA4 properties mirror the whole site, because this uses their
  # real location pages in All Locations.
  #
  # Do not join to other GA4 report views.
  #
  # As of yesterday: today is excluded (partial day).

  derived_table: {
    sql:
      WITH p AS (
        SELECT
          property,
          date,
          _fivetran_id,
          page_path,
          LOWER(REGEXP_EXTRACT(page_path, r'^/locations/([A-Za-z0-9\-]+)')) AS location_slug,
          screen_page_views,
          user_engagement_duration
        FROM `fivetran-the-glass-guru-wareho.google_analytics_4.pages_path_report`
        WHERE property = 'properties/384050813'
          AND date < CURRENT_DATE('America/Chicago')
      )
      SELECT
        p.*,
        s.franchise_name
      FROM p
      LEFT JOIN ${location_slugs.SQL_TABLE_NAME} AS s
        ON p.location_slug = s.slug
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

  dimension: page_path {
    label: "Page Path"
    description: "Page path on the site (e.g. /locations/carrollton-tx/)."
    type: string
    sql: ${TABLE}.page_path ;;
    link: {
      label: "Open page"
      url: "https://www.theglassguru.com{{ value }}"
    }
  }

  dimension: page_type {
    label: "Page Type"
    description: "Home, Location, Service, Quote, Franchise, Blog (URL ends in -blog/), or Other. Older articles without -blog in the URL fall in Other."
    type: string
    sql:
      CASE
        WHEN ${TABLE}.page_path = '/' THEN 'Home'
        WHEN REGEXP_CONTAINS(${TABLE}.page_path, r'^/locations/[A-Za-z0-9]') THEN 'Location'
        WHEN STARTS_WITH(${TABLE}.page_path, '/services/') THEN 'Service'
        WHEN REGEXP_CONTAINS(${TABLE}.page_path, r'^/(get-free-quote|free-quote)') THEN 'Quote'
        WHEN STARTS_WITH(${TABLE}.page_path, '/franchise') THEN 'Franchise'
        WHEN REGEXP_CONTAINS(${TABLE}.page_path, r'-blog/?$') OR STARTS_WITH(${TABLE}.page_path, '/blog') THEN 'Blog'
        ELSE 'Other'
      END ;;
  }

  dimension: location_slug {
    label: "Location Slug"
    description: "Path segment after /locations/ (e.g. carrollton-tx). Sub-pages roll up to their location. NULL for non-location pages."
    type: string
    sql: ${TABLE}.location_slug ;;
  }

  dimension: franchise_name {
    hidden: yes
    description: "FIM franchise name from location_slugs. Join key to etl_knack_franchises."
    type: string
    sql: ${TABLE}.franchise_name ;;
  }

  dimension: location_attribution {
    label: "Location Attribution"
    description: "FIM franchise for location pages; 'Unattributed' for location pages with no operating FIM match; 'Not a Location Page' otherwise."
    type: string
    sql:
      CASE
        WHEN ${TABLE}.franchise_name IS NOT NULL THEN ${TABLE}.franchise_name
        WHEN ${TABLE}.location_slug IS NOT NULL THEN 'Unattributed'
        ELSE 'Not a Location Page'
      END ;;
  }

  # -------------------------------------------------
  #                ALL-TIME MEASURES
  # -------------------------------------------------

  measure: page_views {
    label: "Page Views #"
    group_label: "⏳ | Pages"
    description: "Times the page was viewed."
    type: sum
    sql: ${TABLE}.screen_page_views ;;
    value_format_name: decimal_0
  }

  measure: engagement_seconds {
    label: "Engagement Time (sec)"
    group_label: "⏳ | Pages"
    description: "Total time visitors were actively engaged on the page, in seconds."
    type: sum
    sql: ${TABLE}.user_engagement_duration ;;
    value_format_name: decimal_0
  }

  measure: avg_engagement_time_per_view {
    label: "Avg Engagement Time / View (sec)"
    group_label: "⏳ | Pages"
    description: "Engagement seconds / Page Views."
    type: number
    sql: ${engagement_seconds} / NULLIF(${page_views}, 0) ;;
    value_format_name: decimal_0
  }

  # -------------------------------------------------
  #            DYNAMIC MEASURES (CP / PP)
  # -------------------------------------------------

  measure: page_views_cp {
    label: "Page Views # (CP)"
    group_label: "⚡ | Pages"
    description: "Page views in the current period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.screen_page_views END ;;
    value_format_name: decimal_0
  }

  measure: page_views_pp {
    label: "Page Views # (PP)"
    group_label: "⚡ | Pages"
    description: "Page views in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.screen_page_views END ;;
    value_format_name: decimal_0
  }

  measure: page_views_cp_vs_pp_var {
    label: "Page Views Δ"
    group_label: "⚡ | Pages"
    description: "Page views CP - PP."
    type: number
    sql: COALESCE(${page_views_cp}, 0) - COALESCE(${page_views_pp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: page_views_cp_vs_pp_var_percent {
    label: "Page Views Δ%"
    group_label: "⚡ | Pages"
    description: "Page views (CP - PP) / PP."
    type: number
    sql: (COALESCE(${page_views_cp}, 0) - COALESCE(${page_views_pp}, 0)) / NULLIF(${page_views_pp}, 0) ;;
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

  measure: avg_engagement_time_per_view_cp {
    label: "Avg Engagement Time / View (sec) (CP)"
    group_label: "⚡ | Pages"
    description: "Engagement seconds / Page Views in the current period."
    type: number
    sql: ${engagement_seconds_cp} / NULLIF(${page_views_cp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: avg_engagement_time_per_view_pp {
    label: "Avg Engagement Time / View (sec) (PP)"
    group_label: "⚡ | Pages"
    description: "Engagement seconds / Page Views in the prior period."
    type: number
    sql: ${engagement_seconds_pp} / NULLIF(${page_views_pp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: avg_engagement_time_per_view_cp_vs_pp_var {
    label: "Avg Engagement Time / View Δ (sec)"
    group_label: "⚡ | Pages"
    description: "Avg engagement time per view CP - PP, in seconds."
    type: number
    sql: ${avg_engagement_time_per_view_cp} - ${avg_engagement_time_per_view_pp} ;;
    value_format_name: decimal_0
  }
}
