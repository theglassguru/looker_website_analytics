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

# --- Search Console: pages and locations ---

explore: search_console_pages {
  view_name: gsc_pages
  hidden: no
  label: "Search Console - Pages"
  description: "Google search by page and location (attributed, ~53% of site clicks). Defaults to web search."
  persist_with: website_gsc_datagroup

  always_filter: {
    filters: [gsc_pages.search_type: "web"]
  }

  join: etl_knack_franchises {
    type: left_outer
    relationship: many_to_one
    sql_on: ${gsc_pages.franchise_name} = ${etl_knack_franchises.franchise_name} ;;
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

# --- Search Console: search terms ---

explore: search_console_queries {
  view_name: gsc_queries
  hidden: no
  label: "Search Console - Search Terms"
  description: "Google search by search term, page, and location (attributed, ~53% of site clicks). Defaults to web search."
  persist_with: website_gsc_datagroup

  always_filter: {
    filters: [gsc_queries.search_type: "web"]
  }

  join: etl_knack_franchises {
    type: left_outer
    relationship: many_to_one
    sql_on: ${gsc_queries.franchise_name} = ${etl_knack_franchises.franchise_name} ;;
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
