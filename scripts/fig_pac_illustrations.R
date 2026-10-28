# Generate Conceptual & Mathematical Illustrations for PAC Review
# Author: Jakub Štenc et al. (2026)

suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
  library(dplyr)
  library(tidyr)
})

cat("=== Generating PAC Review Illustrations ===\n")

# Aesthetics
col_space <- "#40695B"  # Forest green
col_year  <- "#F8765C"  # Coral
col_time  <- "#3B0F70"  # Deep purple
ink       <- "#1E293B"
bg_card   <- "#F8FAFC"

theme_clean <- theme_void(base_size = 12, base_family = "sans") +
  theme(
    plot.background = element_rect(fill = "white", colour = NA),
    plot.title = element_text(face = "bold", colour = ink, size = 13.5, margin = margin(b = 4)),
    plot.subtitle = element_text(colour = "#64748B", size = 10.5, margin = margin(b = 8)),
    plot.margin = margin(12, 14, 12, 14)
  )

# ==============================================================================
# FIGURE 1: THE PAC MECHANISMS & ASYMMETRY
# ==============================================================================

# Panel A: The Apparent Competition Triad & 3 Biological Mechanisms
p1_a <- ggplot() +
  # Bounding box
  geom_rect(aes(xmin = 0, xmax = 10, ymin = 0, ymax = 10), fill = "#F8FAFC", colour = "#E2E8F0", linewidth = 0.8) +
  
  # Top Node: Shared Floral Visitor (Bumblebee / Pollinator Pool)
  geom_rect(aes(xmin = 3.5, xmax = 6.5, ymin = 7.7, ymax = 9.4), fill = "#FEF3C7", colour = "#D97706", linewidth = 1.2) +
  annotate("text", x = 5, y = 8.8, label = "SHARED FLORAL VISITOR (k)", fontface = "bold", size = 3.8, colour = "#92400E") +
  annotate("text", x = 5, y = 8.1, label = "e.g., Bombus lapidarius / Eristalis tenax", fontface = "italic", size = 3.1, colour = "#B45309") +
  
  # Bottom Left Node: Core Floral Bully j (Centaurea jacea)
  geom_rect(aes(xmin = 0.6, xmax = 4.2, ymin = 0.8, ymax = 3.2), fill = "#EDE9FE", colour = col_time, linewidth = 1.2) +
  annotate("text", x = 2.4, y = 2.6, label = "CORE BULLY (Plant j)", fontface = "bold", size = 3.8, colour = col_time) +
  annotate("text", x = 2.4, y = 1.9, label = "Centaurea jacea\n(Massive floral abundance & reward)", size = 3.0, colour = "#4C1D95", lineheight = 0.9) +
  annotate("text", x = 2.4, y = 1.1, label = "Diet Share: P(j|k) = 80%", fontface = "bold", size = 3.2, colour = col_time) +

  # Bottom Right Node: Subordinate Plant i (Lotus corniculatus)
  geom_rect(aes(xmin = 5.8, xmax = 9.4, ymin = 0.8, ymax = 3.2), fill = "#FFF1F2", colour = col_year, linewidth = 1.2) +
  annotate("text", x = 7.6, y = 2.6, label = "SUBORDINATE (Plant i)", fontface = "bold", size = 3.8, colour = col_year) +
  annotate("text", x = 7.6, y = 1.9, label = "Lotus corniculatus\n(Low floral density, specialized)", size = 3.0, colour = "#9F1239", lineheight = 0.9) +
  annotate("text", x = 7.6, y = 1.1, label = "Reliance: P(k|i) = 75%", fontface = "bold", size = 3.2, colour = col_year) +

  # Connecting Arrows & Mechanism Labels
  # Arrow 1: Foraging to Bully
  geom_segment(aes(x = 4.4, y = 7.6, xend = 2.8, yend = 3.3), 
               arrow = arrow(length = unit(0.28, "cm"), ends = "both"), linewidth = 1.5, colour = col_time) +
  annotate("label", x = 2.7, y = 5.6, label = "1. Pollinator Diversion\nBully captures 80% of foraging visits;\nstarves subordinate of visits", 
           fill = "white", colour = col_time, fontface = "bold", size = 3.0, label.size = 0.3) +

  # Arrow 2: Foraging to Subordinate
  geom_segment(aes(x = 5.6, y = 7.6, xend = 7.2, yend = 3.3), 
               arrow = arrow(length = unit(0.28, "cm"), ends = "both"), linewidth = 0.9, colour = col_year) +
  annotate("label", x = 7.3, y = 5.6, label = "2. Stigma Clogging (HPD)\nVisitor arrives carrying Centaurea pollen;\nforeign grains clog Lotus stigmas", 
           fill = "white", colour = col_year, fontface = "bold", size = 3.0, label.size = 0.3) +

  # Indirect Apparent Competition Horizontal Arrow
  geom_segment(aes(x = 4.3, y = 1.8, xend = 5.7, yend = 1.8), 
               arrow = arrow(length = unit(0.32, "cm"), type = "closed"), linewidth = 2.2, colour = "#DC2626") +
  annotate("text", x = 5.0, y = 2.2, label = "PAC(j → i)", fontface = "bold", size = 3.6, colour = "#DC2626") +
  
  labs(
    title = "A. The Apparent Competition Triad & 3 Biological Mechanisms",
    subtitle = "Shared pollinators mediate diversion, heterospecific pollen deposition (HPD), and pollen loss"
  ) +
  theme_clean

# Panel B: Asymmetry Visualized (Bully vs. Subordinate)
p1_b <- ggplot() +
  geom_rect(aes(xmin = 0, xmax = 10, ymin = 0, ymax = 10), fill = "#F8FAFC", colour = "#E2E8F0", linewidth = 0.8) +
  
  # Bully Circle
  geom_point(aes(x = 2.5, y = 6.2), size = 34, colour = col_time, fill = "#EDE9FE", shape = 21, stroke = 2.5) +
  annotate("text", x = 2.5, y = 6.6, label = "Centaurea\njacea", fontface = "bold.italic", size = 3.8, colour = col_time) +
  annotate("text", x = 2.5, y = 5.4, label = "CORE BULLY\nAbundance = 34.2", fontface = "bold", size = 2.9, colour = "#4C1D95") +
  
  # Subordinate Circle
  geom_point(aes(x = 7.5, y = 6.2), size = 22, colour = col_year, fill = "#FFF1F2", shape = 21, stroke = 2.2) +
  annotate("text", x = 7.5, y = 6.5, label = "Lotus\ncorniculatus", fontface = "bold.italic", size = 3.6, colour = col_year) +
  annotate("text", x = 7.5, y = 5.5, label = "SUBORDINATE\nAbundance = 4.2", fontface = "bold", size = 2.8, colour = "#9F1239") +

  # Directed Arrow: Bully -> Subordinate (Massive PAC)
  geom_curve(aes(x = 3.5, y = 7.3, xend = 6.6, yend = 7.3), 
             curvature = -0.32, arrow = arrow(length = unit(0.35, "cm"), type = "closed"), 
             linewidth = 3.2, colour = "#DC2626") +
  annotate("label", x = 5.0, y = 8.8, 
           label = "PAC(Lotus ← Centaurea) = 0.60\nHeavy competitive suppression\n(Foreign pollen + visit diversion)", 
           fill = "#FEF2F2", colour = "#991B1B", fontface = "bold", size = 3.2, label.size = 0.4) +

  # Directed Arrow: Subordinate -> Bully (Negligible PAC)
  geom_curve(aes(x = 6.6, y = 5.1, xend = 3.5, yend = 5.1), 
             curvature = -0.32, arrow = arrow(length = unit(0.22, "cm"), type = "closed"), 
             linewidth = 0.8, linetype = "dashed", colour = "#94A3B8") +
  annotate("label", x = 5.0, y = 3.6, 
           label = "PAC(Centaurea ← Lotus) = 0.008\nNear-zero reciprocal impact\n(Bully ignores subordinate)", 
           fill = "white", colour = "#64748B", fontface = "italic", size = 3.1, label.size = 0.3) +

  # Bottom takeaway box
  geom_rect(aes(xmin = 0.6, xmax = 9.4, ymin = 0.6, ymax = 2.2), fill = "white", colour = "#CBD5E1", linewidth = 0.6) +
  annotate("text", x = 5.0, y = 1.4, 
           label = "KEY INSIGHT: Symmetrical overlap indices (Pianka, Jaccard) report a single scalar (e.g. 0.45),\nmasking the fact that one species dominates while the other is suppressed.\nPAC mathematically resolves this directed power imbalance.",
           fontface = "bold", size = 3.0, colour = ink, lineheight = 1.1) +

  labs(
    title = "B. Mathematical Asymmetry: Bully vs. Subordinate",
    subtitle = "PAC is directed (PAC_ij ≠ PAC_ji): isolating dominance hierarchies in mutualistic webs"
  ) +
  theme_clean

# Combine Figure 1
fig1_comb <- p1_a / p1_b + plot_layout(heights = c(1, 1))
dir.create("images", showWarnings = FALSE)
ggsave("images/pac_concept_mechanisms.png", fig1_comb, width = 11.5, height = 11.0, dpi = 240)
cat("Saved images/pac_concept_mechanisms.png successfully!\n")


# ==============================================================================
# FIGURE 2: STEP-BY-STEP TOY MATRIX WALKTHROUGH
# ==============================================================================

# Let's create a visual heat-coded diagram of matrix calculations
# Matrix A: Raw Counts
df_raw_m <- data.frame(
  Plant = rep(c("Centaurea (Bully)", "Lotus (Subordinate)", "Daucus (Umbellifer)"), each = 2),
  Visitor = rep(c("Bombus (Bee)", "Eristalis (Fly)"), times = 3),
  Count = c(80, 20, 15, 5, 5, 75)
)

p2_raw <- ggplot(df_raw_m, aes(x = Visitor, y = factor(Plant, levels = rev(c("Centaurea (Bully)", "Lotus (Subordinate)", "Daucus (Umbellifer)"))), fill = Count)) +
  geom_tile(colour = "white", linewidth = 1.2) +
  geom_text(aes(label = Count), fontface = "bold", size = 4.2, colour = ifelse(df_raw_m$Count > 50, "white", ink)) +
  scale_fill_gradient(low = "#EFF6FF", high = "#1D4ED8", guide = "none") +
  labs(
    title = "Step 1: Raw Bipartite Visits (A_ik)",
    subtitle = "Plant rows × Visitor columns",
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold", size = 11.5, colour = ink),
    plot.subtitle = element_text(size = 9.5, colour = "#64748B"),
    axis.text.x = element_text(face = "bold", colour = ink),
    axis.text.y = element_text(face = "bold", colour = ink)
  )

# Step 2: Row Normalized P(k|i)
df_row_m <- df_raw_m %>%
  group_by(Plant) %>%
  mutate(Prob = Count / sum(Count))

p2_row <- ggplot(df_row_m, aes(x = Visitor, y = factor(Plant, levels = rev(c("Centaurea (Bully)", "Lotus (Subordinate)", "Daucus (Umbellifer)"))), fill = Prob)) +
  geom_tile(colour = "white", linewidth = 1.2) +
  geom_text(aes(label = sprintf("%.2f", Prob)), fontface = "bold", size = 4.2, colour = ifelse(df_row_m$Prob > 0.6, "white", ink)) +
  scale_fill_gradient(low = "#F0FDF4", high = col_space, guide = "none") +
  labs(
    title = "Step 2: Plant Reliance P(k|i)",
    subtitle = "Row-normalized (Rows sum to 1.0)",
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold", size = 11.5, colour = ink),
    plot.subtitle = element_text(size = 9.5, colour = "#64748B"),
    axis.text.x = element_text(face = "bold", colour = ink),
    axis.text.y = element_blank()
  )

# Step 3: Column Normalized P(j|k)
df_col_m <- df_raw_m %>%
  group_by(Visitor) %>%
  mutate(Prob = Count / sum(Count))

p2_col <- ggplot(df_col_m, aes(x = Visitor, y = factor(Plant, levels = rev(c("Centaurea (Bully)", "Lotus (Subordinate)", "Daucus (Umbellifer)"))), fill = Prob)) +
  geom_tile(colour = "white", linewidth = 1.2) +
  geom_text(aes(label = sprintf("%.2f", Prob)), fontface = "bold", size = 4.2, colour = ifelse(df_col_m$Prob > 0.6, "white", ink)) +
  scale_fill_gradient(low = "#FFFBEB", high = "#D97706", guide = "none") +
  labs(
    title = "Step 3: Visitor Diet Share P(j|k)",
    subtitle = "Column-normalized (Cols sum to 1.0)",
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold", size = 11.5, colour = ink),
    plot.subtitle = element_text(size = 9.5, colour = "#64748B"),
    axis.text.x = element_text(face = "bold", colour = ink),
    axis.text.y = element_blank()
  )

# Step 4: Resulting 3x3 PAC Matrix
# Centaurea: 0.80*0.80 + 0.20*0.20 = 0.68 (self)
# Centaurea <- Lotus: 0.80*0.15 + 0.20*0.05 = 0.13
# Centaurea <- Daucus: 0.80*0.05 + 0.20*0.75 = 0.19
# Lotus <- Centaurea: 0.75*0.80 + 0.25*0.20 = 0.65
# Lotus <- Daucus: 0.75*0.05 + 0.25*0.75 = 0.225
# Daucus <- Centaurea: 0.0625*0.80 + 0.9375*0.20 = 0.2375
# Daucus <- Lotus: 0.0625*0.15 + 0.9375*0.05 = 0.056
df_pac_m <- data.frame(
  Focal_i = rep(c("Centaurea", "Lotus", "Daucus"), each = 3),
  Source_j = rep(c("Centaurea", "Lotus", "Daucus"), times = 3),
  PAC = c(0.68, 0.13, 0.19,
          0.65, 0.16, 0.23,
          0.24, 0.06, 0.71)
)

p2_pac <- ggplot(df_pac_m, aes(x = Source_j, y = factor(Focal_i, levels = rev(c("Centaurea", "Lotus", "Daucus"))), fill = PAC)) +
  geom_tile(colour = "white", linewidth = 1.2) +
  geom_text(aes(label = sprintf("%.2f", PAC)), fontface = "bold", size = 4.2, colour = ifelse(df_pac_m$PAC > 0.4, "white", ink)) +
  scale_fill_gradient(low = "#FEF2F2", high = "#DC2626", guide = "none") +
  labs(
    title = "Step 4: Final Directed PAC Matrix (PAC_ij)",
    subtitle = "Rows = Focal victim (i) | Columns = Affecting source (j)",
    x = "Source Species (j)", y = "Focal Species (i)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold", size = 12, colour = ink),
    plot.subtitle = element_text(size = 9.5, colour = "#64748B"),
    axis.text.x = element_text(face = "bold", colour = ink),
    axis.text.y = element_text(face = "bold", colour = ink)
  )

fig2_comb <- (p2_raw | p2_row | p2_col) / p2_pac + 
  plot_layout(heights = c(1, 1.15)) +
  plot_annotation(
    title = "Mathematical Computation of bipartite::PAC(web)",
    subtitle = "Multiplying plant reliance P(k|i) by visitor dominance P(j|k) produces the directed unipartite PAC network",
    theme = theme(
      plot.title = element_text(face = "bold", size = 14, colour = ink),
      plot.subtitle = element_text(size = 11, colour = "#64748B")
    )
  )

ggsave("images/pac_toy_matrix_walkthrough.png", fig2_comb, width = 12.0, height = 8.5, dpi = 240)
cat("Saved images/pac_toy_matrix_walkthrough.png successfully!\n")


# ==============================================================================
# FIGURE 3: DIURNAL RELIEF MECHANISM (TEMPORAL ESCAPE)
# ==============================================================================

# Time series comparison: Morning vs Midday visitation
hours_seq <- seq(8, 17, by = 0.2)
df_curves <- data.frame(
  Hour = rep(hours_seq, times = 2),
  Species = rep(c("Lotus corniculatus (Subordinate)", "Centaurea jacea (Core Bully)"), each = length(hours_seq)),
  Activity = c(
    dnorm(hours_seq, mean = 9.4, sd = 1.0) * 2.8,   # Lotus peaks early morning
    dnorm(hours_seq, mean = 13.0, sd = 1.8) * 3.6   # Centaurea broad midday plateau
  )
)

p3_curves <- ggplot(df_curves, aes(x = Hour, y = Activity, colour = Species, fill = Species)) +
  geom_area(position = "identity", alpha = 0.35) +
  geom_line(linewidth = 1.3) +
  annotate("rect", xmin = 8.2, xmax = 10.4, ymin = 0, ymax = 1.2, fill = "#FEF3C7", alpha = 0.45) +
  annotate("label", x = 9.3, y = 1.05, label = "Temporal Escape Window\n(Lotus forages cleanly before Centaurea rush)", 
           fill = "white", colour = "#92400E", fontface = "bold", size = 3.1) +
  annotate("rect", xmin = 11.0, xmax = 15.0, ymin = 0, ymax = 1.2, fill = "#EDE9FE", alpha = 0.35) +
  annotate("label", x = 13.0, y = 1.05, label = "Midday Core Rush Hour\n(Foreign pollen clouds on all shared insects)", 
           fill = "white", colour = "#4C1D95", fontface = "bold", size = 3.1) +
  scale_colour_manual(values = c("Lotus corniculatus (Subordinate)" = col_year, "Centaurea jacea (Core Bully)" = col_time)) +
  scale_fill_manual(values = c("Lotus corniculatus (Subordinate)" = col_year, "Centaurea jacea (Core Bully)" = col_time)) +
  scale_x_continuous(breaks = 8:17, labels = paste0(8:17, "h")) +
  labs(
    title = "A. Diurnal Visitation Dynamics across the Daily Clock",
    subtitle = "Subordinate plants decouple from core bullies through early morning floral presentation",
    x = "Diurnal Hour of Day", y = "Floral Visitation Density"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    legend.title = element_blank(),
    plot.title = element_text(face = "bold", size = 13, colour = ink),
    plot.subtitle = element_text(size = 10.5, colour = "#64748B"),
    axis.text = element_text(colour = "#475569")
  )

# Bar comparison: Static Pooled PAC vs. Realized Hourly PAC
df_relief_bar <- data.frame(
  Measurement = c("1. Static Pooled Matrix\n(Traditional Whole-Season PAC)", "2. Realized Diurnal PAC\n(Time-Resolved Hourly Mean)"),
  PAC_Value = c(0.65, 0.43),
  Type = c("Static Artifact", "Realized Truth")
)

p3_bars <- ggplot(df_relief_bar, aes(x = Measurement, y = PAC_Value, fill = Type)) +
  geom_col(width = 0.52, colour = "white", linewidth = 0.8) +
  geom_text(aes(label = sprintf("PAC = %.2f", PAC_Value)), vjust = -0.5, fontface = "bold", size = 4.0, colour = ink) +
  # Relief bracket
  annotate("segment", x = 1, xend = 2, y = 0.67, yend = 0.67, linewidth = 0.8, colour = "#DC2626") +
  annotate("segment", x = 1, xend = 1, y = 0.65, yend = 0.67, linewidth = 0.8, colour = "#DC2626") +
  annotate("segment", x = 2, xend = 2, y = 0.45, yend = 0.67, linewidth = 0.8, colour = "#DC2626") +
  annotate("label", x = 1.5, y = 0.72, label = "Diurnal PAC Relief: +33.8%\nSaved Niche Space via Temporal Escape", 
           fill = "#FEF2F2", colour = "#991B1B", fontface = "bold", size = 3.3, label.size = 0.3) +
  scale_fill_manual(values = c("Static Artifact" = "#94A3B8", "Realized Truth" = col_time), guide = "none") +
  scale_y_continuous(limits = c(0, 0.80), breaks = seq(0, 0.80, 0.20)) +
  labs(
    title = "B. The Diurnal PAC Relief Metric",
    subtitle = "Static pooling overestimates competition; hourly resolution uncovers temporal buffering",
    x = NULL, y = "Apparent Competition on Lotus (PAC)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, colour = ink),
    plot.subtitle = element_text(size = 10.5, colour = "#64748B"),
    axis.text.x = element_text(face = "bold", colour = ink, size = 10),
    axis.text.y = element_text(colour = "#475569")
  )

fig3_comb <- p3_curves / p3_bars + 
  plot_layout(heights = c(1.15, 1))

ggsave("images/pac_diurnal_relief_mechanism.png", fig3_comb, width = 11.5, height = 10.0, dpi = 240)
cat("Saved images/pac_diurnal_relief_mechanism.png successfully!\n")

# Copy all images to HanDriverNet docs
paper_img_dir <- "../../Psani_clanku/2026/HanDriverNet/docs/images"
dir.create(paper_img_dir, recursive = TRUE, showWarnings = FALSE)
file.copy("images/pac_concept_mechanisms.png", file.path(paper_img_dir, "pac_concept_mechanisms.png"), overwrite = TRUE)
file.copy("images/pac_toy_matrix_walkthrough.png", file.path(paper_img_dir, "pac_toy_matrix_walkthrough.png"), overwrite = TRUE)
file.copy("images/pac_diurnal_relief_mechanism.png", file.path(paper_img_dir, "pac_diurnal_relief_mechanism.png"), overwrite = TRUE)
cat("Copied all PAC illustration images to HanDriverNet/docs/images/\n")
