# -------------------------------------------------
#                    DATAGROUPS
# -------------------------------------------------
#
# Fivetran stamps every row with _fivetran_synced. A new max value means
# a sync landed, which invalidates cache and rebuilds dependent PDTs.
#
# website_ga4_datagroup       - GA4 base views and explores
# website_gsc_datagroup       - Search Console base views and explores
# website_analytics_datagroup - anything built from BOTH sources
#                               (network + location scorecard PDTs)

datagroup: website_ga4_datagroup {
  sql_trigger: SELECT MAX(_fivetran_synced) FROM `fivetran-the-glass-guru-wareho.google_analytics_4.pages_path_report` ;;
  max_cache_age: "24 hours"
}

datagroup: website_gsc_datagroup {
  sql_trigger: SELECT MAX(_fivetran_synced) FROM `fivetran-the-glass-guru-wareho.google_search_console.page_report` ;;
  max_cache_age: "24 hours"
}

datagroup: website_analytics_datagroup {
  sql_trigger:
    SELECT CONCAT(
      CAST((SELECT MAX(_fivetran_synced) FROM `fivetran-the-glass-guru-wareho.google_analytics_4.pages_path_report`) AS STRING),
      '|',
      CAST((SELECT MAX(_fivetran_synced) FROM `fivetran-the-glass-guru-wareho.google_search_console.page_report`) AS STRING)
    ) ;;
  max_cache_age: "24 hours"
}
