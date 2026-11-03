view: website_location_daily {
  label: "Website - Locations"

  # -------------------------------------------------
  #              PERSISTED DERIVED TABLE (BQ)
  # -------------------------------------------------
  #
  # One row per location per day: the location scorecard.
  #   Search - gsc page_report, web search, /locations/<slug>/ pages
  #   Pages  - GA4 pages_path_report, All Locations property, same pages
  # Both mapped slug -> FIM franchise (operating locations only).
  # Unattributed location pages are excluded here; see gsc_pages /
  # ga4_pages for those.
  #
  # The slug map is INLINED as the slugs CTE below, not referenced via
  # ${location_slugs.SQL_TABLE_NAME}: in a persisted table Looker prepends
  # referenced derived tables as their own WITH clause, which collides
  # with this SQL's WITH and fails the CREATE TABLE. Keep the slugs CTE
  # identical to location_slugs.view.lkml.
  #
  # Search figures are ATTRIBUTED (page-level ~53% of site clicks).
  #
  # FULL OUTER JOIN on franchise_name + date so a location with data in
  # only one source still appears.
  # Validated 2026-11-02: 72 locations, one row per location-day;
  # Oct 2026 = 2,920 search clicks / 29,272 page views.
  #
  # As of yesterday: today is excluded (partial day).

  derived_table: {
    datagroup_trigger: website_analytics_datagroup
    sql:
      WITH f AS (
        SELECT
          franchise_name,
          REGEXP_REPLACE(
            REGEXP_REPLACE(LOWER(TRIM(REGEXP_REPLACE(franchise_name, r'\[\d+\]', ''))), r'[^a-z0-9]+', '-'),
            r'^-|-$', ''
          ) AS name_slug,
          LOWER(REGEXP_EXTRACT(
            JSON_VALUE(website_url_raw, '$.url'),
            r'theglassguru\.com/(?:locations/)?([A-Za-z0-9\-]+)/?$'
          )) AS url_slug
        FROM `fivetran-the-glass-guru-wareho.raw_knack_fim.etl_knack_franchises`
        WHERE status IN ('Active', 'Active - Listed for Sale', 'Onboarding', 'Wind-Down')
      ),
      slugs AS (
        SELECT slug, MIN(franchise_name) AS franchise_name
        FROM (
          SELECT name_slug AS slug, franchise_name FROM f WHERE name_slug IS NOT NULL AND name_slug != ''
          UNION ALL
          SELECT url_slug AS slug, franchise_name FROM f WHERE url_slug IS NOT NULL
        )
        GROUP BY slug
      ),
      gsc AS (
        SELECT
          s.franchise_name,
          g.date,
          SUM(g.clicks) AS gsc_clicks,
          SUM(g.impressions) AS gsc_impressions,
          SUM(g.position * g.impressions) AS gsc_position_x_impressions
        FROM `fivetran-the-glass-guru-wareho.google_search_console.page_report` AS g
        JOIN slugs AS s
          ON s.slug = LOWER(REGEXP_EXTRACT(g.page, r'^https?://[^/]+/locations/([A-Za-z0-9\-]+)'))
        WHERE g.site = 'https://www.theglassguru.com/'
          AND g.search_type = 'web'
          AND g.date < CURRENT_DATE('America/Chicago')
        GROUP BY 1, 2
      ),
      ga AS (
        SELECT
          s.franchise_name,
          p.date,
          SUM(p.screen_page_views) AS page_views,
          SUM(p.user_engagement_duration) AS engagement_seconds
        FROM `fivetran-the-glass-guru-wareho.google_analytics_4.pages_path_report` AS p
        JOIN slugs AS s
          ON s.slug = LOWER(REGEXP_EXTRACT(p.page_path, r'^/locations/([A-Za-z0-9\-]+)'))
        WHERE p.property = 'properties/384050813'
          AND p.date < CURRENT_DATE('America/Chicago')
        GROUP BY 1, 2
      )
      SELECT
        COALESCE(gsc.franchise_name, ga.franchise_name) AS franchise_name,
        COALESCE(gsc.date, ga.date) AS date,
        gsc.gsc_clicks,
        gsc.gsc_impressions,
        gsc.gsc_position_x_impressions,
        ga.page_views,
        ga.engagement_seconds
      FROM gsc
      FULL OUTER JOIN ga
        ON ga.franchise_name = gsc.franchise_name
        AND ga.date = gsc.date
    ;;
  }

  # -------------------------------------------------
  #                   PRIMARY KEY
  # -------------------------------------------------

  dimension: pk {
    primary_key: yes
    hidden: yes
    description: "franchise_name | date. Verified unique 2026-11-02."
    type: string
    sql: CONCAT(${TABLE}.franchise_name, '|', CAST(${TABLE}.date AS STRING)) ;;
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
  #                   DIMENSIONS
  # -------------------------------------------------

  dimension: franchise_name {
    hidden: yes
    description: "FIM franchise name. Join key to etl_knack_franchises."
    type: string
    sql: ${TABLE}.franchise_name ;;
  }

  # -------------------------------------------------
  #                ALL-TIME MEASURES
  # -------------------------------------------------

  measure: impressions {
    label: "Impressions #"
    group_label: "⏳ | Scorecard"
    description: "Times the location's pages appeared in Google search (attributed, web)."
    type: sum
    sql: ${TABLE}.gsc_impressions ;;
    value_format_name: decimal_0
  }

  measure: clicks {
    label: "Clicks #"
    group_label: "⏳ | Scorecard"
    description: "Clicks from Google search to the location's pages (attributed, web)."
    type: sum
    sql: ${TABLE}.gsc_clicks ;;
    value_format_name: decimal_0
  }

  measure: ctr {
    label: "CTR %"
    group_label: "⏳ | Scorecard"
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
    group_label: "⏳ | Scorecard"
    description: "Impression-weighted average ranking position. Lower is better."
    type: number
    sql: ${position_x_impressions} / NULLIF(${impressions}, 0) ;;
    value_format_name: decimal_1
  }

  measure: page_views {
    label: "Page Views #"
    group_label: "⏳ | Scorecard"
    description: "Views of the location's pages (all traffic sources, not just search)."
    type: sum
    sql: ${TABLE}.page_views ;;
    value_format_name: decimal_0
  }

  measure: engagement_seconds {
    hidden: yes
    description: "Helper: engagement seconds on the location's pages."
    type: sum
    sql: ${TABLE}.engagement_seconds ;;
  }

  measure: avg_engagement_time_per_view {
    label: "Avg Engagement Time / View (sec)"
    group_label: "⏳ | Scorecard"
    description: "Engagement seconds / Page Views."
    type: number
    sql: ${engagement_seconds} / NULLIF(${page_views}, 0) ;;
    value_format_name: decimal_0
  }

  measure: locations_count {
    label: "Locations #"
    group_label: "⏳ | Scorecard"
    description: "Distinct locations with website activity."
    type: count_distinct
    sql: ${TABLE}.franchise_name ;;
  }

  # -------------------------------------------------
  #            DYNAMIC MEASURES (CP / PP)
  # -------------------------------------------------

  measure: impressions_cp {
    label: "Impressions # (CP)"
    group_label: "⚡ | Scorecard"
    description: "Impressions in the current period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.gsc_impressions END ;;
    value_format_name: decimal_0
  }

  measure: impressions_pp {
    label: "Impressions # (PP)"
    group_label: "⚡ | Scorecard"
    description: "Impressions in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.gsc_impressions END ;;
    value_format_name: decimal_0
  }

  measure: impressions_cp_vs_pp_var {
    label: "Impressions Δ"
    group_label: "⚡ | Scorecard"
    description: "Impressions CP - PP."
    type: number
    sql: COALESCE(${impressions_cp}, 0) - COALESCE(${impressions_pp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: impressions_cp_vs_pp_var_percent {
    label: "Impressions Δ%"
    group_label: "⚡ | Scorecard"
    description: "Impressions (CP - PP) / PP."
    type: number
    sql: (COALESCE(${impressions_cp}, 0) - COALESCE(${impressions_pp}, 0)) / NULLIF(${impressions_pp}, 0) ;;
    value_format_name: percent_1
  }

  measure: clicks_cp {
    label: "Clicks # (CP)"
    group_label: "⚡ | Scorecard"
    description: "Clicks in the current period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.gsc_clicks END ;;
    value_format_name: decimal_0
  }

  measure: clicks_pp {
    label: "Clicks # (PP)"
    group_label: "⚡ | Scorecard"
    description: "Clicks in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.gsc_clicks END ;;
    value_format_name: decimal_0
  }

  measure: clicks_cp_vs_pp_var {
    label: "Clicks Δ"
    group_label: "⚡ | Scorecard"
    description: "Clicks CP - PP."
    type: number
    sql: COALESCE(${clicks_cp}, 0) - COALESCE(${clicks_pp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: clicks_cp_vs_pp_var_percent {
    label: "Clicks Δ%"
    group_label: "⚡ | Scorecard"
    description: "Clicks (CP - PP) / PP."
    type: number
    sql: (COALESCE(${clicks_cp}, 0) - COALESCE(${clicks_pp}, 0)) / NULLIF(${clicks_pp}, 0) ;;
    value_format_name: percent_1
  }

  measure: ctr_cp {
    label: "CTR % (CP)"
    group_label: "⚡ | Scorecard"
    description: "Clicks / Impressions in the current period."
    type: number
    sql: ${clicks_cp} / NULLIF(${impressions_cp}, 0) ;;
    value_format_name: percent_2
  }

  measure: ctr_pp {
    label: "CTR % (PP)"
    group_label: "⚡ | Scorecard"
    description: "Clicks / Impressions in the prior period."
    type: number
    sql: ${clicks_pp} / NULLIF(${impressions_pp}, 0) ;;
    value_format_name: percent_2
  }

  measure: ctr_cp_vs_pp_var {
    label: "CTR Δ (pts)"
    group_label: "⚡ | Scorecard"
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
    group_label: "⚡ | Scorecard"
    description: "Impression-weighted position in the current period. Lower is better."
    type: number
    sql: ${position_x_impressions_cp} / NULLIF(${impressions_cp}, 0) ;;
    value_format_name: decimal_1
  }

  measure: avg_position_pp {
    label: "Avg Position (PP)"
    group_label: "⚡ | Scorecard"
    description: "Impression-weighted position in the prior period. Lower is better."
    type: number
    sql: ${position_x_impressions_pp} / NULLIF(${impressions_pp}, 0) ;;
    value_format_name: decimal_1
  }

  measure: avg_position_cp_vs_pp_var {
    label: "Avg Position Δ"
    group_label: "⚡ | Scorecard"
    description: "Position CP - PP. Negative = ranking improved."
    type: number
    sql: ${avg_position_cp} - ${avg_position_pp} ;;
    value_format_name: decimal_1
  }

  measure: page_views_cp {
    label: "Page Views # (CP)"
    group_label: "⚡ | Scorecard"
    description: "Page views in the current period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.current_period_start} AND ${timeframe_filters.current_period_end} THEN ${TABLE}.page_views END ;;
    value_format_name: decimal_0
  }

  measure: page_views_pp {
    label: "Page Views # (PP)"
    group_label: "⚡ | Scorecard"
    description: "Page views in the prior period."
    type: sum
    sql: CASE WHEN ${TABLE}.date BETWEEN ${timeframe_filters.prior_period_start} AND ${timeframe_filters.prior_period_end} THEN ${TABLE}.page_views END ;;
    value_format_name: decimal_0
  }

  measure: page_views_cp_vs_pp_var {
    label: "Page Views Δ"
    group_label: "⚡ | Scorecard"
    description: "Page views CP - PP."
    type: number
    sql: COALESCE(${page_views_cp}, 0) - COALESCE(${page_views_pp}, 0) ;;
    value_format_name: decimal_0
  }

  measure: page_views_cp_vs_pp_var_percent {
    label: "Page Views Δ%"
    group_label: "⚡ | Scorecard"
    description: "Page views (CP - PP) / PP."
    type: number
    sql: (COALESCE(${page_views_cp}, 0) - COALESCE(${page_views_pp}, 0)) / NULLIF(${page_views_pp}, 0) ;;
    value_format_name: percent_1
  }
}
