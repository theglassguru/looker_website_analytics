view: location_slugs {
  label: "Location Slugs"

  # -------------------------------------------------
  #                 DERIVED TABLE (BQ)
  # -------------------------------------------------
  #
  # Maps website location slugs (/locations/<slug>/) to FIM franchises.
  # One row per slug. A franchise may own more than one slug.
  #
  # Operating FIM records only: Active, Active - Listed for Sale,
  # Onboarding, Wind-Down. Slugs belonging only to inactive franchises
  # are absent here and roll to Unattributed in the joined views.
  #
  # Two slug sources per franchise, combined:
  #   1. Franchise Name  - "Carrollton TX [124225]" -> carrollton-tx
  #   2. FIM Website URL - last path segment of website_url_raw.url
  #      (FIM URLs are root-level, e.g. theglassguru.com/brentwood-ca)
  #
  # fid_count > 1 means two franchises claim the same slug. Expected 0;
  # collision_count surfaces it if that ever changes.
  #
  # Validated 2026-11-02: 78 slugs, 73 locations, 0 collisions.

  derived_table: {
    sql:
      WITH f AS (
        SELECT
          CAST(fid AS STRING) AS fid,
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
      s AS (
        SELECT name_slug AS slug, 'Franchise Name' AS slug_source, fid, franchise_name
        FROM f
        WHERE name_slug IS NOT NULL AND name_slug != ''
        UNION ALL
        SELECT url_slug AS slug, 'FIM Website URL' AS slug_source, fid, franchise_name
        FROM f
        WHERE url_slug IS NOT NULL
      )
      SELECT
        slug,
        MIN(fid) AS fid,
        MIN(franchise_name) AS franchise_name,
        STRING_AGG(DISTINCT slug_source, ' + ' ORDER BY slug_source) AS slug_source,
        COUNT(DISTINCT fid) AS fid_count
      FROM s
      GROUP BY slug
    ;;
  }

  # -------------------------------------------------
  #                   PRIMARY KEY
  # -------------------------------------------------

  dimension: slug {
    primary_key: yes
    label: "Location Slug"
    description: "Website location slug, the path segment after /locations/ (e.g. carrollton-tx)."
    type: string
    sql: ${TABLE}.slug ;;
  }

  # -------------------------------------------------
  #                   DIMENSIONS
  # -------------------------------------------------

  dimension: fid {
    label: "FID"
    description: "FIM franchise ID that owns this slug."
    type: string
    sql: ${TABLE}.fid ;;
  }

  dimension: franchise_name {
    hidden: yes
    label: "Franchise Name"
    description: "FIM franchise name. Join key to etl_knack_franchises."
    type: string
    sql: ${TABLE}.franchise_name ;;
  }

  dimension: slug_source {
    label: "Slug Source"
    description: "Where the slug came from: Franchise Name, FIM Website URL, or both."
    type: string
    sql: ${TABLE}.slug_source ;;
  }

  dimension: fid_count {
    hidden: yes
    label: "FID #"
    description: "Distinct franchises claiming this slug. Should always be 1."
    type: number
    sql: ${TABLE}.fid_count ;;
  }

  dimension: has_collision {
    label: "Has Collision"
    description: "TRUE when more than one operating franchise claims this slug."
    type: yesno
    sql: ${TABLE}.fid_count > 1 ;;
  }

  # -------------------------------------------------
  #                ALL-TIME MEASURES
  # -------------------------------------------------

  measure: slug_count {
    label: "Slugs #"
    group_label: "⏳ | Slugs"
    description: "Count of location slugs."
    type: count
  }

  measure: location_count {
    label: "Locations #"
    group_label: "⏳ | Slugs"
    description: "Count of distinct franchises with at least one slug."
    type: count_distinct
    sql: ${fid} ;;
  }

  measure: collision_count {
    label: "Collisions #"
    group_label: "⏳ | Slugs"
    description: "Slugs claimed by more than one operating franchise. Should be 0."
    type: count
    filters: [has_collision: "Yes"]
  }
}
