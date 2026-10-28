library(ggplot2)
library(grid)
library(png)

# Plant photo badges
badge_ach <- rasterGrob(readPNG("images/badges/story_badge_achillea_flower.png"), interpolate = TRUE)
badge_suc <- rasterGrob(readPNG("images/badges/story_badge_succisa_flower.png"), interpolate = TRUE)
badge_cen <- rasterGrob(readPNG("images/badges/story_badge_centaurea.png"), interpolate = TRUE)
badge_ran <- rasterGrob(readPNG("images/badges/story_badge_ranunculus.png"), interpolate = TRUE)
badge_san <- rasterGrob(readPNG("images/badges/story_badge_sanguisorba.png"), interpolate = TRUE)

# Pollinator photo badges
badge_eri <- rasterGrob(readPNG("images/badges/story_badge_eristalis.png"), interpolate = TRUE)
badge_but <- rasterGrob(readPNG("images/badges/story_badge_butterfly.png"), interpolate = TRUE)
badge_zyg <- rasterGrob(readPNG("images/badges/story_badge_zygaena.png"), interpolate = TRUE)

# Cutouts
k_ran <- rasterGrob(readPNG("images/kytky/Ran_acr.png"), interpolate = TRUE)
k_ach <- rasterGrob(readPNG("images/kytky/Ach_pta.png"), interpolate = TRUE)

clean_theme <- theme_void() +
  theme(
    plot.background = element_rect(fill = "#FFFFFF", color = NA),
    panel.background = element_rect(fill = "#FFFFFF", color = NA),
    plot.margin = margin(10, 10, 10, 10)
  )

# Nodes setup
# Plants: Ranunculus (1.0), Achillea (2.9), Succisa (5.1), Sanguisorba (7.3), Centaurea (9.2)
# Pollinators: Halictus (1.1), Eristalis (3.1), Butterfly (5.3), Zygaena (7.5), Syrphid (9.1)

edges <- data.frame(
  p = c("eristalis", "eristalis", "butterfly", "butterfly", "butterfly", "zygaena", "halictus", "halictus", "eristalis", "eristalis", "syrphid", "syrphid"),
  pl = c("achillea", "succisa", "succisa", "achillea", "sanguisorba", "sanguisorba", "ranunculus", "achillea", "ranunculus", "centaurea", "centaurea", "succisa"),
  x1 = c(3.1, 3.1, 5.3, 5.3, 5.3, 7.5, 1.1, 1.1, 3.1, 3.1, 9.1, 9.1),
  y1 = c(1.35, 1.35, 1.35, 1.35, 1.35, 1.35, 1.35, 1.35, 1.35, 1.35, 1.35, 1.35),
  x2 = c(2.9, 5.1, 5.1, 2.9, 7.3, 7.3, 1.0, 2.9, 1.0, 9.2, 9.2, 5.1),
  y2 = c(3.70, 3.70, 3.70, 3.70, 3.70, 3.70, 3.70, 3.70, 3.70, 3.70, 3.70, 3.70),
  weight = c(4.2, 4.5, 3.5, 2.0, 2.2, 3.8, 2.5, 2.0, 2.8, 3.2, 2.4, 2.2)
)

# Test 1: Clean circular badges with elegant banners
p1 <- ggplot() +
  # Background soft cards or bands
  annotate("rect", xmin = 0.2, xmax = 10.0, ymin = 3.1, ymax = 5.1, fill = "#F8FAF9", color = "#E2E8F0", linewidth = 0.5, linetype = "dashed", alpha = 0.6) +
  annotate("rect", xmin = 0.2, xmax = 10.0, ymin = 0.1, ymax = 1.95, fill = "#FDF8F6", color = "#E2E8F0", linewidth = 0.5, linetype = "dashed", alpha = 0.6) +

  # Top banner: Co-flowering neighbours
  annotate("label", x = 5.1, y = 4.85, 
           label = "   CO-FLOWERING NEIGHBOURS   •   Competing for visits & exchanging heterospecific pollen   ",
           fill = "#40695B", color = "#FFFFFF", fontface = "bold", size = 3.6, label.r = unit(0.4, "lines"), label.padding = unit(0.4, "lines")) +

  # Bottom banner: Diverse flower visitors
  annotate("label", x = 5.1, y = 0.32, 
           label = "   DIVERSE FLOWER VISITORS   •   Carrying mixed pollen loads with varying constancy   ",
           fill = "#C4472F", color = "#FFFFFF", fontface = "bold", size = 3.6, label.r = unit(0.4, "lines"), label.padding = unit(0.4, "lines")) +

  # Center callout: Community context
  annotate("label", x = 5.1, y = 2.52, 
           label = "  COMMUNITY CONTEXT : Bipartite interaction network linking dozens of species  ",
           fill = "#FFFFFF", color = "#3B0F70", fontface = "bold", size = 3.4, 
           label.r = unit(0.3, "lines"), label.padding = unit(0.3, "lines"),
           linewidth = 0.8) +

  # Network edges
  geom_segment(data = edges, aes(x = x1, y = y1, xend = x2, yend = y2, linewidth = weight),
               color = "#64748B", alpha = 0.55, lineend = "round") +
  scale_linewidth_continuous(range = c(1.5, 4.2), guide = "none") +

  # --- Plant Nodes (y = 3.70) ---
  # Ranunculus
  annotate("point", x = 1.0, y = 3.70, size = 26, color = "#40695B") +
  annotation_custom(badge_ran, xmin = 1.0 - 0.58, xmax = 1.0 + 0.58, ymin = 3.70 - 0.58, ymax = 3.70 + 0.58) +
  annotate("text", x = 1.0, y = 4.38, label = "Ranunculus acris", fontface = "bold.italic", size = 3.3, color = "#1E293B") +

  # Achillea
  annotate("point", x = 2.9, y = 3.70, size = 26, color = "#40695B") +
  annotation_custom(badge_ach, xmin = 2.9 - 0.58, xmax = 2.9 + 0.58, ymin = 3.70 - 0.58, ymax = 3.70 + 0.58) +
  annotate("text", x = 2.9, y = 4.38, label = "Achillea ptarmica", fontface = "bold.italic", size = 3.3, color = "#1E293B") +

  # Succisa (Focal Hub)
  annotate("point", x = 5.1, y = 3.70, size = 29, color = "#3B0F70") +
  annotation_custom(badge_suc, xmin = 5.1 - 0.62, xmax = 5.1 + 0.62, ymin = 3.70 - 0.62, ymax = 3.70 + 0.62) +
  annotate("text", x = 5.1, y = 4.40, label = "Succisa pratensis", fontface = "bold.italic", size = 3.6, color = "#3B0F70") +

  # Sanguisorba
  annotate("point", x = 7.3, y = 3.70, size = 26, color = "#40695B") +
  annotation_custom(badge_san, xmin = 7.3 - 0.58, xmax = 7.3 + 0.58, ymin = 3.70 - 0.58, ymax = 3.70 + 0.58) +
  annotate("text", x = 7.3, y = 4.38, label = "Sanguisorba offic.", fontface = "bold.italic", size = 3.3, color = "#1E293B") +

  # Centaurea
  annotate("point", x = 9.2, y = 3.70, size = 26, color = "#40695B") +
  annotation_custom(badge_cen, xmin = 9.2 - 0.58, xmax = 9.2 + 0.58, ymin = 3.70 - 0.58, ymax = 3.70 + 0.58) +
  annotate("text", x = 9.2, y = 4.38, label = "Centaurea jacea", fontface = "bold.italic", size = 3.3, color = "#1E293B") +

  # --- Pollinator Nodes (y = 1.35) ---
  # Halictus bee
  annotate("point", x = 1.1, y = 1.35, size = 10, color = "#F8765C") +
  annotate("point", x = 1.1, y = 1.35, size = 5.5, color = "#FFFFFF") +
  annotate("text", x = 1.1, y = 0.72, label = "Halictus bee", fontface = "bold", size = 3.2, color = "#1E293B") +
  annotate("text", x = 1.1, y = 0.52, label = "(Solitary bee)", size = 2.6, color = "#64748B") +

  # Eristalis hoverfly
  annotate("point", x = 3.1, y = 1.35, size = 28, color = "#F59E0B") +
  annotation_custom(badge_eri, xmin = 3.1 - 0.60, xmax = 3.1 + 0.60, ymin = 1.35 - 0.60, ymax = 1.35 + 0.60) +
  annotate("text", x = 3.1, y = 0.72, label = "Eristalis interruptus", fontface = "bold.italic", size = 3.4, color = "#1E293B") +
  annotate("text", x = 3.1, y = 0.52, label = "Hoverfly (Abundant Generalist)", fontface = "bold", size = 2.6, color = "#C4472F") +

  # Butterfly
  annotate("point", x = 5.3, y = 1.35, size = 27, color = "#F8765C") +
  annotation_custom(badge_but, xmin = 5.3 - 0.58, xmax = 5.3 + 0.58, ymin = 1.35 - 0.58, ymax = 1.35 + 0.58) +
  annotate("text", x = 5.3, y = 0.72, label = "Meadow Butterfly", fontface = "bold", size = 3.2, color = "#1E293B") +
  annotate("text", x = 5.3, y = 0.52, label = "(Lycaenid / Satyrine)", fontface = "italic", size = 2.6, color = "#64748B") +

  # Zygaena
  annotate("point", x = 7.5, y = 1.35, size = 27, color = "#F8765C") +
  annotation_custom(badge_zyg, xmin = 7.5 - 0.58, xmax = 7.5 + 0.58, ymin = 1.35 - 0.58, ymax = 1.35 + 0.58) +
  annotate("text", x = 7.5, y = 0.72, label = "Zygaena burnet moth", fontface = "bold.italic", size = 3.2, color = "#1E293B") +
  annotate("text", x = 7.5, y = 0.52, label = "(Diurnal flower visitor)", size = 2.6, color = "#64748B") +

  # Syrphid fly
  annotate("point", x = 9.1, y = 1.35, size = 10, color = "#F8765C") +
  annotate("point", x = 9.1, y = 1.35, size = 5.5, color = "#FFFFFF") +
  annotate("text", x = 9.1, y = 0.72, label = "Syrphid fly sp.", fontface = "bold", size = 3.2, color = "#1E293B") +
  annotate("text", x = 9.1, y = 0.52, label = "(Small dipteran)", size = 2.6, color = "#64748B") +

  coord_fixed(xlim = c(0.1, 10.1), ylim = c(0.05, 5.25)) +
  clean_theme

ggsave("images/test_network_v1.png", p1, width = 10.5, height = 5.4, dpi = 300)
cat("Saved test_network_v1.png\n")
