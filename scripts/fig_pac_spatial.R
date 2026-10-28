# Slide figure: effect of co-flowering plant identity, abundance, and clumpiness on PAC
# Prototype test linking HanSpaNet fine-scale spatial metrics with annual PAC sharing networks.
# Run from Seminar_Goteborg folder: Rscript scripts/fig_pac_spatial.R

suppressMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(bipartite)
  library(lme4)
  library(lmerTest)
  library(ggplot2)
})

src_spa <- "../../Psani_clanku/2026/HanSpaNet"
src_pac <- "../../Psani_clanku/2025/Annual_dynamics_pollinator_sharing"
out <- "images"

navy <- "#3B0F70"; rose <- "#B63679"; coral <- "#F8765C"; green <- "#40695B"
slate <- "#64748B"; ink <- "#1E293B"; grid_col <- "#E2E8F0"

theme_deck <- theme_minimal(base_size = 24, base_family = "sans") +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = grid_col),
        axis.text = element_text(colour = "#334155"), axis.title = element_text(colour = ink),
        legend.position = "none", plot.background = element_rect(fill = "white", colour = NA))

# 1. Load data
load(file.path(src_spa, "data/species_spatial_metrics.rda"))
si <- read.csv(file.path(src_spa, "data/spatial_interactions.csv"))
map <- unique(si[, c("plant_code", "plant_name")]) %>% filter(!is.na(plant_code), plant_code != "")

species_spatial_metrics <- species_spatial_metrics %>% 
  mutate(plot_id = as.character(plot_id), 
         plant_code = as.character(plant_code),
         Year = as.numeric(year) + ifelse(as.numeric(year) < 100, 2000, 0))

int <- read.csv(file.path(src_pac, "data/published_data/annual_sharing_interactions.csv"))
pac_annual <- int %>% 
  filter(!is.na(Standardized_rate), Standardized_rate > 0) %>%
  group_by(Year, Plant_species, Insect_species) %>%
  summarise(rate = sum(Standardized_rate), .groups = "drop") %>%
  group_by(Year) %>% group_split() %>%
  map_dfr(function(df) {
    m <- df %>% select(-Year) %>% pivot_wider(names_from = Insect_species, values_from = rate, values_fill = 0)
    mat <- as.matrix(m[, -1]); rownames(mat) <- m$Plant_species
    pac <- suppressWarnings(bipartite::PAC(mat))
    diag(pac) <- 0
    as.data.frame(as.table(pac)) %>%
      rename(target = Var1, driver = Var2, pac = Freq) %>%
      mutate(Year = df$Year[1])
  }) %>%
  left_join(map, by = c("target" = "plant_name")) %>% rename(target_code = plant_code) %>%
  left_join(map, by = c("driver" = "plant_name")) %>% rename(driver_code = plant_code) %>%
  filter(!is.na(target_code), !is.na(driver_code))

plot_sp <- species_spatial_metrics %>% 
  filter(species_abundance > 0) %>%
  select(Year, plot_id, plant_code, species_abundance, species_clumping)

dyads <- plot_sp %>% rename(target_code = plant_code, target_abund = species_abundance, target_clump = species_clumping) %>%
  inner_join(plot_sp %>% rename(driver_code = plant_code, driver_abund = species_abundance, driver_clump = species_clumping),
             by = c("Year", "plot_id"), relationship = "many-to-many") %>%
  filter(target_code != driver_code) %>%
  inner_join(pac_annual, by = c("Year", "target_code", "driver_code"))

dyads <- dyads %>%
  mutate(log_abund_ratio_sc = as.vector(scale(log(driver_abund / target_abund))),
         driver_clump_sc = as.vector(scale(driver_clump)),
         target_clump_sc = as.vector(scale(target_clump)),
         driver_is_thief_sc = as.vector(scale(as.numeric(driver_code %in% c("Suc_pra", "Cen_jac")))),
         pac_sc = as.vector(scale(pac)))

cat("Fitting standardized dyadic mixed model on", nrow(dyads), "plant pairs...\n")
m_std <- lmer(pac_sc ~ driver_is_thief_sc + log_abund_ratio_sc + driver_clump_sc + target_clump_sc +
                (1 | Year) + (1 | driver_code) + (1 | target_code), 
              data = dyads)

cf <- as.data.frame(coef(summary(m_std)))
cf$term <- rownames(cf)
ci <- confint(m_std, method = "Wald")
cf <- cf %>% filter(term != "(Intercept)") %>%
  mutate(lo = ci[term, 1], hi = ci[term, 2], p = `Pr(>|t|)`)

print(cf[, c("term", "Estimate", "lo", "hi", "p")])

lab <- c(
  driver_is_thief_sc = "Neighbour is a 'Thief' (Succisa / Centaurea)",
  log_abund_ratio_sc = "Neighbour has more flowers (abundance ratio)",
  driver_clump_sc = "Neighbour grows in dense clumps",
  target_clump_sc = "Focal plant grows in dense clumps"
)

grp <- c(
  driver_is_thief_sc = "Neighbour Identity",
  log_abund_ratio_sc = "Neighbour Abundance",
  driver_clump_sc = "Spatial Arrangement",
  target_clump_sc = "Spatial Arrangement"
)

cf <- cf %>% 
  mutate(
    label = factor(lab[term], levels = rev(lab)),
    group = factor(grp[term], levels = c("Neighbour Identity", "Neighbour Abundance", "Spatial Arrangement")),
    col = coral, # All significant positive drivers of apparent competition
    star = case_when(p < 0.001 ~ "***", p < 0.01 ~ "**", p < 0.05 ~ "*", TRUE ~ "n.s.")
  )

p <- ggplot(cf, aes(Estimate, label)) +
  geom_vline(xintercept = 0, colour = slate, linewidth = 0.8) +
  geom_errorbar(aes(xmin = lo, xmax = hi, colour = I(col)), orientation = "y", width = 0, linewidth = 1.6) +
  geom_point(aes(colour = I(col)), size = 6) +
  geom_text(aes(x = hi, label = star), hjust = -0.3, size = 6.5, colour = ink) +
  facet_grid(group ~ ., scales = "free_y", space = "free_y") +
  scale_x_continuous(expand = expansion(mult = c(0.05, 0.2))) +
  labs(x = "Standardized effect on Apparent Competition (PAC) on focal plant (SD units)", y = NULL) +
  theme_deck +
  theme(strip.text.y = element_text(angle = 0, hjust = 0, face = "bold", size = 18, colour = ink),
        panel.spacing = unit(1.2, "lines"),
        plot.margin = margin(10, 25, 10, 10))

ggsave(file.path(out, "pac_space_effects.png"), p, width = 14.5, height = 5.8, dpi = 200)
cat("Saved standardized plot to images/pac_space_effects.png successfully!\n")
