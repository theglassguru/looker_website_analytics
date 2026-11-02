# -------------------------------------------------
#                    INCLUDES
# -------------------------------------------------

include: "/views/**/*.view.lkml"
include: "/models/_datagroups.lkml"
include: "//knack_fim/views/etl_knack_franchises.view.lkml"
include: "//timeframe_filters/**/*.view.lkml"

# -------------------------------------------------
#                    EXPLORES
# -------------------------------------------------
#
# Every explore cross-joins timeframe_suggestions + timeframe_filters
# for CP / PP dynamic measures. All data is as of yesterday.
# Explore names differ from view names, so each sets view_name.

# --- Search Console: site totals ---

explore: search_console_site {
  view_name: gsc_site
  hidden: no
  label: "Search Console - Site"
  description: "Complete site-wide Google search totals for www.theglassguru.com. Defaults to web search."
  persist_with: website_gsc_datagroup

  always_filter: {
    filters: [gsc_site.search_type: "web"]
  }

  join: timeframe_suggestions {
    type: cross
    relationship: one_to_one
  }

  join: timeframe_filters {
    view_label: "🔻 | Timeframe Filter"
    type: cross
    relationship: one_to_one
  }
}

# --- Location slug map (admin / validation) ---

explore: location_slugs {
  hidden: yes
  label: "Location Slugs"
  description: "Website slug to FIM franchise map. Check Collisions # = 0."

  join: etl_knack_franchises {
    type: left_outer
    relationship: many_to_one
    sql_on: ${location_slugs.franchise_name} = ${etl_knack_franchises.franchise_name} ;;
  }
}
