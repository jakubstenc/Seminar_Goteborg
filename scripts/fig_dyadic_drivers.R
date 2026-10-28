# Seminar Göteborg & Ecology Letters 2026: Outlook Slide & Paper Figure 1
# "Beyond Static Networks: The Driver-Attributed Network"
# Combines:
# 1. Panel A: Circular Unipartite Network of Apparent Competition (edges colored by Driver)
# 2. Panel B: 3D Driver Simplex (Ternary plot of dyadic variance partitioning across 608 links)
# 3. Panel C: Physical Variance Partitioning across Topological Compartments (Core vs Bridges vs Subordinates)
# 4. Panel D: Diurnal Apparent Competition Relief (Phenological escape valve for subordinates)
# Run: Rscript scripts/fig_dyadic_drivers.R

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(igraph)
  library(ggraph)
  library(tidygraph)
  library(ggplot2)
  library(ggrepel)
  library(patchwork)
  library(bipartite)
})

out <- "images"
dyad_file <- "../../Psani_clanku/2026/HanDriverNet/outputs/dyadic_variance_partitioning.csv"
raw_file  <- "../../Psani_clanku/2026/HanDriverNet/data/diurnal_interactions.csv"

if (!file.exists(dyad_file)) {
  stop("Dyad file not found! Run HanDriverNet 01 first.")
}

dyads <- read.csv(dyad_file)

# Palette
col_space <- "#40695B"  # Forest green
col_year  <- "#F8765C"  # Coral / orange
col_time  <- "#3B0F70"  # Deep purple
grid_col  <- "#E2E8F0"
ink       <- "#1E293B"

theme_deck <- theme_minimal(base_size = 14, base_family = "sans") +
  theme(
    panel.grid = element_blank(),
    plot.background = element_rect(fill = "white", colour = NA),
    axis.text = element_text(colour = "#475569", size = 11),
    axis.title = element_text(colour = ink, face = "bold", size = 12),
    plot.title = element_text(colour = ink, face = "bold", size = 15),
    plot.subtitle = element_text(colour = "#64748B", size = 11.5)
  )

# ==============================================================================
# PART 1: THE CIRCULAR DRIVER-ATTRIBUTED NETWORK (PANEL A)
# ==============================================================================

focus_plants <- c(
  # Composites & Dipsacaceae
  "Centaurea jacea", "Succisa pratensis", "Cirsium palustre", "Serratula tinctoria", "Achillea ptarmica", "Leontodon hispidus",
  # White Umbellifers
  "Heracleum sphondylium", "Daucus carota", "Selinum carvifolia", "Angelica sylvestris",
  # Fabaceae
  "Lotus corniculatus", "Lathyrus pratensis", "Trifolium pratense", "Trifolium hybridum",
  # Other herbs
  "Potentilla erecta", "Ranunculus acris"
)

guild_map <- data.frame(
  name = focus_plants,
  guild = c(
    rep("Composites & Dipsacaceae", 6),
    rep("White Umbellifers", 4),
    rep("Fabaceae", 4),
    rep("Other herbs", 2)
  ),
  stringsAsFactors = FALSE
)

sub_edges <- dyads %>%
  filter(Plant_A %in% focus_plants, Plant_B %in% focus_plants) %>%
  filter(Mean_PAC >= 0.02 | Primary_Driver == "Time") %>%
  mutate(
    from = Plant_A,
    to = Plant_B,
    weight = Mean_PAC,
    Driver = factor(Primary_Driver, levels = c("Space", "Year", "Time"))
  ) %>%
  arrange(desc(weight)) %>%
  head(75)

g <- tbl_graph(nodes = guild_map, edges = sub_edges, directed = TRUE)

layout_circ <- create_layout(g, layout = "linear", circular = TRUE)
layout_circ$angle <- 90 - 360 * (1:nrow(layout_circ) - 0.5) / nrow(layout_circ)
layout_circ$hjust <- ifelse(layout_circ$angle < -90, 1, 0)
layout_circ$angle <- ifelse(layout_circ$angle < -90, layout_circ$angle + 180, layout_circ$angle)

p_net <- ggraph(layout_circ) +
  geom_edge_arc(aes(colour = Driver, width = weight, alpha = weight),
                strength = 0.45, lineend = "round") +
  geom_node_point(aes(fill = guild), size = 5.2, shape = 21, colour = "white", stroke = 1.1) +
  geom_node_text(aes(x = x * 1.16, y = y * 1.16, label = sub("^(\\w)\\w+ ", "\\1. ", name),
                     angle = angle, hjust = hjust),
                 size = 3.6, fontface = "italic", colour = ink) +
  scale_edge_colour_manual(
    values = c("Space" = col_space, "Year" = col_year, "Time" = col_time),
    name = "Link Driver:"
  ) +
  scale_edge_width_continuous(range = c(0.6, 2.8), guide = "none") +
  scale_edge_alpha_continuous(range = c(0.35, 0.9), guide = "none") +
  scale_fill_manual(
    values = c("Composites & Dipsacaceae" = "#3B0F70",
               "White Umbellifers" = "#64748B",
               "Fabaceae" = "#F8765C",
               "Other herbs" = "#D97706"),
    name = "Guild:"
  ) +
  scale_x_continuous(expand = expansion(mult = 0.28)) +
  scale_y_continuous(expand = expansion(mult = 0.28)) +
  labs(
    title = "A. The Driver-Attributed Network",
    subtitle = "Links colored by governing physical axis (Edge width = Mean PAC)"
  ) +
  theme_void(base_size = 14, base_family = "sans") +
  theme(
    plot.title = element_text(colour = ink, face = "bold", size = 14, margin = margin(b = 2)),
    plot.subtitle = element_text(colour = "#64748B", size = 11, margin = margin(b = 6)),
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.spacing.x = unit(12, "pt"),
    legend.title = element_text(face = "bold", size = 10),
    legend.text = element_text(size = 9.5),
    legend.margin = margin(l = 25),
    plot.margin = margin(5, 10, 5, 40)
  )

# ==============================================================================
# PART 2: THE 3D DRIVER SIMPLEX (PANEL B)
# ==============================================================================

h_tri <- sqrt(3) / 2
dyads <- dyads %>%
  mutate(
    s = Pct_Space / 100,
    y = Pct_Year / 100,
    t = Pct_Time / 100,
    tri_x = 0.5 * (2 * y + t) / (s + y + t),
    tri_y = (h_tri * t) / (s + y + t),
    lab_A = sub("^(\\w)\\w+ ", "\\1. ", Plant_A),
    lab_B = sub("^(\\w)\\w+ ", "\\1. ", Plant_B),
    dyad_name = paste0(lab_A, " → ", lab_B)
  )

triangle_df <- data.frame(
  x = c(0, 1, 0.5, 0),
  y = c(0, 0, h_tri, 0)
)

highlights <- dyads %>%
  filter(
    (Plant_A == "Centaurea jacea" & Plant_B == "Succisa pratensis") |
    (Plant_A == "Heracleum sphondylium" & Plant_B == "Achillea ptarmica") |
    (Plant_A == "Leontodon hispidus" & Plant_B == "Succisa pratensis") |
    (Plant_A == "Selinum carvifolia" & Plant_B == "Achillea ptarmica") |
    (Plant_A == "Trifolium hybridum" & Plant_B == "Centaurea jacea")
  ) %>% head(5)

p_tri <- ggplot() +
  geom_polygon(data = triangle_df, aes(x, y), fill = "#F8FAFC", colour = "#CBD5E1", linewidth = 1.1) +
  geom_segment(aes(x = 0.5, y = 0, xend = 0.5, yend = h_tri), colour = "#E2E8F0", linetype = "dashed") +
  geom_segment(aes(x = 0, y = 0, xend = 0.75, yend = h_tri/2), colour = "#E2E8F0", linetype = "dashed") +
  geom_segment(aes(x = 1, y = 0, xend = 0.25, yend = h_tri/2), colour = "#E2E8F0", linetype = "dashed") +
  geom_point(data = dyads, aes(x = tri_x, y = tri_y, colour = Primary_Driver, size = Mean_PAC),
             alpha = 0.6) +
  geom_point(data = highlights, aes(x = tri_x, y = tri_y), size = 3.8, shape = 21, stroke = 1.4, fill = "white", colour = "black") +
  geom_text_repel(data = highlights, aes(x = tri_x, y = tri_y, label = dyad_name),
                  size = 3.3, fontface = "italic", box.padding = 0.4, point.padding = 0.2,
                  nudge_y = 0.05, max.overlaps = 25, seed = 42) +
  annotate("text", x = 0.06, y = -0.06, label = "SPACE\n(Micro-Clumping)\n464 links (76%)", 
           colour = col_space, fontface = "bold", size = 3.5, hjust = 0.5, lineheight = 0.95) +
  annotate("text", x = 0.94, y = -0.06, label = "YEAR\n(Climate Shocks)\n125 links (21%)", 
           colour = col_year, fontface = "bold", size = 3.5, hjust = 0.5, lineheight = 0.95) +
  annotate("text", x = 0.5, y = h_tri + 0.05, label = "TIME (Diurnal Window)\n19 links (3%)", 
           colour = col_time, fontface = "bold", size = 3.5, hjust = 0.5, lineheight = 0.95) +
  scale_colour_manual(values = c("Space" = col_space, "Year" = col_year, "Time" = col_time)) +
  scale_size_continuous(range = c(1.8, 6), name = "Mean PAC") +
  scale_x_continuous(limits = c(-0.10, 1.10)) +
  scale_y_continuous(limits = c(-0.14, h_tri + 0.10)) +
  labs(
    title = "B. Dyadic Driver Simplex",
    subtitle = "608 links partitioned in continuous 3D driver space"
  ) +
  theme_deck +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    legend.position = "none",
    plot.title = element_text(colour = ink, face = "bold", size = 14, margin = margin(b = 2)),
    plot.subtitle = element_text(colour = "#64748B", size = 11, margin = margin(b = 6)),
    plot.margin = margin(5, 10, 5, 5)
  )

# ==============================================================================
# PART 3: STATISTICAL GRAPH 1 - VARIANCE BY COMPARTMENT (PANEL C)
# ==============================================================================

composites <- c("Centaurea jacea", "Succisa pratensis", "Cirsium palustre", "Serratula tinctoria", "Achillea ptarmica", "Leontodon hispidus")
umbels     <- c("Heracleum sphondylium", "Daucus carota", "Selinum carvifolia", "Angelica sylvestris", "Pimpinella saxifraga")
fabaceae   <- c("Lotus corniculatus", "Lathyrus pratensis", "Trifolium pratense", "Trifolium hybridum", "Vicia cracca")

dyads$role <- "Other Community"
dyads$role[dyads$Plant_A %in% composites & dyads$Plant_B %in% composites] <- "Core Module\n(Composites)"
dyads$role[(dyads$Plant_A %in% umbels & dyads$Plant_B %in% composites) | (dyads$Plant_A %in% composites & dyads$Plant_B %in% umbels)] <- "Connector Bridges\n(Umbels ↔ Core)"
dyads$role[(dyads$Plant_A %in% fabaceae & dyads$Plant_B %in% composites) | (dyads$Plant_A %in% composites & dyads$Plant_B %in% fabaceae)] <- "Subordinates\n(Fabaceae ↔ Core)"

role_levels <- c("Core Module\n(Composites)", "Connector Bridges\n(Umbels ↔ Core)", "Subordinates\n(Fabaceae ↔ Core)", "Other Community")
dyads$role <- factor(dyads$role, levels = role_levels)

role_summary <- dyads %>%
  group_by(role) %>%
  summarise(
    n = n(),
    mean_Space = mean(Pct_Space),
    se_Space   = sd(Pct_Space) / sqrt(n()),
    mean_Year  = mean(Pct_Year),
    se_Year    = sd(Pct_Year) / sqrt(n()),
    mean_Time  = mean(Pct_Time),
    se_Time    = sd(Pct_Time) / sqrt(n()),
    .groups = "drop"
  )

df_long_mean <- role_summary %>%
  select(role, n, mean_Space, mean_Year, mean_Time) %>%
  pivot_longer(cols = starts_with("mean_"), names_to = "Dimension", values_to = "Mean_Pct", names_prefix = "mean_")

df_long_se <- role_summary %>%
  select(role, se_Space, se_Year, se_Time) %>%
  pivot_longer(cols = starts_with("se_"), names_to = "Dimension", values_to = "SE_Pct", names_prefix = "se_")

df_plot_c <- inner_join(df_long_mean, df_long_se, by = c("role", "Dimension")) %>%
  mutate(
    Dimension = factor(Dimension, levels = c("Space", "Year", "Time")),
    label_txt = sprintf("%.1f%%", Mean_Pct)
  )

p_role <- ggplot(df_plot_c, aes(x = role, y = Mean_Pct, fill = Dimension)) +
  geom_col(position = position_dodge(0.78), width = 0.72, colour = "white", linewidth = 0.4) +
  geom_errorbar(aes(ymin = pmax(0, Mean_Pct - SE_Pct), ymax = Mean_Pct + SE_Pct),
                position = position_dodge(0.78), width = 0.22, linewidth = 0.6, colour = "#334155") +
  geom_text(aes(label = label_txt, y = Mean_Pct + SE_Pct + 2.5),
            position = position_dodge(0.78), size = 3.1, fontface = "bold", colour = ink) +
  scale_fill_manual(
    values = c("Space" = col_space, "Year" = col_year, "Time" = col_time),
    name = "Physical Dimension:"
  ) +
  scale_y_continuous(limits = c(0, 95), breaks = seq(0, 80, 20), expand = c(0, 0)) +
  labs(
    title = "C. Physical Dimension by Network Compartment",
    subtitle = "Space governs the core (80.4%); Year doubles in connector bridges (25.2%)",
    x = NULL,
    y = "Variance Explained (%)"
  ) +
  theme_deck +
  theme(
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.title = element_text(face = "bold", size = 10),
    legend.text = element_text(size = 9.5),
    panel.grid.major.y = element_line(colour = "#F1F5F9", linewidth = 0.6),
    axis.text.x = element_text(face = "bold", colour = ink, size = 9.8),
    plot.title = element_text(colour = ink, face = "bold", size = 14, margin = margin(b = 2)),
    plot.subtitle = element_text(colour = "#64748B", size = 11, margin = margin(b = 6)),
    plot.margin = margin(5, 10, 5, 10)
  )

# ==============================================================================
# PART 4: STATISTICAL GRAPH 2 - DIURNAL PAC RELIEF (PANEL D)
# ==============================================================================

# Calculate diurnal relief from Core Composites
df_raw <- read.csv(raw_file) %>%
  filter(!is.na(Plant_species), !is.na(Insect_species), 
         Insect_species != "Unknown", Interaction_count > 0)

m_all <- df_raw %>%
  group_by(Plant_species, Insect_species) %>%
  summarise(v = sum(Interaction_count), .groups = "drop") %>%
  pivot_wider(names_from = Insect_species, values_from = v, values_fill = 0) %>%
  tibble::column_to_rownames("Plant_species") %>%
  as.matrix()

pac_static_mat <- suppressWarnings(bipartite::PAC(m_all))

hours <- 8:17
pac_hourly_list <- list()
for (h in hours) {
  sub_h <- df_raw %>% filter(Hour == h)
  m_h <- sub_h %>%
    group_by(Plant_species, Insect_species) %>%
    summarise(v = sum(Interaction_count), .groups = "drop") %>%
    pivot_wider(names_from = Insect_species, values_from = v, values_fill = 0) %>%
    tibble::column_to_rownames("Plant_species") %>%
    as.matrix()
  if (nrow(m_h) >= 2 && ncol(m_h) >= 2) {
    p <- suppressWarnings(bipartite::PAC(m_h))
    pac_hourly_list[[as.character(h)]] <- as.data.frame(as.table(p)) %>%
      rename(Plant_A = Var1, Plant_B = Var2, PAC_h = Freq) %>%
      mutate(Hour = h)
  }
}
pac_hourly_df <- bind_rows(pac_hourly_list)

pac_diurnal_df <- pac_hourly_df %>%
  group_by(Plant_A, Plant_B) %>%
  summarise(Mean_PAC_diurnal = mean(PAC_h, na.rm = TRUE), .groups = "drop")

pac_compare <- as.data.frame(as.table(pac_static_mat)) %>%
  rename(Plant_A = Var1, Plant_B = Var2, PAC_static = Freq) %>%
  inner_join(pac_diurnal_df, by = c("Plant_A", "Plant_B")) %>%
  filter(Plant_A != Plant_B) %>%
  mutate(PAC_relief_pct = (PAC_static - Mean_PAC_diurnal) / PAC_static * 100)

core_comp_sp <- c("Centaurea jacea", "Succisa pratensis", "Cirsium palustre", "Serratula tinctoria")

focal_relief_sp <- c(
  "Myosotis sp", "Crepis biennis", "Hypericum maculatum", "Lycopus europaeus", 
  "Trifolium pratense", "Lotus corniculatus", "Ranunculus repens", "Trifolium repens", 
  "Selinum carvifolia", "Succisa pratensis", "Centaurea jacea", "Cirsium palustre"
)

df_relief <- pac_compare %>%
  filter(Plant_B %in% core_comp_sp, Plant_A %in% focal_relief_sp) %>%
  group_by(Plant_A) %>%
  summarise(
    mean_relief = mean(PAC_relief_pct, na.rm = TRUE),
    se_relief   = sd(PAC_relief_pct, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  ) %>%
  mutate(
    Guild = case_when(
      Plant_A %in% c("Centaurea jacea", "Succisa pratensis", "Cirsium palustre") ~ "Core Bullies",
      Plant_A %in% c("Lotus corniculatus", "Trifolium pratense", "Trifolium repens") ~ "Fabaceae",
      TRUE ~ "Subordinate Herbs"
    ),
    Plant_label = sub("^(\\w)\\w+ ", "\\1. ", Plant_A)
  ) %>%
  arrange(mean_relief)

df_relief$Plant_label <- factor(df_relief$Plant_label, levels = df_relief$Plant_label)

p_relief <- ggplot(df_relief, aes(x = mean_relief, y = Plant_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#94A3B8", linewidth = 0.7) +
  geom_segment(aes(x = 0, xend = mean_relief, y = Plant_label, yend = Plant_label),
               linewidth = 1.3, colour = "#CBD5E1") +
  geom_point(aes(fill = Guild), size = 4.2, shape = 21, stroke = 1.2, colour = "white") +
  geom_text(aes(label = sprintf("%+.1f%%", mean_relief)),
            hjust = ifelse(df_relief$mean_relief >= 0, -0.28, 1.28),
            size = 3.2, fontface = "bold", colour = ink) +
  scale_fill_manual(
    values = c("Core Bullies" = "#3B0F70", "Fabaceae" = "#F8765C", "Subordinate Herbs" = "#D97706"),
    name = "Guild:"
  ) +
  scale_x_continuous(limits = c(-8, 26), breaks = seq(-5, 25, 5)) +
  labs(
    title = "D. Diurnal Apparent Competition Relief",
    subtitle = "Subordinates escape core bullies via diurnal staggering; Core bullies cannot escape each other",
    x = "PAC Reduction through Diurnal Niche Partitioning (%)",
    y = NULL
  ) +
  theme_deck +
  theme(
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.title = element_text(face = "bold", size = 10),
    legend.text = element_text(size = 9.5),
    panel.grid.major.x = element_line(colour = "#F1F5F9", linewidth = 0.6),
    axis.text.y = element_text(face = "italic", colour = ink, size = 9.5),
    plot.title = element_text(colour = ink, face = "bold", size = 14, margin = margin(b = 2)),
    plot.subtitle = element_text(colour = "#64748B", size = 11, margin = margin(b = 6)),
    plot.margin = margin(5, 10, 5, 10)
  )

# ==============================================================================
# COMBINE PANELS (2x2 PUBLICATION-GRADE COMPOSITE)
# ==============================================================================

p_comb <- (p_net | p_tri) / (p_role | p_relief) + 
  plot_layout(heights = c(1.15, 1))

# Save taller, balanced proportions (width = 13.6, height = 13.2)
ggsave(file.path(out, "dyadic_drivers_4panel.png"), p_comb, width = 13.6, height = 13.2, dpi = 240)
file.copy(file.path(out, "dyadic_drivers_4panel.png"), file.path(out, "dyadic_drivers_circ_network.png"), overwrite = TRUE)
file.copy(file.path(out, "dyadic_drivers_4panel.png"), file.path("docs/images", "dyadic_drivers_4panel.png"), overwrite = TRUE)
cat("Saved 4-panel composite to images/dyadic_drivers_4panel.png successfully!\n")

# Also copy to paper figure repository
paper_fig_dir <- "../../Psani_clanku/2026/HanDriverNet/figures"
paper_docs_dir <- "../../Psani_clanku/2026/HanDriverNet/docs/figures"
if (dir.exists(paper_fig_dir)) {
  file.copy(file.path(out, "dyadic_drivers_4panel.png"), 
            file.path(paper_fig_dir, "Figure1_dyadic_drivers.png"), overwrite = TRUE)
  dir.create(paper_docs_dir, recursive = TRUE, showWarnings = FALSE)
  file.copy(file.path(out, "dyadic_drivers_4panel.png"), 
            file.path(paper_docs_dir, "Figure1_dyadic_drivers.png"), overwrite = TRUE)
  cat("Saved Figure 1 to HanDriverNet/figures/Figure1_dyadic_drivers.png\n")
}
