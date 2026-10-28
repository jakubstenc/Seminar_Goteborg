# Slide figure: effect of fine-scale space on visitation (HanSpaNet species-level model).
# Same data prep and model as Psani_clanku/2026/HanSpaNet/R_scripts/07_species_level_models.R (Model 1).
# Run from the Seminar_Goteborg folder:  Rscript scripts/fig_space.R
suppressMessages({library(dplyr); library(lme4); library(lmerTest); library(ggplot2)})
src <- "../../Psani_clanku/2026/HanSpaNet"
out <- "images"

navy <- "#3B0F70"; rose <- "#B63679"; coral <- "#F8765C"; green <- "#40695B"
slate <- "#64748B"; ink <- "#1E293B"; grid_col <- "#E2E8F0"
theme_deck <- theme_minimal(base_size = 24, base_family = "sans") +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = grid_col),
        axis.text = element_text(colour = "#334155"), axis.title = element_text(colour = ink),
        legend.position = "none", plot.background = element_rect(fill = "white", colour = NA))

load(file.path(src, "data/species_spatial_metrics.rda"))
load(file.path(src, "data/species_interactions.rda"))
species_spatial_metrics <- species_spatial_metrics |> mutate(plot_id = as.character(plot_id), plant_code = as.character(plant_code))
species_interactions <- species_interactions |> mutate(plot_id = as.character(plot_id), plant_code = as.character(plant_code))

df <- species_spatial_metrics |>
  left_join(species_interactions, by = c("year", "plot_id", "plant_code")) |>
  mutate(species_visitation_rate = coalesce(species_visitation_rate, 0)) |>
  filter(!is.na(heterospecific_clumping), !is.na(heterospecific_heterogeneity), !is.na(ESI)) |>
  group_by(plant_code) |>
  mutate(species_abundance = if (n() > 1 && var(species_abundance, na.rm = TRUE) > 0)
    as.vector(scale(species_abundance)) else 0) |>
  ungroup() |>
  mutate(across(c(species_clumping, heterospecific_density, heterospecific_clumping,
                  heterospecific_heterogeneity, ESI), ~ as.vector(scale(.))),
         log_visitation = log(species_visitation_rate + 0.01),
         across(c(year, plot_id, plant_code), as.factor)) |>
  as.data.frame()

m1 <- lmer(log_visitation ~ species_abundance + species_clumping + heterospecific_density +
             heterospecific_clumping + heterospecific_heterogeneity + ESI +
             (1 | year) + (1 | plot_id) + (1 | plant_code), data = df)
cf <- as.data.frame(coef(summary(m1)))
cf$term <- rownames(cf)
ci <- confint(m1, method = "Wald")
cf <- cf |> filter(term != "(Intercept)", term != "ESI") |>
  mutate(lo = ci[term, 1], hi = ci[term, 2], p = `Pr(>|t|)`)
print(cf[, c("term", "Estimate", "lo", "hi", "p")])

lab <- c(species_abundance = "More flowers of the plant",
         species_clumping = "Its flowers in a clump",
         heterospecific_density = "More flowers of neighbours",
         heterospecific_clumping = "Neighbours in clumps",
         heterospecific_heterogeneity = "Mixed neighbourhood")
grp <- c(species_abundance = "The plant itself", species_clumping = "The plant itself",
         heterospecific_density = "Its neighbours", heterospecific_clumping = "Its neighbours",
         heterospecific_heterogeneity = "Its neighbours")
cf <- cf |> mutate(label = factor(lab[term], levels = rev(lab)),
                   group = factor(grp[term], levels = c("The plant itself", "Its neighbours")),
                   col = ifelse(hi < 0, coral, ifelse(lo > 0, green, slate)),
                   star = case_when(p < 0.001 ~ "***", p < 0.01 ~ "**", p < 0.05 ~ "*", TRUE ~ "n.s."))

p <- ggplot(cf, aes(Estimate, label)) +
  geom_vline(xintercept = 0, colour = slate, linewidth = 0.8) +
  geom_errorbarh(aes(xmin = lo, xmax = hi, colour = I(col)), height = 0, linewidth = 1.6) +
  geom_point(aes(colour = I(col)), size = 6) +
  geom_text(aes(x = hi, label = star), hjust = -0.35, size = 6.5, colour = ink) +
  facet_grid(group ~ ., scales = "free_y", space = "free_y") +
  scale_x_continuous(expand = expansion(mult = c(0.05, 0.15))) +
  labs(x = "Change in visitation rate (log scale) per 1 SD", y = NULL) +
  theme_deck +
  theme(strip.text.y = element_text(angle = 0, hjust = 0, face = "bold", size = 20, colour = ink),
        panel.spacing = unit(1.2, "lines"))
ggsave(file.path(out, "space_effects.png"), p, width = 12, height = 5.6, dpi = 200)
cat("n =", nrow(df), " plots:", nlevels(df$plot_id), " years:", nlevels(df$year), " species:", nlevels(df$plant_code), "\n")
