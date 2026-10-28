library(ggplot2)
library(grid)
library(png)

# -------------------------------------------------------------
# Read Badges & Pre-create RasterGrobs
# -------------------------------------------------------------
# Plant photo badges
badge_ran <- rasterGrob(readPNG("images/badges/story_badge_ranunculus.png"), interpolate = TRUE)
badge_ach <- rasterGrob(readPNG("images/badges/story_badge_achillea_flower.png"), interpolate = TRUE)
badge_suc <- rasterGrob(readPNG("images/badges/story_badge_succisa_flower.png"), interpolate = TRUE)
badge_san <- rasterGrob(readPNG("images/badges/story_badge_sanguisorba.png"), interpolate = TRUE)
badge_cen <- rasterGrob(readPNG("images/badges/story_badge_centaurea.png"), interpolate = TRUE)

# Pollinator photo badges
badge_hal <- rasterGrob(readPNG("images/badges/story_badge_halictus.png"), interpolate = TRUE)
badge_eri <- rasterGrob(readPNG("images/badges/story_badge_eristalis.png"), interpolate = TRUE)
badge_but <- rasterGrob(readPNG("images/badges/story_badge_butterfly.png"), interpolate = TRUE)
badge_zyg <- rasterGrob(readPNG("images/badges/story_badge_zygaena.png"), interpolate = TRUE)
badge_syr <- rasterGrob(readPNG("images/badges/story_badge_syrphid.png"), interpolate = TRUE)

# Clean, borderless presentation theme
clean_theme <- theme_void() +
  theme(
    plot.background = element_rect(fill = "#FFFFFF", color = NA),
    panel.background = element_rect(fill = "#FFFFFF", color = NA),
    plot.margin = margin(8, 12, 8, 12)
  )

# X positions: 1.0, 3.1, 5.2, 7.3, 9.4
y_plant <- 3.75
y_poll  <- 1.45

# Interaction edges
edges <- data.frame(
  p_name  = c("Halictus", "Halictus", "Eristalis", "Eristalis", "Eristalis", "Eristalis", 
              "Butterfly", "Butterfly", "Butterfly", "Zygaena", "Zygaena", "Zygaena", 
              "Syrphid", "Syrphid", "Syrphid"),
  pl_name = c("Ranunculus", "Achillea", "Ranunculus", "Achillea", "Succisa", "Centaurea",
              "Achillea", "Succisa", "Sanguisorba", "Succisa", "Sanguisorba", "Centaurea",
              "Succisa", "Sanguisorba", "Centaurea"),
  x1 = c(1.0, 1.0, 3.1, 3.1, 3.1, 3.1, 5.2, 5.2, 5.2, 7.3, 7.3, 7.3, 9.4, 9.4, 9.4),
  y1 = rep(y_poll, 15),
  x2 = c(1.0, 3.1, 1.0, 3.1, 5.2, 9.4, 3.1, 5.2, 7.3, 5.2, 7.3, 9.4, 5.2, 7.3, 9.4),
  y2 = rep(y_plant, 15),
  weight = c(2.2, 2.0, 2.5, 4.8, 5.0, 3.0, 2.2, 3.8, 2.6, 3.0, 4.2, 2.5, 2.6, 2.2, 3.6),
  is_succisa = c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE, TRUE, FALSE, FALSE),
  is_bridge  = c(FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
)

# Build plot function
create_network_plot <- function() {
  p <- ggplot() +
    # -------------------------------------------------------------
    # Bipartite Interaction Edges
    # -------------------------------------------------------------
    # General edges (slate grey)
    geom_segment(data = subset(edges, !is_succisa),
                 aes(x = x1, y = y1, xend = x2, yend = y2, linewidth = weight),
                 color = "#94A3B8", alpha = 0.55, lineend = "round") +
    
    # Edges connected to Succisa pratensis (highlighted / richer tone)
    geom_segment(data = subset(edges, is_succisa),
                 aes(x = x1, y = y1, xend = x2, yend = y2, linewidth = weight),
                 color = "#6D28D9", alpha = 0.75, lineend = "round") +
    
    # Golden highlight on the core Achillea - Eristalis - Succisa sharing bridge
    geom_segment(data = subset(edges, is_bridge),
                 aes(x = x1, y = y1, xend = x2, yend = y2),
                 color = "#F59E0B", linewidth = 5.2, alpha = 0.85, lineend = "round") +
    geom_segment(data = subset(edges, is_bridge),
                 aes(x = x1, y = y1, xend = x2, yend = y2),
                 color = "#FFFBEB", linewidth = 2.0, alpha = 0.95, lineend = "round") +
    
    scale_linewidth_continuous(range = c(1.8, 4.6), guide = "none") +

    # -------------------------------------------------------------
    # Top Row: Plant Nodes (y = y_plant = 3.75)
    # -------------------------------------------------------------
    # 1. Ranunculus acris
    annotate("point", x = 1.0, y = y_plant, size = 28, color = "#40695B") +
    annotate("point", x = 1.0, y = y_plant, size = 25, color = "white") +
    annotation_custom(badge_ran, xmin = 1.0 - 0.58, xmax = 1.0 + 0.58, ymin = y_plant - 0.58, ymax = y_plant + 0.58) +

    # 2. Achillea ptarmica
    annotate("point", x = 3.1, y = y_plant, size = 32, color = "#FDE68A", alpha = 0.85) +
    annotate("point", x = 3.1, y = y_plant, size = 28, color = "#D97706") +
    annotate("point", x = 3.1, y = y_plant, size = 25, color = "white") +
    annotation_custom(badge_ach, xmin = 3.1 - 0.58, xmax = 3.1 + 0.58, ymin = y_plant - 0.58, ymax = y_plant + 0.58) +

    # 3. Succisa pratensis (Central Hub)
    annotate("point", x = 5.2, y = y_plant, size = 36, color = "#EDE9FE", alpha = 0.95) +
    annotate("point", x = 5.2, y = y_plant, size = 30, color = "#6D28D9") +
    annotate("point", x = 5.2, y = y_plant, size = 26, color = "white") +
    annotation_custom(badge_suc, xmin = 5.2 - 0.63, xmax = 5.2 + 0.63, ymin = y_plant - 0.63, ymax = y_plant + 0.63) +

    # 4. Sanguisorba officinalis
    annotate("point", x = 7.3, y = y_plant, size = 28, color = "#40695B") +
    annotate("point", x = 7.3, y = y_plant, size = 25, color = "white") +
    annotation_custom(badge_san, xmin = 7.3 - 0.58, xmax = 7.3 + 0.58, ymin = y_plant - 0.58, ymax = y_plant + 0.58) +

    # 5. Centaurea jacea
    annotate("point", x = 9.4, y = y_plant, size = 28, color = "#40695B") +
    annotate("point", x = 9.4, y = y_plant, size = 25, color = "white") +
    annotation_custom(badge_cen, xmin = 9.4 - 0.58, xmax = 9.4 + 0.58, ymin = y_plant - 0.58, ymax = y_plant + 0.58) +

    # -------------------------------------------------------------
    # Bottom Row: Pollinator Nodes (y = y_poll = 1.45)
    # -------------------------------------------------------------
    # 1. Halictus bee
    annotate("point", x = 1.0, y = y_poll, size = 27, color = "#F8765C") +
    annotate("point", x = 1.0, y = y_poll, size = 24, color = "white") +
    annotation_custom(badge_hal, xmin = 1.0 - 0.57, xmax = 1.0 + 0.57, ymin = y_poll - 0.57, ymax = y_poll + 0.57) +

    # 2. Eristalis interruptus
    annotate("point", x = 3.1, y = y_poll, size = 35, color = "#FEF3C7", alpha = 0.95) +
    annotate("point", x = 3.1, y = y_poll, size = 30, color = "#D97706") +
    annotate("point", x = 3.1, y = y_poll, size = 26, color = "white") +
    annotation_custom(badge_eri, xmin = 3.1 - 0.63, xmax = 3.1 + 0.63, ymin = y_poll - 0.63, ymax = y_poll + 0.63) +

    # 3. Meadow Butterfly
    annotate("point", x = 5.2, y = y_poll, size = 28, color = "#F8765C") +
    annotate("point", x = 5.2, y = y_poll, size = 25, color = "white") +
    annotation_custom(badge_but, xmin = 5.2 - 0.59, xmax = 5.2 + 0.59, ymin = y_poll - 0.59, ymax = y_poll + 0.59) +

    # 4. Zygaena burnet moth
    annotate("point", x = 7.3, y = y_poll, size = 28, color = "#F8765C") +
    annotate("point", x = 7.3, y = y_poll, size = 25, color = "white") +
    annotation_custom(badge_zyg, xmin = 7.3 - 0.59, xmax = 7.3 + 0.59, ymin = y_poll - 0.59, ymax = y_poll + 0.59) +

    # 5. Syrphid hoverflies
    annotate("point", x = 9.4, y = y_poll, size = 27, color = "#F8765C") +
    annotate("point", x = 9.4, y = y_poll, size = 24, color = "white") +
    annotation_custom(badge_syr, xmin = 9.4 - 0.57, xmax = 9.4 + 0.57, ymin = y_poll - 0.57, ymax = y_poll + 0.57) +

    coord_fixed(xlim = c(0.2, 10.2), ylim = c(0.70, 4.50)) +
    clean_theme

  return(p)
}

# Generate and save high-resolution figure
p_net <- create_network_plot()

out_file_1 <- "images/not_in_vacuum_network.png"
out_file_2 <- "docs/images/not_in_vacuum_network.png"

ggsave(out_file_1, p_net, width = 11.2, height = 5.7, dpi = 300)
ggsave(out_file_2, p_net, width = 11.2, height = 5.7, dpi = 300)

cat(sprintf("Generated %s and %s successfully!\n", out_file_1, out_file_2))
