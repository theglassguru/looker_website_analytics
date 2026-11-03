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
# Explore names that differ from view names set view_name.

# --- Scorecard: whole site, one row per day ---

explore: website_overview {
  view_name: website_network_daily
  hidden: no
  label: "Website - Overview"
  description: "Whole-site scorecard by day: Google search, sessions, page views, daily visitors."
  persist_with: website_analytics_datagroup

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

# --- Scorecard: by location, one row per location per day ---

explore: website_locations {
  view_name: website_location_daily
  hidden: no
  label: "Website - Locations"
  description: "Location scorecard: search impressions, clicks, and page views for every location's pages."
  persist_with: website_analytics_datagroup

  join: etl_knack_franchises {
    type: left_outer
    relationship: many_to_one
    sql_on: ${website_location_daily.franchise_name} = ${etl_knack_franchises.franchise_name} ;;
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

# --- GA4: traffic by channel ---

explore: ga4_channels {
  hidden: no
  label: "GA4 - Channels"
  description: "Site visits and engagement by channel (All Locations property)."
  persist_with: website_ga4_datagroup

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

# --- GA4: traffic by source / medium ---

explore: ga4_sources {
  hidden: no
  label: "GA4 - Sources"
  description: "Site visits and engagement by source and medium, lowercased (All Locations property)."
  persist_with: website_ga4_datagroup

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

# --- GA4: pages and locations ---

explore: ga4_pages {
  hidden: no
  label: "GA4 - Pages"
  description: "Page views and engagement by page and location (All Locations property)."
  persist_with: website_ga4_datagroup

  join: etl_knack_franchises {
    type: left_outer
    relationship: many_to_one
    sql_on: ${ga4_pages.franchise_name} = ${etl_knack_franchises.franchise_name} ;;
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
