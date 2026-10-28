# Slide figure: Winners and Losers in spatial apparent competition (PAC)
# Evaluates species-level Driver Power vs Target Vulnerability from dyadic mixed models
# Run from Seminar_Goteborg folder: Rscript scripts/fig_pac_winners_losers.R

suppressMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(bipartite)
  library(lme4)
  library(ggplot2)
})

src_spa <- "../../Psani_clanku/2026/HanSpaNet"
src_pac <- "../../Psani_clanku/2025/Annual_dynamics_pollinator_sharing"
out <- "images"

navy <- "#3B0F70"; rose <- "#B63679"; coral <- "#F8765C"; green <- "#40695B"
slate <- "#64748B"; ink <- "#1E293B"; grid_col <- "#E2E8F0"

theme_deck <- theme_minimal(base_size = 22, base_family = "sans") +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank(),
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
  purrr::map_dfr(function(df) {
    m <- df %>% select(-Year) %>% tidyr::pivot_wider(names_from = Insect_species, values_from = rate, values_fill = 0)
    mat <- as.matrix(m[, -1]); rownames(mat) <- m$Plant_species
    pac <- suppressWarnings(bipartite::PAC(mat)); diag(pac) <- 0
    as.data.frame(as.table(pac)) %>% rename(target = Var1, driver = Var2, pac = Freq) %>% mutate(Year = df$Year[1])
  }) %>%
  left_join(map, by = c("target" = "plant_name")) %>% rename(target_code = plant_code) %>%
  left_join(map, by = c("driver" = "plant_name")) %>% rename(driver_code = plant_code) %>%
  filter(!is.na(target_code), !is.na(driver_code))

plot_sp <- species_spatial_metrics %>% filter(species_abundance > 0) %>%
  select(Year, plot_id, plant_code, species_abundance, species_clumping)

dyads <- plot_sp %>% rename(target_code = plant_code, target_abund = species_abundance, target_clump = species_clumping) %>%
  inner_join(plot_sp %>% rename(driver_code = plant_code, driver_abund = species_abundance, driver_clump = species_clumping),
             by = c("Year", "plot_id"), relationship = "many-to-many") %>%
  filter(target_code != driver_code) %>%
  inner_join(pac_annual, by = c("Year", "target_code", "driver_code")) %>%
  mutate(log_abund_ratio_sc = as.vector(scale(log(driver_abund / target_abund))),
         driver_clump_sc = as.vector(scale(driver_clump)),
         target_clump_sc = as.vector(scale(target_clump)))

# 2. Fit model
m <- lmer(pac ~ log_abund_ratio_sc + driver_clump_sc + target_clump_sc +
            (1 | Year) + (1 | driver_code) + (1 | target_code), data = dyads)

ran_driver <- ranef(m)$driver_code
ran_driver$plant_code <- rownames(ran_driver)
colnames(ran_driver)[1] <- "driver_power"

ran_target <- ranef(m)$target_code
ran_target$plant_code <- rownames(ran_target)
colnames(ran_target)[1] <- "target_vulnerability"

counts <- plot_sp %>% group_by(plant_code) %>% summarise(n_obs = n(), .groups = "drop")

roles <- ran_driver %>% 
  inner_join(ran_target, by = "plant_code") %>%
  left_join(map, by = "plant_code") %>%
  left_join(counts, by = "plant_code") %>%
  filter(n_obs >= 70) %>% # species with solid representation
  mutate(net_balance = driver_power - target_vulnerability,
         lab = sub("^(\\w)\\w+ ", "\\1. ", plant_name),
         lab = factor(lab, levels = lab[order(net_balance)]),
         col = ifelse(net_balance > 0, green, coral))

p <- ggplot(roles, aes(net_balance, lab, colour = I(col))) +
  geom_vline(xintercept = 0, colour = slate, linewidth = 0.8) +
  geom_segment(aes(x = 0, xend = net_balance, yend = lab), linewidth = 1.6, alpha = 0.6) +
  geom_point(size = 5.5) +
  annotate("text", x = 0.075, y = 21, hjust = 0, size = 6, colour = green, fontface = "bold", lineheight = 1.05,
           label = "WINNERS (Drivers) →\n• Dictate visitors in dense clumps\n• Immune to neighbour theft\n• Core species (Centaurea, Succisa, Selinum)") +
  annotate("text", x = 0.045, y = 5.5, hjust = 0, size = 6, colour = coral, fontface = "bold", lineheight = 1.05,
           label = "← LOSERS (Targets)\n• Suffer visitor theft near clumped neighbours\n• High incoming apparent competition\n• Periphery (Hypericum, Lotus, Galium)") +
  scale_x_continuous(expand = expansion(mult = c(0.08, 0.18))) +
  labs(x = "Net Spatial Apparent Competition (Driver Power − Target Vulnerability)", y = NULL) +
  theme_deck +
  theme(axis.text.y = element_text(face = "italic", size = 15, colour = "#1E293B"))

ggsave(file.path(out, "pac_winners_losers.png"), p, width = 13.5, height = 7.2, dpi = 200)
cat("Saved images/pac_winners_losers.png successfully!\n")
