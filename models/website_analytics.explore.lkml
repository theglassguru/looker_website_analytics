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
# Explores are added here as each view is built and validated.
# Every explore cross-joins timeframe_suggestions + timeframe_filters
# for CP / PP dynamic measures.
