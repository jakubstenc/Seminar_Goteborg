# Slide figure: cumulative pollen deposition (AUC) by mating system, SI vs SIC.
# Same data preparation and AUC definition as
#   Psani_clanku/2026/Pollen_Deposition_Curves/statistical_analysis.qmd (section 2)
# Run from the Seminar_Goteborg folder:  Rscript scripts/fig_deposition_auc.R
suppressMessages({library(readr); library(dplyr); library(tidyr); library(stringr); library(ggplot2); library(patchwork)})
src <- "../../Psani_clanku/2026/Pollen_Deposition_Curves"
out <- "images"

green <- "#40695B"; navy <- "#3B0F70"; plum <- "#8C2981"; coral <- "#F8765C"
peach <- "#FEB47B"; slate <- "#64748B"; grid_col <- "#E2E8F0"
ms_cols <- c(SI = navy, SIC = coral)
theme_deck <- theme_minimal(base_size = 24, base_family = "sans") +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = grid_col),
        axis.text = element_text(colour = "#334155"), axis.title = element_text(colour = "#1E293B"),
        legend.position = "none", plot.background = element_rect(fill = "white", colour = NA))

# ---- data preparation (identical to statistical_analysis.qmd) ----------------
parse_flower_age <- function(x) {
  x_clean <- str_extract(as.character(x), "^[0-9:.]+")
  sapply(x_clean, function(val) {
    if (is.na(val)) return(NA_real_)
    parts <- as.numeric(str_split(val, ":")[[1]])
    if (length(parts) == 1) return(parts[1])
    if (length(parts) == 2) return(parts[1] + parts[2] / 60)
    if (length(parts) == 3) return(parts[1] + parts[2] / 60 + parts[3] / 3600)
    NA_real_
  }, USE.NAMES = FALSE)
}

df_clean <- read_csv(file.path(src, "data/species_traits.csv"), show_col_types = FALSE) |>
  rename(sexual_system = `sexual system`) |>
  mutate(flower_age_num = parse_flower_age(flower_age_hours),
         pollen_deposition_mean = as.numeric(pollen_deposition_mean),
         maximum_longevity = as.numeric(maximum_longevity),
         survey_id = ifelse(is.na(survey_identifier), Species, paste(Species, survey_identifier, sep = " - ")),
         mating_system = replace_na(mating_system, "Unknown"),
         life_form = replace_na(life_form, "Unknown")) |>
  filter(!is.na(flower_age_num), !is.na(pollen_deposition_mean)) |>
  group_by(survey_id) |>
  mutate(max_dep = max(pollen_deposition_mean, na.rm = TRUE),
         std_dep_max = ifelse(max_dep > 0, pollen_deposition_mean / max_dep, NA_real_),
         max_age_ref = ifelse(!is.na(first(maximum_longevity)), first(maximum_longevity),
                              max(flower_age_num, na.rm = TRUE)),
         std_flower_age = flower_age_num / max_age_ref) |>
  ungroup()

auc_trapz <- function(x, y) {
  ok <- complete.cases(x, y); x <- x[ok]; y <- y[ok]
  o <- order(x); x <- x[o]; y <- y[o]
  if (length(x) < 2) return(NA_real_)
  sum(diff(x) * (head(y, -1) + tail(y, -1)) / 2)
}

df_auc <- df_clean |>
  group_by(survey_id) |>
  summarise(Species = first(Species), mating_system = first(mating_system),
            life_form = first(life_form),
            n_tp = sum(!is.na(std_dep_max)),
            age_cover = max(std_flower_age, na.rm = TRUE) - min(std_flower_age, na.rm = TRUE),
            auc = auc_trapz(std_flower_age, std_dep_max), .groups = "drop")

# ---- Wilcoxon tests, BH-adjusted over the same 4 contrasts as the analysis ---
wt <- function(col, g1, g2) {
  x <- na.omit(df_auc$auc[df_auc[[col]] == g1]); y <- na.omit(df_auc$auc[df_auc[[col]] == g2])
  tibble(contrast = paste(g1, "vs", g2), n1 = length(x), n2 = length(y),
         med1 = median(x), med2 = median(y), p = wilcox.test(x, y, exact = FALSE)$p.value)
}
tests <- bind_rows(wt("mating_system", "SI", "SIC"), wt("mating_system", "SI", "SC"),
                   wt("mating_system", "SC", "SIC"), wt("life_form", "semelparous", "iteroparous")) |>
  mutate(p_adj = p.adjust(p, "BH"))
print(tests)
si_sic <- tests[1, ]

# ---- panel A: what the AUC is (one example survey per mating system) --------
d2 <- filter(df_auc, mating_system %in% names(ms_cols), !is.na(auc))
cat("Sampling coverage of flower life (share of max. longevity):\n")
print(d2 |> group_by(mating_system) |>
        summarise(n = n(), med_timepoints = median(n_tp), med_age_cover = median(age_cover)))
example_ids <- d2 |>
  filter(n_tp >= 4) |>
  group_by(mating_system) |>
  slice_min(abs(auc - median(d2$auc[d2$mating_system == first(mating_system)])), n = 1, with_ties = FALSE) |>
  pull(survey_id)
ex <- df_clean |>
  filter(survey_id %in% example_ids) |>
  left_join(select(df_auc, survey_id, auc), by = "survey_id") |>
  arrange(survey_id, std_flower_age) |>
  mutate(mating_system = factor(mating_system, levels = names(ms_cols)))
strip_lab <- ex |> group_by(mating_system) |>
  summarise(lab = sprintf("%s  \u00b7  AUC %.2f\n%s", first(mating_system), first(auc), first(Species)),
            .groups = "drop")
strip_lab <- setNames(strip_lab$lab, strip_lab$mating_system)

pA <- ggplot(ex, aes(std_flower_age, std_dep_max, colour = mating_system, fill = mating_system)) +
  geom_area(alpha = 0.25, position = "identity", colour = NA) +
  geom_line(linewidth = 1.4) +
  geom_point(size = 2.5) +
  facet_wrap(~mating_system, ncol = 1, labeller = as_labeller(strip_lab)) +
  scale_colour_manual(values = ms_cols) + scale_fill_manual(values = ms_cols) +
  scale_x_continuous(breaks = c(0, 0.5, 1), labels = c("0", "0.5", "1")) +
  scale_y_continuous(breaks = c(0, 0.5, 1), limits = c(0, 1.02)) +
  labs(x = "Relative flower age", y = "Deposition (share of max.)") +
  theme_deck +
  theme(strip.text = element_text(size = 17, face = "bold", hjust = 0, colour = "#1E293B"),
        axis.title = element_text(size = 19), axis.text = element_text(size = 16))

# ---- panel B: AUC per survey, SI vs SIC -------------------------------------
d2 <- d2 |> mutate(mating_system = factor(mating_system, levels = names(ms_cols)))
meds <- d2 |> group_by(mating_system) |> summarise(med = median(auc), n = n(), .groups = "drop")
lab_p <- sprintf("Wilcoxon, adj. p = %.3f", si_sic$p_adj)

pB <- ggplot(d2, aes(mating_system, auc, colour = mating_system)) +
  geom_crossbar(data = meds, aes(y = med, ymin = med, ymax = med), width = 0.5, linewidth = 0.9) +
  geom_point(position = position_jitter(width = 0.12, height = 0, seed = 7), size = 4.5, alpha = 0.75) +
  geom_text(data = meds, aes(y = -0.1, label = paste("n =", n)), colour = slate, size = 6) +
  annotate("segment", x = 1, xend = 2, y = 1.08, yend = 1.08, colour = slate, linewidth = 0.8) +
  annotate("text", x = 1.5, y = 1.15, label = lab_p, size = 6, colour = "#1E293B") +
  scale_colour_manual(values = ms_cols) +
  scale_x_discrete(labels = c(SI = "Self-incompatible\n(SI)", SIC = "Self-incompatible/\ncompatible (SIC)")) +
  scale_y_continuous(limits = c(-0.12, 1.2), breaks = seq(0, 1, 0.25)) +
  labs(x = NULL, y = "Area under the deposition curve") +
  theme_deck

p <- pA + pB + plot_layout(widths = c(1, 1.5))
ggsave(file.path(out, "deposition_auc_mating.png"), p, width = 12, height = 6.6, dpi = 200)
print(meds)
cat("Examples:", example_ids, "\n")

# ---- 2. Does the stigma get enough pollen for all ovules? (max P/O per survey) ----
po <- df_clean |>
  mutate(po = pollen_deposition_mean / as.numeric(ovule_number_per_flower)) |>
  filter(is.finite(po), mating_system %in% names(ms_cols)) |>
  group_by(survey_id, mating_system) |>
  summarise(Species = first(Species), max_po = max(po), .groups = "drop") |>
  mutate(mating_system = factor(mating_system, levels = names(ms_cols)))
po_sum <- po |> group_by(mating_system) |>
  summarise(n = n(), k = sum(max_po >= 1), .groups = "drop") |>
  mutate(label = sprintf("%d of %d surveys\nreach P/O \u2265 1", k, n))
print(po_sum)

p_po <- ggplot(po, aes(mating_system, max_po, colour = mating_system)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0.05, ymax = 1, fill = "#F1F5F9") +
  geom_hline(yintercept = 1, linetype = "dashed", colour = slate, linewidth = 0.9) +
  annotate("text", x = 2.55, y = 1.25, label = "1 pollen grain per ovule", hjust = 1, vjust = 0,
           size = 5.5, colour = slate) +
  annotate("text", x = 2.55, y = 0.8, label = "too little pollen", hjust = 1, vjust = 1,
           size = 5.5, colour = slate, fontface = "italic") +
  geom_point(position = position_jitter(width = 0.12, height = 0, seed = 3), size = 5, alpha = 0.8) +
  geom_text(data = po_sum, aes(y = 300, label = label), size = 6.5, lineheight = 0.95, fontface = "bold") +
  scale_colour_manual(values = ms_cols) +
  scale_x_discrete(labels = c(SI = "Self-incompatible\n(SI)", SIC = "Self-incompatible/\ncompatible (SIC)")) +
  scale_y_log10(limits = c(0.05, 900), breaks = c(0.1, 1, 10, 100), labels = c("0.1", "1", "10", "100")) +
  labs(x = NULL, y = "Highest pollen : ovule ratio\nreached on the stigma") +
  theme_deck
ggsave(file.path(out, "deposition_po_max.png"), p_po, width = 12, height = 6.6, dpi = 200)
