# Slide figure: Winners of diurnal stratification (PAC reduction by time of day)
# Evaluates species-level benefit (Static PAC vs Realized Diurnal PAC) from DiuHanPolNet
# Run from Seminar_Goteborg folder: Rscript scripts/fig_diu_winners.R

suppressMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(bipartite)
})

src <- "../../Psani_clanku/2026/DiuHanPolNet"
out <- "images"

navy <- "#3B0F70"; rose <- "#B63679"; coral <- "#F8765C"; green <- "#40695B"
purple <- "#5B3F9A"; slate <- "#64748B"; ink <- "#1E293B"; grid_col <- "#E2E8F0"

theme_deck <- theme_minimal(base_size = 20, base_family = "sans") +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = grid_col),
        axis.text = element_text(colour = "#334155"), axis.title = element_text(colour = ink),
        plot.background = element_rect(fill = "white", colour = NA),
        strip.text = element_text(face = "bold", size = 20, colour = ink))

# Load diurnal interactions
df <- read.csv(file.path(src, "data/diurnal_interactions.csv")) %>%
  filter(Insect_species != "Unknown", !is.na(Insect_species))

years <- sort(unique(df$Year))

calc_overlap_matrix <- function(mat) {
  n <- nrow(mat)
  overlap <- matrix(0, n, n)
  rownames(overlap) <- rownames(mat)
  colnames(overlap) <- rownames(mat)
  for (i in 1:n) {
    for (j in 1:n) {
      p1 <- mat[i,] / sum(mat[i,], na.rm=TRUE)
      p2 <- mat[j,] / sum(mat[j,], na.rm=TRUE)
      if (!is.na(sum(p1)) & !is.na(sum(p2)) & sum(p1) > 0 & sum(p2) > 0) {
        overlap[i,j] <- sum(p1 * p2) / sqrt(sum(p1^2) * sum(p2^2))
      }
    }
  }
  return(overlap)
}

results <- data.frame()

for (y in years) {
  df_y <- df %>% filter(Year == y)
  if (nrow(df_y) < 50 || length(unique(df_y$Plant_species)) < 2 || length(unique(df_y$Insect_species)) < 2) next
  
  agg_web <- df_y %>%
    group_by(Plant_species, Insect_species) %>%
    summarize(Count = sum(Interaction_count), .groups="drop") %>%
    pivot_wider(names_from = Insect_species, values_from = Count, values_fill = 0) %>%
    tibble::column_to_rownames("Plant_species") %>%
    as.matrix()
  
  pac_plants <- suppressWarnings(PAC(agg_web))
  pac_insects <- suppressWarnings(PAC(t(agg_web)))
  
  plant_time <- df_y %>%
    group_by(Plant_species, Hour) %>%
    summarize(Visits = sum(Interaction_count), .groups="drop") %>%
    pivot_wider(names_from = Hour, values_from = Visits, values_fill = 0) %>%
    tibble::column_to_rownames("Plant_species") %>%
    as.matrix()
  
  insect_time <- df_y %>%
    group_by(Insect_species, Hour) %>%
    summarize(Visits = sum(Interaction_count), .groups="drop") %>%
    pivot_wider(names_from = Hour, values_from = Visits, values_fill = 0) %>%
    tibble::column_to_rownames("Insect_species") %>%
    as.matrix()
  
  total_hourly_activity <- df_y %>%
    group_by(Hour) %>%
    summarize(Total_Visits = sum(Interaction_count), .groups="drop") %>%
    arrange(Hour) %>%
    pull(Total_Visits)
  
  plant_time_std <- sweep(plant_time, 2, total_hourly_activity, "/")
  insect_time_std <- sweep(insect_time, 2, total_hourly_activity, "/")
  
  overlap_plants_std <- calc_overlap_matrix(plant_time_std)
  overlap_insects_std <- calc_overlap_matrix(insect_time_std)
  
  common_p <- intersect(rownames(pac_plants), rownames(overlap_plants_std))
  realized_pac_plants <- pac_plants[common_p, common_p] * overlap_plants_std[common_p, common_p]
  
  common_i <- intersect(rownames(pac_insects), rownames(overlap_insects_std))
  realized_pac_insects <- pac_insects[common_i, common_i] * overlap_insects_std[common_i, common_i]
  
  p_static <- rowMeans(pac_plants[common_p, common_p], na.rm = TRUE)
  p_real <- rowMeans(realized_pac_plants, na.rm = TRUE)
  
  i_static <- rowMeans(pac_insects[common_i, common_i], na.rm = TRUE)
  i_real <- rowMeans(realized_pac_insects, na.rm = TRUE)
  
  results <- rbind(results, data.frame(
    Year = y,
    Guild = c(rep("Plants", length(p_static)), rep("Pollinators", length(i_static))),
    Species = c(names(p_static), names(i_static)),
    Static_PAC = c(p_static, i_static),
    Realized_PAC = c(p_real, i_real)
  ))
}

top_plants <- df %>% count(Plant_species, wt = Interaction_count, sort = TRUE) %>% head(12) %>% pull(Plant_species)
top_plants <- union(top_plants, c("Lotus corniculatus", "Lathyrus pratensis", "Trifolium pratense"))

top_insects <- df %>% count(Insect_species, wt = Interaction_count, sort = TRUE) %>% head(13) %>% pull(Insect_species)
top_insects <- union(top_insects, c("Zygaena_sp", "Syritta_pipiens"))

plot_data <- results %>%
  filter((Guild == "Plants" & Species %in% top_plants) | (Guild == "Pollinators" & Species %in% top_insects)) %>%
  group_by(Guild, Species) %>%
  summarize(
    Mean_Static = mean(Static_PAC, na.rm = TRUE),
    Mean_Realized = mean(Realized_PAC, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Benefit = Mean_Static - Mean_Realized,
    Pct_Reduction = (Benefit / Mean_Static) * 100,
    lab = sub("^(\\w)\\w+ ", "\\1. ", gsub("_", " ", Species))
  )

# Order separately per guild
plot_data <- plot_data %>%
  group_by(Guild) %>%
  mutate(lab = factor(lab, levels = lab[order(Pct_Reduction)])) %>%
  ungroup()

cat("Top plant winners:\n")
print(plot_data %>% filter(Guild == "Plants") %>% arrange(desc(Pct_Reduction)) %>% select(lab, Pct_Reduction, Mean_Static, Mean_Realized))

p <- ggplot(plot_data) +
  geom_segment(aes(x = Mean_Realized * 100, xend = Mean_Static * 100, y = lab, yend = lab),
               colour = "#CBD5E1", linewidth = 2.2) +
  geom_point(aes(x = Mean_Static * 100, y = lab, colour = "Static meta-web (whole day)"), size = 5) +
  geom_point(aes(x = Mean_Realized * 100, y = lab, colour = "Realized (diurnal slices)"), size = 5) +
  geom_text(aes(x = Mean_Realized * 100, y = lab, label = paste0("−", round(Pct_Reduction), "%")),
            hjust = 1.35, size = 4.8, colour = purple, fontface = "bold") +
  facet_wrap(~ Guild, scales = "free_y") +
  scale_colour_manual(values = c("Static meta-web (whole day)" = slate, "Realized (diurnal slices)" = purple)) +
  scale_x_continuous(expand = expansion(mult = c(0.18, 0.08))) +
  labs(x = "Apparent Competition Pressure (%)", y = NULL) +
  theme_deck +
  theme(legend.position = "top", legend.title = element_blank(),
        axis.text.y = element_text(face = "italic", size = 15),
        strip.background = element_rect(fill = "#F8FAFC", colour = NA),
        panel.spacing = unit(2.5, "lines"),
        plot.margin = margin(10, 20, 10, 10))

ggsave(file.path(out, "diu_winners_dumbbell.png"), p, width = 14, height = 7.5, dpi = 200)
cat("Saved to images/diu_winners_dumbbell.png successfully!\n")
