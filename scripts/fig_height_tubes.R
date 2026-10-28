# Slide figures: plant height, pollen deposition and pollen tubes (2026, with K. Hodánková & J. Valverde)
# Data: FEG/Klara_Hodankova/data ; models follow scripts/analyze_plant_heights.R there
# Run from the Seminar_Goteborg folder:  Rscript scripts/fig_height_tubes.R
suppressMessages({library(ggplot2); library(dplyr); library(tidyr); library(lme4); library(glmmTMB); library(ggeffects)})
src <- "../../FEG/Klara_Hodankova/data"; out <- "images"
green <- "#40695B"; navy <- "#3B0F70"; plum <- "#8C2981"; coral <- "#F8765C"; slate <- "#64748B"; grid_col <- "#E2E8F0"
theme_deck <- theme_minimal(base_size = 24, base_family = "sans") +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_blank(),
        axis.text = element_text(colour = "#334155"), axis.title = element_text(colour = "#1E293B"),
        plot.background = element_rect(fill = "white", colour = NA))

h <- read.csv(file.path(src, "Plant_heights.csv"))
hl <- h |> pivot_longer(-plant, values_to = "height") |> mutate(height = as.numeric(height)) |> filter(!is.na(height))
cat("Inflorescences:", nrow(hl), " plants:", n_distinct(hl$plant), " median height:", median(hl$height), "\n")

d <- read.csv(file.path(src, "Pollen_height.csv")) |>
  mutate(across(c(plant_height, pollen, tubes), as.numeric), plant = factor(plant), flower = factor(flower)) |>
  filter(!is.na(plant_height), !is.na(pollen), pollen >= 0)
cat("Stigmas:", nrow(d), " plants:", n_distinct(d$plant), "\n")

# Pollen ~ height (quadratic, NB vs Poisson as in original script)
m_nb <- glmmTMB(pollen ~ poly(plant_height, 2) + (1 | plant / flower), data = d, family = nbinom2)
m_po <- glmer(pollen ~ poly(plant_height, 2) + (1 | plant / flower), data = d, family = poisson)
best <- if (AIC(m_nb) < AIC(m_po)) m_nb else m_po
cat("Pollen model:", class(best)[1], "\n"); print(summary(best)$coefficients)
pp <- as.data.frame(ggpredict(best, terms = "plant_height [all]"))
cat("Peak of predicted deposition at height:", pp$x[which.max(pp$predicted)], "cm\n")

# Proportion of grains with tubes ~ height (binomial)
dt <- d |> filter(!is.na(tubes), pollen > 0) |> mutate(prop = tubes / pollen)
m_bin <- glmer(cbind(tubes, pollen - tubes) ~ plant_height + (1 | plant / flower), data = dt, family = binomial)
print(summary(m_bin)$coefficients)
pb <- as.data.frame(ggpredict(m_bin, terms = "plant_height [all]"))
cat("Predicted tube proportion at 15 cm and 65 cm:", round(approx(pb$x, pb$predicted, c(15, 65))$y, 2), "\n")

xl <- range(c(hl$height, d$plant_height))
p1 <- ggplot(hl, aes(height)) + geom_histogram(binwidth = 5, boundary = 0, fill = "#CBD5E1", colour = "white") +
  scale_x_continuous(limits = xl) + labs(x = "Inflorescence height (cm)", y = "Inflorescences") + theme_deck
ggsave(file.path(out, "ht_height_distribution.png"), p1, width = 9, height = 4, dpi = 200)
ggsave(file.path("docs", out, "ht_height_distribution.png"), p1, width = 9, height = 4, dpi = 200)

p2 <- ggplot(d, aes(plant_height, pollen)) +
  geom_ribbon(data = pp, aes(x = x, ymin = conf.low, ymax = conf.high), inherit.aes = FALSE, fill = green, alpha = 0.15) +
  geom_point(colour = green, alpha = 0.55, size = 3) +
  geom_line(data = pp, aes(x, predicted), inherit.aes = FALSE, colour = green, linewidth = 1.6) +
  scale_x_continuous(limits = xl) + labs(x = "Plant height (cm)", y = "Own pollen grains per stigma") + theme_deck
ggsave(file.path(out, "ht_pollen_height.png"), p2, width = 9, height = 6, dpi = 200)
ggsave(file.path("docs", out, "ht_pollen_height.png"), p2, width = 9, height = 6, dpi = 200)

p3 <- ggplot(dt, aes(plant_height, prop)) +
  geom_ribbon(data = pb, aes(x = x, ymin = conf.low, ymax = conf.high), inherit.aes = FALSE, fill = coral, alpha = 0.18) +
  geom_point(colour = coral, alpha = 0.6, size = 3) +
  geom_line(data = pb, aes(x, predicted), inherit.aes = FALSE, colour = coral, linewidth = 1.6) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  scale_x_continuous(limits = xl) + labs(x = "Plant height (cm)", y = "Grains with a pollen tube") + theme_deck
ggsave(file.path(out, "ht_tubes_height.png"), p3, width = 9, height = 6, dpi = 200)
ggsave(file.path("docs", out, "ht_tubes_height.png"), p3, width = 9, height = 6, dpi = 200)

# ---- Step figures with population height distribution as context --------
m_tnb <- glmmTMB(tubes ~ poly(plant_height, 2) + (1 | plant / flower), data = filter(d, !is.na(tubes)), family = nbinom2)
m_tpo <- glmer(tubes ~ poly(plant_height, 2) + (1 | plant / flower), data = filter(d, !is.na(tubes)), family = poisson)
bt <- if (AIC(m_tnb) < AIC(m_tpo)) m_tnb else m_tpo
cat("Tube count model:", class(bt)[1], "\n"); print(coef(summary(bt)))
pt <- as.data.frame(ggpredict(bt, terms = "plant_height [all]"))
cat("Peak of predicted tube number at height:", pt$x[which.max(pt$predicted)], "cm\n")
cat("Share of inflorescences 25-40 cm:", round(mean(hl$height >= 25 & hl$height <= 40), 2),
    " above 50 cm:", round(mean(hl$height > 50), 2), "\n")

ymax <- 80
hb <- hl |> mutate(bin = cut(height, breaks = seq(5, 75, 5))) |> count(bin) |>
  mutate(mid = seq(7.5, 72.5, 5)[as.integer(bin)], y = n / max(n) * ymax * 0.55)
bg <- geom_col(data = hb, aes(mid, y), inherit.aes = FALSE, width = 4.6, fill = "#E2E8F0")
xs <- scale_x_continuous(limits = c(5, 75), breaks = seq(10, 70, 10))
med <- median(hl$height)

sA <- ggplot() + geom_col(data = hb, aes(mid, n), width = 4.6, fill = "#94A3B8") +
  geom_vline(xintercept = med, linetype = "dashed", colour = navy, linewidth = 1) +
  annotate("text", x = med + 1.5, y = max(hb$n) * 0.95, label = paste0("median ", med, " cm"), hjust = 0, colour = navy, size = 7) +
  xs + labs(x = "Inflorescence height (cm)", y = "Inflorescences") + theme_deck
ggsave(file.path(out, "ht_step1_distribution.png"), sA, width = 10, height = 6, dpi = 200)
ggsave(file.path("docs", out, "ht_step1_distribution.png"), sA, width = 10, height = 6, dpi = 200)

base <- ggplot() + bg + xs + coord_cartesian(ylim = c(0, ymax)) +
  labs(x = "Plant height (cm)", y = "Grains per stigma") + theme_deck +
  theme(legend.position = "top", legend.title = element_blank())
sB <- base +
  geom_ribbon(data = pp, aes(x, ymin = conf.low, ymax = conf.high), fill = green, alpha = 0.15) +
  geom_point(data = d, aes(plant_height, pollen, colour = "Pollen grains"), alpha = 0.55, size = 3) +
  geom_line(data = pp, aes(x, predicted, colour = "Pollen grains"), linewidth = 1.6) +
  scale_colour_manual(values = c("Pollen grains" = green, "Pollen tubes" = plum))
ggsave(file.path(out, "ht_step2_pollen.png"), sB, width = 10, height = 6, dpi = 200)
ggsave(file.path("docs", out, "ht_step2_pollen.png"), sB, width = 10, height = 6, dpi = 200)
# no CI ribbon for tube counts: ggpredict CI from the observation-level random effect is uninformative
sC <- sB +
  geom_point(data = filter(d, !is.na(tubes)), aes(plant_height, tubes, colour = "Pollen tubes"), alpha = 0.55, size = 3, shape = 17) +
  geom_line(data = pt, aes(x, predicted, colour = "Pollen tubes"), linewidth = 1.6)
ggsave(file.path(out, "ht_step3_tubes.png"), sC, width = 10, height = 6, dpi = 200)
ggsave(file.path("docs", out, "ht_step3_tubes.png"), sC, width = 10, height = 6, dpi = 200)

hb2 <- hb |> mutate(y = n / max(n) * 0.55)
sD <- ggplot() + geom_col(data = hb2, aes(mid, y), width = 4.6, fill = "#E2E8F0") +
  geom_ribbon(data = pb, aes(x, ymin = conf.low, ymax = conf.high), fill = coral, alpha = 0.18) +
  geom_point(data = dt, aes(plant_height, prop), colour = coral, alpha = 0.6, size = 3) +
  geom_line(data = pb, aes(x, predicted), colour = coral, linewidth = 1.6) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) + xs +
  labs(x = "Plant height (cm)", y = "Grains with a pollen tube") + theme_deck
ggsave(file.path(out, "ht_step4_proportion.png"), sD, width = 10, height = 6, dpi = 200)
ggsave(file.path("docs", out, "ht_step4_proportion.png"), sD, width = 10, height = 6, dpi = 200)
