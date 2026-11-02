view: gsc_queries {
  label: "Search Console - Search Terms"

  # -------------------------------------------------
  #                 DERIVED TABLE (BQ)
  # -------------------------------------------------
  #
  # Search Console by search term and page for www.theglassguru.com.
  # Source: google_search_console.keyword_page_report (Fivetran).
  # Grain: date x search_type x country x device x page x query.
  #
  # ATTRIBUTED DATA: query-level rows capture ~53% of site clicks
  # (Google withholds rare/anonymized queries). Use gsc_site for
  # complete totals.
  #
  # Branded = search term contains "glass guru" / "glassguru".
  # Validated 2026-11-02: 64% of search-term clicks are branded.
  #
  # As of yesterday: today is excluded (partial day).

  derived_table: {
    sql:
      WITH q AS (
        SELECT
          date,
          search_type,
          country,
          device,
          page,
          query,
          REGEXP_EXTRACT(page, r'^https?://[^/]+(/[^?#]*)') AS page_path,
          LOWER(REGEXP_EXTRACT(page, r'^https?://[^/]+/locations/([A-Za-z0-9\-]+)')) AS location_slug,
          clicks,
          impressions,
          position * impressions AS position_x_impressions
        FROM `fivetran-the-glass-guru-wareho.google_search_console.keyword_page_report`
        WHERE site = 'https://www.theglassguru.com/'
          AND date < CURRENT_DATE('America/Chicago')
      )
      SELECT
        q.*,
        s.franchise_name
      FROM q
      LEFT JOIN ${location_slugs.SQL_TABLE_NAME} AS s
        ON q.location_slug = s.slug
    ;;
  }

  # -------------------------------------------------
  #                   PRIMARY KEY
  # -------------------------------------------------

  dimension: pk {
    primary_key: yes
    hidden: yes
    description: "date | search_type | country | device | page | query. Verified unique 2026-11-02."
    type: string
    sql: CONCAT(CAST(${TABLE}.date AS STRING), '|', ${TABLE}.search_type, '|', IFNULL(${TABLE}.country, '~'), '|', IFNULL(${TABLE}.device, '~'), '|', ${TABLE}.page, '|', ${TABLE}.query) ;;
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

  dimension: query {
    label: "Search Term"
    description: "The term the searcher typed into Google."
    type: string
    sql: ${TABLE}.query ;;
  }

  dimension: is_branded {
    label: "Is Branded"
    description: "TRUE when the search term contains 'glass guru' or 'glassguru'."
    type: yesno
    sql: REGEXP_CONTAINS(LOWER(${TABLE}.query), r'glass\s*guru') ;;
  }

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

  dimension: page {
    label: "Page URL"
    description: "Full landing page URL shown in Google results."
    type: string
    sql: ${TABLE}.page ;;
    link: {
      label: "Open page"
      url: "{{ value }}"
    }
  }

  dimension: page_path {
    label: "Page Path"
    description: "Page URL without domain, query string, or fragment (e.g. /locations/carrollton-tx/)."
    type: string
    sql: ${TABLE}.page_path ;;
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

  measure: clicks {
    label: "Clicks #"
    group_label: "⏳ | Search"
    description: "Clicks from Google search (attributed)."
    type: sum
    sql: ${TABLE}.clicks ;;
    value_format_name: decimal_0
  }

  measure: impressions {
    label: "Impressions #"
    group_label: "⏳ | Search"
    description: "Times the site appeared in Google search results (attributed)."
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

  measure: query_count {
    label: "Search Terms #"
    group_label: "⏳ | Search"
    description: "Distinct search terms."
    type: count_distinct
    sql: ${TABLE}.query ;;
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
