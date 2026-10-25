# Slide figures for Freudenfeld et al. 2025 (AoB Plants 17: plaf009)
# Redrawn from the original data in Psani_clanku/2024/Martin/martin_clanek_rko/clanek1
# Run from the Seminar_Goteborg folder:  Rscript scripts/fig_freudenfeld_2025.R
suppressMessages({library(readxl); library(ggplot2); library(dplyr); library(tidyr)})

src <- "../../Psani_clanku/2024/Martin/martin_clanek_rko/clanek1"
out <- "images"

# Deck palette (SCAPE / Göteborg theme)
green <- "#40695B"; navy <- "#3B0F70"; plum <- "#8C2981"; rose <- "#B63679"
coral <- "#F8765C"; peach <- "#FEB47B"; slate <- "#64748B"; grid_col <- "#E2E8F0"
order_cols <- c(Hymenoptera = navy, Diptera = coral, Lepidoptera = plum, Coleoptera = green)

theme_deck <- theme_minimal(base_size = 24, base_family = "sans") +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = grid_col),
        axis.text = element_text(colour = "#334155"),
        axis.title = element_text(colour = "#1E293B"),
        legend.position = "top", legend.title = element_blank(),
        plot.background = element_rect(fill = "white", colour = NA))

# ---- 1. Pollen load per individual, by pollinator group -------------------
p <- read_excel(file.path(src, "stery_zakl_tab.xlsx")) |>
  mutate(load = opr_pol_skl, order = ifelse(order %in% names(order_cols), order, "Other"))
grp <- p |>
  group_by(skup_opr, order) |>
  summarise(n = n(), m = mean(log10(load + 1)),
            se = sd(log10(load + 1)) / sqrt(n), .groups = "drop") |>
  mutate(lcl = m - 1.96 * se, ucl = m + 1.96 * se) |>
  arrange(desc(m))
p$skup_opr <- factor(p$skup_opr, levels = grp$skup_opr)
grp$skup_opr <- factor(grp$skup_opr, levels = grp$skup_opr)

base_load <- ggplot(p, aes(skup_opr, load + 1)) +
  geom_jitter(aes(colour = order), width = 0.18, height = 0, alpha = 0.35, size = 1.8, show.legend = FALSE) +
  scale_y_log10(breaks = c(1, 10, 100, 1000, 10000), labels = c("0", "10", "100", "1 000", "10 000")) +
  scale_colour_manual(values = c(order_cols, Other = slate)) +
  labs(x = NULL, y = "Pollen grains per ¼ body") +
  theme_deck +
  theme(axis.text.x = element_text(angle = 50, hjust = 1, size = 15, face = "italic"))

ggsave(file.path(out, "freud_load_1_individuals.png"), base_load, width = 11, height = 6.2, dpi = 200)

load_means <- base_load +
  geom_errorbar(data = grp, aes(x = skup_opr, ymin = 10^lcl, ymax = 10^ucl, colour = order),
                inherit.aes = FALSE, width = 0, linewidth = 1.1) +
  geom_point(data = grp, aes(x = skup_opr, y = 10^m, fill = order), inherit.aes = FALSE,
             shape = 21, colour = "white", size = 3.6, stroke = 0.8) +
  scale_fill_manual(values = c(order_cols, Other = slate)) +
  guides(fill = guide_legend(override.aes = list(size = 5))) +
  theme(legend.position = "top")
ggsave(file.path(out, "freud_load_2_means.png"), load_means, width = 11, height = 6.2, dpi = 200)

# ---- 2. Visitation density over years ------------------------------------
d <- read_excel(file.path(src, "density_roky.xlsx")) |>
  mutate(denzita = as.numeric(denzita)) |>
  filter(!is.na(denzita))
hi <- c("Apis" = navy, "Sarcophagidae" = coral, "Sphaerophoria" = rose, "Eristalis tenax" = green)
d_hi <- filter(d, skupina %in% names(hi))

dens_base <- ggplot(d, aes(rok, denzita, group = skupina)) +
  geom_line(colour = "#CBD5E1", linewidth = 0.8) +
  scale_x_continuous(breaks = 2011:2021) +
  labs(x = NULL, y = "Interaction density\n(visits per survey, all plots)") +
  theme_deck
ggsave(file.path(out, "freud_density_1_all.png"), dens_base, width = 11, height = 6.2, dpi = 200)

dens_hi <- dens_base +
  geom_line(data = d_hi, aes(colour = skupina), linewidth = 1.6) +
  geom_point(data = d_hi, aes(colour = skupina), size = 3) +
  scale_colour_manual(values = hi, breaks = names(hi)) +
  theme(legend.text = element_text(face = "italic"))
ggsave(file.path(out, "freud_density_2_highlight.png"), dens_hi, width = 11, height = 6.2, dpi = 200)

# ---- 3. Where is the variation? CV comparison ------------------------------
cv <- function(x) sd(x) / mean(x)
within_cv <- p |> group_by(skup_opr) |> filter(n() >= 5) |> summarise(cv = cv(load)) |> pull(cv)
among_cv  <- cv(p |> group_by(skup_opr) |> summarise(m = mean(load)) |> pull(m))
year_cv   <- d |> group_by(skupina) |> filter(mean(denzita) > 0) |> summarise(cv = cv(denzita)) |> pull(cv)

cvdf <- tibble(
  what = factor(c("Pollen load\namong groups", "Pollen load\namong individuals\n(within group)", "Visitation\namong years\n(within group)"),
                levels = c("Pollen load\namong groups", "Pollen load\namong individuals\n(within group)", "Visitation\namong years\n(within group)")),
  value = c(among_cv, median(within_cv), median(year_cv)),
  col = c(slate, peach, coral))
write.csv(transform(cvdf, what = gsub("\n", " ", what)), file.path("scripts", "freud_cv_values.csv"), row.names = FALSE)

cv_plot <- ggplot(cvdf, aes(what, value, fill = col)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = sprintf("%.2f", value)), vjust = -0.4, size = 7, colour = "#1E293B") +
  scale_fill_identity() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(x = NULL, y = "Coefficient of variation") +
  theme_deck
ggsave(file.path(out, "freud_cv.png"), cv_plot, width = 9, height = 6.2, dpi = 200)

print(cvdf[, 1:2])
cat("groups:", nlevels(p$skup_opr), " individuals:", nrow(p), " density groups:", length(unique(d$skupina)), "\n")
