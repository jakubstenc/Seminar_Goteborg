# Slide figures: pollinator behaviour (constancy synthesis, Eristalis artificial flowers)
# and yearly Succisa stigma loads vs drought.
# Run from the Seminar_Goteborg folder:  Rscript scripts/fig_behaviour_deposition.R
suppressMessages({library(ggplot2); library(dplyr); library(tidyr)})
pc <- "../../Psani_clanku"
out <- "images"

green <- "#40695B"; navy <- "#3B0F70"; plum <- "#8C2981"; rose <- "#B63679"
coral <- "#F8765C"; peach <- "#FEB47B"; slate <- "#64748B"; grid_col <- "#E2E8F0"
yellow_fl <- "#F2C200"
theme_deck <- theme_minimal(base_size = 24, base_family = "sans") +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = grid_col),
        axis.text = element_text(colour = "#334155"), axis.title = element_text(colour = "#1E293B"),
        legend.position = "top", legend.title = element_blank(),
        plot.background = element_rect(fill = "white", colour = NA))

# ---- 1. Flower constancy across pollinator groups (synthesis, in prep.) ----
v <- read.table(file.path(pc, "2025/Constancy_Preference_2025/data/Stenc_Janovsky_2025_dataset.txt"),
                header = TRUE, sep = "\t", stringsAsFactors = TRUE) |>
  filter(method != "natural pop.")
v$poll.group <- factor(v$poll.group, levels = c("honeybee", "bumblebees", "oth. bees", "butterflies", "hoverflies"),
                       labels = c("Honeybee", "Bumblebees", "Other bees", "Butterflies", "Hoverflies"))
m <- glm(cbind(const.trans, n.tot - const.trans) ~ poll.group, data = v, family = quasibinomial)
nd <- data.frame(poll.group = levels(v$poll.group))
pr <- predict(m, nd, type = "link", se.fit = TRUE)
nd <- nd |> mutate(fit = plogis(pr$fit), lcl = plogis(pr$fit - 2 * pr$se.fit), ucl = plogis(pr$fit + 2 * pr$se.fit),
                   n = as.vector(table(v$poll.group)),
                   poll.group = factor(poll.group, levels = levels(v$poll.group)))
v$prop <- v$const.trans / v$n.tot
grp_cols <- c(Honeybee = navy, Bumblebees = plum, `Other bees` = rose, Butterflies = peach, Hoverflies = coral)
pconst <- ggplot(nd, aes(poll.group, fit, colour = poll.group)) +
  geom_jitter(data = v, aes(y = prop), width = 0.15, height = 0, alpha = 0.35, size = 2.5) +
  geom_errorbar(aes(ymin = lcl, ymax = ucl), width = 0, linewidth = 1.4) +
  geom_point(size = 6) +
  geom_text(aes(y = -0.07, label = paste("n =", n)), colour = slate, size = 6) +
  scale_colour_manual(values = grp_cols, guide = "none") +
  scale_y_continuous(limits = c(-0.1, 1), breaks = seq(0, 1, 0.25)) +
  labs(x = NULL, y = "Decisions due to flower constancy") +
  theme_deck
ggsave(file.path(out, "behav_constancy_groups.png"), pconst, width = 10, height = 6.2, dpi = 200)
cat("Constancy GLM:\n"); print(anova(m, test = "F")); print(nd)

# ---- 2. Eristalis tenax: visits to yellow forms, naive vs experienced ------
# Visit counts per flower form from Haveldová et al. (submitted), Results section
vis <- tibble(group = c("Naive", "Naive", "Experienced", "Experienced"),
              colour = c("Yellow", "White", "Yellow", "White"),
              visits = c(1829 + 1682, 693 + 637, 8000 + 7855, 8857 + 7261)) |>
  group_by(group) |> mutate(share = visits / sum(visits)) |> ungroup() |>
  mutate(group = factor(group, levels = c("Naive", "Experienced")),
         colour = factor(colour, levels = c("White", "Yellow")))
pyel <- ggplot(vis, aes(group, share, fill = colour)) +
  geom_col(width = 0.6, colour = "#CBD5E1") +
  geom_hline(yintercept = 0.5, linetype = "dashed", colour = slate) +
  geom_text(data = filter(vis, colour == "Yellow"), aes(y = share / 2, label = scales::percent(share, 1)),
            size = 9, colour = "#1E293B", fontface = "bold") +
  scale_fill_manual(values = c(White = "#FFFFFF", Yellow = yellow_fl)) +
  scale_y_continuous(labels = scales::percent, breaks = seq(0, 1, 0.25)) +
  labs(x = NULL, y = "Share of visits") +
  theme_deck + theme(legend.position = "right")
ggsave(file.path(out, "behav_yellow_share.png"), pyel, width = 8, height = 6.2, dpi = 200)
print(vis)

# ---- 3. Succisa stigma loads per year vs summer drought --------------------
dep <- read.csv(file.path(pc, "2025/Linking-Network-Structure-to-Pollen-Deposition-Mechanisms/data/pollen_deposition.csv"))
dsum <- dep |>
  pivot_longer(c(conspecific_pollen, heterospecific_pollen), names_to = "type", values_to = "grains") |>
  group_by(year, type) |>
  filter(!is.na(grains)) |>
  summarise(m = mean(grains), se = sd(grains) / sqrt(n()), n = n(), .groups = "drop") |>
  mutate(type = recode(type, conspecific_pollen = "Conspecific (own)", heterospecific_pollen = "Heterospecific (foreign)"))
pdep <- ggplot(dsum, aes(year, m, colour = type, group = type)) +
  scale_x_continuous(breaks = 2022:2024) +
  geom_line(linewidth = 1.6) +
  geom_errorbar(aes(ymin = m - se, ymax = m + se), width = 0, linewidth = 1.2) +
  geom_point(size = 5) +
  scale_colour_manual(values = c(`Conspecific (own)` = green, `Heterospecific (foreign)` = coral)) +
  expand_limits(y = 0) +
  labs(x = NULL, y = "Pollen grains per stigma") +
  theme_deck
ggsave(file.path(out, "dep_cp_hp_years.png"), pdep, width = 9, height = 6.2, dpi = 200)
print(dsum)
