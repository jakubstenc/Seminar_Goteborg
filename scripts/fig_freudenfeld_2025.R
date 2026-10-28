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
        panel.grid.major.y = element_blank(),
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

# The base plot already contains the (invisible) mean layer, CI range and legend,
# so both fragment images have exactly the same panel position and y range.
base_load <- ggplot(p, aes(skup_opr, load + 1)) +
  geom_point(aes(colour = order), position = position_jitter(width = 0.18, height = 0, seed = 42),
             alpha = 0.35, size = 1.8, show.legend = FALSE) +
  geom_blank(data = grp, aes(x = skup_opr, y = 10^lcl), inherit.aes = FALSE) +
  geom_blank(data = grp, aes(x = skup_opr, y = 10^ucl), inherit.aes = FALSE) +
  geom_point(data = grp, aes(x = skup_opr, y = 10^m, fill = order), inherit.aes = FALSE,
             shape = 21, colour = "transparent", size = 3.6, alpha = 0) +
  scale_y_log10(breaks = c(1, 10, 100, 1000, 10000), labels = c("0", "10", "100", "1 000", "10 000")) +
  scale_colour_manual(values = c(order_cols, Other = slate)) +
  scale_fill_manual(values = c(order_cols, Other = slate)) +
  guides(fill = guide_legend(override.aes = list(size = 5, alpha = 0))) +
  labs(x = NULL, y = "Pollen grains per ¼ body") +
  theme_deck +
  theme(axis.text.x = element_text(angle = 50, hjust = 1, size = 15, face = "italic"),
        legend.text = element_text(colour = "transparent"))

ggsave(file.path(out, "freud_load_1_individuals.png"), base_load, width = 11, height = 6.2, dpi = 200)
ggsave(file.path("docs", out, "freud_load_1_individuals.png"), base_load, width = 11, height = 6.2, dpi = 200)

load_means <- base_load +
  geom_errorbar(data = grp, aes(x = skup_opr, ymin = 10^lcl, ymax = 10^ucl, colour = order),
                inherit.aes = FALSE, width = 0, linewidth = 1.1) +
  geom_point(data = grp, aes(x = skup_opr, y = 10^m, fill = order), inherit.aes = FALSE,
             shape = 21, colour = "white", size = 3.6, stroke = 0.8) +
  guides(fill = guide_legend(override.aes = list(size = 5, alpha = 1))) +
  theme(legend.text = element_text(colour = "black"))
ggsave(file.path(out, "freud_load_2_means.png"), load_means, width = 11, height = 6.2, dpi = 200)
ggsave(file.path("docs", out, "freud_load_2_means.png"), load_means, width = 11, height = 6.2, dpi = 200)

# Step 3: coefficients of variation for pollen load
cv <- function(x) sd(x) / mean(x)
within_cv <- p |> group_by(skup_opr) |> filter(n() >= 5) |> summarise(cv = cv(load)) |> pull(cv)
among_cv  <- cv(p |> group_by(skup_opr) |> summarise(m = mean(load)) |> pull(m))

load_cv <- load_means +
  annotate("label", x = 0.7, y = 10^0.5, hjust = 0, size = 6.5, fill = "white", colour = "#1E293B",
           border.colour = "transparent", lineheight = 1.1,
           label = sprintf("CV among groups:  %.2f\nCV within groups (median):  %.2f", among_cv, median(within_cv)))
ggsave(file.path(out, "freud_load_3_cv.png"), load_cv, width = 11, height = 6.2, dpi = 200)
ggsave(file.path("docs", out, "freud_load_3_cv.png"), load_cv, width = 11, height = 6.2, dpi = 200)

# ---- 2. Visitation density over years ------------------------------------
d <- read_excel(file.path(src, "density_roky.xlsx")) |>
  mutate(denzita = as.numeric(denzita)) |>
  filter(!is.na(denzita))
hi <- c("Apis" = navy, "Sarcophagidae" = coral, "Sphaerophoria" = rose, "Eristalis tenax" = green)
d_hi <- filter(d, skupina %in% names(hi))

# Clean plot without background grey curves and without horizontal gridlines
dens_hi <- ggplot(d_hi, aes(rok, denzita, group = skupina)) +
  geom_line(aes(colour = skupina), linewidth = 1.8) +
  geom_point(aes(colour = skupina), size = 3.6) +
  scale_colour_manual(values = hi, breaks = names(hi)) +
  scale_x_continuous(breaks = 2011:2021) +
  scale_y_continuous(limits = c(0, 215), breaks = seq(0, 200, by = 50), expand = c(0, 0)) +
  labs(x = NULL, y = "Interaction density\n(visits per survey, all plots)") +
  theme_deck +
  theme(legend.text = element_text(face = "italic", colour = "black", size = 20))

ggsave(file.path(out, "freud_density_1_all.png"), dens_hi, width = 11, height = 6.2, dpi = 200)
ggsave(file.path("docs", out, "freud_density_1_all.png"), dens_hi, width = 11, height = 6.2, dpi = 200)
ggsave(file.path(out, "freud_density_2_highlight.png"), dens_hi, width = 11, height = 6.2, dpi = 200)
ggsave(file.path("docs", out, "freud_density_2_highlight.png"), dens_hi, width = 11, height = 6.2, dpi = 200)

# Step 3: CV across years (highlighted groups + median of all groups)
year_cv_tab <- d |> group_by(skupina) |> filter(mean(denzita) > 0) |> summarise(cv = cv(denzita))
year_cv <- year_cv_tab$cv
hi_cv <- year_cv_tab |> filter(skupina %in% names(hi)) |>
  mutate(skupina = factor(skupina, levels = names(hi))) |> arrange(skupina)

# Text stays inside the existing data range (x 2011-2021, y 0-215)
y_top <- 195; step <- 13
cv_rows <- tibble(
  name = c(as.character(hi_cv$skupina), sprintf("Median, all %d groups", length(year_cv))),
  value = sprintf("%.2f", c(hi_cv$cv, median(year_cv))),
  col = c(unname(hi[as.character(hi_cv$skupina)]), "#1E293B"),
  face = c(rep("italic", nrow(hi_cv)), "bold"),
  y = y_top - step * (seq_len(nrow(hi_cv) + 1)))

dens_cv <- dens_hi +
  annotate("text", x = 2011, y = y_top, label = "CV across years", hjust = 0, size = 6.5,
           colour = "#1E293B", fontface = "bold") +
  annotate("text", x = 2011, y = cv_rows$y, label = cv_rows$name, hjust = 0, size = 6,
           colour = cv_rows$col, fontface = cv_rows$face) +
  annotate("text", x = 2015.4, y = cv_rows$y, label = cv_rows$value, hjust = 1, size = 6,
           colour = cv_rows$col, fontface = ifelse(cv_rows$face == "bold", "bold", "plain"))
ggsave(file.path(out, "freud_density_3_cv.png"), dens_cv, width = 11, height = 6.2, dpi = 200)
ggsave(file.path("docs", out, "freud_density_3_cv.png"), dens_cv, width = 11, height = 6.2, dpi = 200)

# ---- 3. Where is the variation? CV comparison ------------------------------

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
ggsave(file.path("docs", out, "freud_cv.png"), cv_plot, width = 9, height = 6.2, dpi = 200)

print(cvdf[, 1:2])
cat("groups:", nlevels(p$skup_opr), " individuals:", nrow(p), " density groups:", length(unique(d$skupina)), "\n")
