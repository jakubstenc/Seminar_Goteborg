# Conceptual diagram of Pollen Presentation Theory (Harder & Thomson 1989)
# Diminishing returns of pollen removal: Dose vs. Dump

suppressMessages({
  library(ggplot2)
  library(dplyr)
})

# Color palette matching Seminar Göteborg presentation theme
green      <- "#2D5A4C" # Deep elegant forest green
purple     <- "#4A157F" # Deep royal purple for Dosing
magenta    <- "#AF2769" # Rich raspberry magenta for Dumping
slate      <- "#64748B"
dark       <- "#1E293B"
grid_color <- "#F1F5F9"
bg_curve   <- "#EDF5F1"

# Curve data
x <- seq(0, 100, length.out = 400)
# Saturating curve: y = 100 * (x / (x + 28))
y <- 100 * (x / (x + 28))
df_curve <- tibble(removed = x, delivered = y)

dose_x <- 20
dose_y <- 100 * (dose_x / (dose_x + 28)) # 41.67

dump_x <- 100
dump_y <- 100 * (dump_x / (dump_x + 28)) # 78.12

df_dose_pt <- tibble(x = dose_x, y = dose_y)
df_dump_pt <- tibble(x = dump_x, y = dump_y)

p <- ggplot(df_curve, aes(x = removed, y = delivered)) +
  # Soft area under curve
  geom_area(fill = bg_curve, alpha = 0.85) +
  
  # Main saturating curve
  geom_line(color = green, linewidth = 3) +
  
  # --- Dosing projection lines & point ---
  annotate("segment", x = dose_x, y = 0, xend = dose_x, yend = dose_y, 
           linetype = "dashed", color = purple, linewidth = 0.85, alpha = 0.8) +
  annotate("segment", x = 0, y = dose_y, xend = dose_x, yend = dose_y, 
           linetype = "dashed", color = purple, linewidth = 0.85, alpha = 0.8) +
  geom_point(data = df_dose_pt, aes(x = x, y = y), 
             color = purple, fill = "#FFFFFF", shape = 21, stroke = 2.8, size = 6.2) +
  
  # --- Dumping projection lines & point ---
  annotate("segment", x = dump_x, y = 0, xend = dump_x, yend = dump_y, 
           linetype = "dashed", color = magenta, linewidth = 0.85, alpha = 0.8) +
  annotate("segment", x = 0, y = dump_y, xend = dump_x, yend = dump_y, 
           linetype = "dashed", color = magenta, linewidth = 0.85, alpha = 0.8) +
  geom_point(data = df_dump_pt, aes(x = x, y = y), 
             color = magenta, fill = "#FFFFFF", shape = 21, stroke = 2.8, size = 6.2) +
  
  # --- Callout 1: DOSING (Top-Left, left-aligned, clear of dashed line) ---
  annotate("label", x = 3, y = 94, 
           label = "DOSING (Dispensing)\n• Steep slope: high efficiency per grain\n• Pollen saved for future visits", 
           color = purple, fontface = "bold", size = 4.2, hjust = 0, vjust = 0.5,
           fill = "#FAF8FD", linewidth = 0.5, lineheight = 1.3) +
  annotate("segment", x = dose_x, y = 80, xend = dose_x, yend = dose_y + 4.5,
           arrow = arrow(length = unit(0.022, "npc"), type = "closed"), 
           color = purple, linewidth = 0.9) +

  # --- Callout 2: DUMPING (Top-Right, right-aligned, clear of curve) ---
  annotate("label", x = 104, y = 100, 
           label = "DUMPING (All at once)\n• Flat plateau: severe diminishing returns\n• Most pollen groomed away, eaten, or lost", 
           color = magenta, fontface = "bold", size = 4.2, hjust = 1, vjust = 0.5,
           fill = "#FDF7FA", linewidth = 0.5, lineheight = 1.3) +
  annotate("segment", x = dump_x, y = 87.5, xend = dump_x, yend = dump_y + 4.5,
           arrow = arrow(length = unit(0.022, "npc"), type = "closed"), 
           color = magenta, linewidth = 0.9) +

  # --- Labels & Scales ---
  labs(
    title = "Per-visit pollen removal curve",
    subtitle = "Harder & Thomson (1989) American Naturalist",
    x = "Pollen removed in a single visit",
    y = "Pollen deposited on stigmas"
  ) +
  scale_x_continuous(
    breaks = c(0, dose_x, dump_x), 
    labels = c("0", "Small package\n(dosed)", "All pollen\n(dumped)"),
    limits = c(0, 106),
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    breaks = c(0, dose_y, dump_y),
    labels = c("0", "", ""),
    limits = c(0, 114),
    expand = c(0, 0)
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(color = dark, face = "bold", size = 20, margin = margin(b = 4)),
    plot.subtitle = element_text(color = slate, size = 13.5, margin = margin(b = 16)),
    axis.title.x = element_text(color = dark, face = "bold", size = 14, margin = margin(t = 12)),
    axis.title.y = element_text(color = dark, face = "bold", size = 14, margin = margin(r = 14)),
    axis.text.x = element_text(color = dark, size = 12.5, lineheight = 1.05),
    axis.text.y = element_text(color = dark, size = 12),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    plot.margin = margin(16, 28, 16, 20)
  )

ggsave("images/pollen_presentation_theory.png", p, width = 9.4, height = 5.2, dpi = 300, bg = "white")
ggsave("docs/images/pollen_presentation_theory.png", p, width = 9.4, height = 5.2, dpi = 300, bg = "white")
ggsave("images/pollen_presentation_theory_single.png", p, width = 9.4, height = 5.2, dpi = 300, bg = "white")
ggsave("docs/images/pollen_presentation_theory_single.png", p, width = 9.4, height = 5.2, dpi = 300, bg = "white")
cat("Figure generated cleanly.\n")

