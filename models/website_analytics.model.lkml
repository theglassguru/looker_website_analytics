connection: "fivetran"

label: "MKTG | Website [HQ]"

include: "/models/website_analytics.explore.lkml"
include: "/models/_datagroups.lkml"

persist_with: website_analytics_datagroup
