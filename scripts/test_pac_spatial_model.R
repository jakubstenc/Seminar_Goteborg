suppressMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(bipartite)
  library(lme4)
  library(lmerTest)
})
src_spa <- "../../Psani_clanku/2026/HanSpaNet"
src_pac <- "../../Psani_clanku/2025/Annual_dynamics_pollinator_sharing"

load(file.path(src_spa, "data/species_spatial_metrics.rda"))
si <- read.csv(file.path(src_spa, "data/spatial_interactions.csv"))
map <- unique(si[, c("plant_code", "plant_name")]) %>% filter(!is.na(plant_code), plant_code != "")

# Clean year in spatial metrics: year is 11..25, in pac it is 2011..2025
species_spatial_metrics <- species_spatial_metrics %>% 
  mutate(plot_id = as.character(plot_id), 
         plant_code = as.character(plant_code),
         Year = as.numeric(year) + ifelse(as.numeric(year) < 100, 2000, 0))

# Meadow-level PAC per year
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
  })

# Add plant_codes to pac_annual
pac_annual <- pac_annual %>%
  left_join(map, by = c("target" = "plant_name")) %>% rename(target_code = plant_code) %>%
  left_join(map, by = c("driver" = "plant_name")) %>% rename(driver_code = plant_code) %>%
  filter(!is.na(target_code), !is.na(driver_code))

plot_plants <- species_spatial_metrics %>%
  select(Year, plot_id, plant_code, species_abundance) %>%
  filter(species_abundance > 0)

# Join neighbours: for each focal plant (target), neighbours are drivers
pac_plot <- plot_plants %>%
  rename(target_code = plant_code, target_abund = species_abundance) %>%
  inner_join(plot_plants %>% rename(driver_code = plant_code, driver_abund = species_abundance),
             by = c("Year", "plot_id"), relationship = "many-to-many") %>%
  filter(target_code != driver_code) %>%
  left_join(pac_annual, by = c("Year", "target_code", "driver_code")) %>%
  mutate(pac = coalesce(pac, 0))

pac_summary <- pac_plot %>%
  group_by(Year, plot_id, target_code) %>%
  summarise(
    incoming_pac_sum = sum(pac),
    incoming_pac_wt = sum(pac * driver_abund) / sum(driver_abund),
    incoming_pac_exposure = sum(pac * driver_abund),
    n_neighbours = n(),
    prop_thief = sum(driver_abund[driver_code %in% c("Suc_pra", "Cen_jac")]) / sum(driver_abund),
    .groups = "drop"
  )

df_model <- species_spatial_metrics %>%
  rename(target_code = plant_code) %>%
  inner_join(pac_summary, by = c("Year", "plot_id", "target_code")) %>%
  filter(!is.na(heterospecific_clumping), !is.na(species_clumping), !is.na(heterospecific_density)) %>%
  group_by(target_code) %>%
  mutate(species_abundance = if (n() > 1 && var(species_abundance, na.rm = TRUE) > 0)
    as.vector(scale(species_abundance)) else 0) %>%
  ungroup() %>%
  mutate(across(c(species_clumping, heterospecific_density, heterospecific_clumping,
                  heterospecific_heterogeneity, prop_thief), ~ as.vector(scale(.))),
         log_pac_wt = log(incoming_pac_wt + 0.001),
         log_pac_sum = log(incoming_pac_sum + 0.001),
         across(c(Year, plot_id, target_code), as.factor)) %>%
  as.data.frame()

cat("Fitting Model 1: log(incoming_pac_wt) ~ space + thief\n")
m_wt <- lmer(log_pac_wt ~ species_abundance + species_clumping + 
               heterospecific_density + heterospecific_clumping + 
               heterospecific_heterogeneity + prop_thief + 
               (1 | Year) + (1 | plot_id) + (1 | target_code), data = df_model)
print(summary(m_wt)$coefficients)

cat("\nFitting Model 2: log(incoming_pac_sum) ~ space + thief\n")
m_sum <- lmer(log_pac_sum ~ species_abundance + species_clumping + 
                heterospecific_density + heterospecific_clumping + 
                heterospecific_heterogeneity + prop_thief + 
                (1 | Year) + (1 | plot_id) + (1 | target_code), data = df_model)
print(summary(m_sum)$coefficients)
