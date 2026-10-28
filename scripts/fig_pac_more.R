# Slide figures: more on the potential for apparent competition (PAC, Müller's index)
#  1. pac_net_roles.png    who drives whom: net PAC role (outgoing - incoming) per plant, 15-year mean
#  2. pac_turnover.png     drought locks the sharing network: turnover vs abundance null
#  3. pac_nmds.png         pulse (drought) and press (decade) in PAC structure
# Data / results: Psani_clanku/2025/Annual_dynamics_pollinator_sharing
# Run from the Seminar_Goteborg folder:  Rscript scripts/fig_pac_more.R
suppressMessages({library(dplyr); library(tidyr); library(purrr); library(ggplot2); library(bipartite)})
src <- "../../Psani_clanku/2025/Annual_dynamics_pollinator_sharing"
out <- "images"
navy <- "#3B0F70"; plum <- "#8C2981"; rose <- "#B63679"; coral <- "#F8765C"; peach <- "#FEB47B"
green <- "#40695B"; slate <- "#64748B"; ink <- "#1E293B"; grid_col <- "#E2E8F0"
theme_deck <- theme_minimal(base_size = 24, base_family = "sans") +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = grid_col),
        axis.text = element_text(colour = "#334155"), axis.title = element_text(colour = ink),
        legend.position = "none", plot.background = element_rect(fill = "white", colour = NA))
core <- c("Centaurea jacea", "Selinum carvifolia", "Succisa pratensis", "Pimpinella saxifraga",
          "Achillea ptarmica", "Ranunculus acris")

# ---- 1. net PAC role ------------------------------------------------------------------
int <- read.csv(file.path(src, "data/published_data/annual_sharing_interactions.csv"))
roles <- int |> filter(!is.na(Standardized_rate), Standardized_rate > 0) |>
  group_by(Year, Plant_species, Insect_species) |>
  summarise(rate = sum(Standardized_rate), .groups = "drop") |>
  group_by(Year) |> group_split() |>
  map_dfr(function(df) {
    m <- df |> select(-Year) |> pivot_wider(names_from = Insect_species, values_from = rate, values_fill = 0)
    mat <- as.matrix(m[, -1]); rownames(mat) <- m$Plant_species
    pac <- suppressWarnings(bipartite::PAC(mat)); diag(pac) <- 0
    tibble(Year = df$Year[1], Plant_species = rownames(pac),
           driver = colSums(pac, na.rm = TRUE), target = rowSums(pac, na.rm = TRUE))
  }) |> mutate(net = driver - target)
# species present in >= 10 of 15 years
sp <- roles |> group_by(Plant_species) |>
  summarise(n = n(), mean = mean(net), lo = quantile(net, 0.25), hi = quantile(net, 0.75),
            drv = mean(driver), tgt = mean(target), .groups = "drop") |>
  filter(n >= 10) |>
  mutate(core = Plant_species %in% core,
         lab = sub("^(\\w)\\w+ ", "\\1. ", Plant_species),
         lab = factor(lab, levels = lab[order(mean)]))
print(sp |> arrange(desc(mean)), n = 50)
cat("share of species-years with net > 0: core", mean(roles$net[roles$Plant_species %in% core] > 0),
    " periphery", mean(roles$net[!roles$Plant_species %in% core] > 0), "\n")

p1 <- ggplot(sp, aes(mean, lab, colour = I(ifelse(core, green, slate)))) +
  geom_vline(xintercept = 0, colour = slate, linewidth = 0.8) +
  geom_segment(aes(x = lo, xend = hi, yend = lab), linewidth = 1.6, alpha = 0.6) +
  geom_point(aes(size = I(ifelse(core, 5.5, 4)))) +
  annotate("text", x = 2.2, y = 13, hjust = 0, size = 6.5, colour = green, fontface = "bold", lineheight = 0.95,
           label = "drivers →\ntheir pollinators visit everyone") +
  annotate("text", x = 0.15, y = 5, hjust = 0, size = 6.5, colour = slate, fontface = "bold", lineheight = 0.95,
           label = "← targets\nvisited by pollinators fed elsewhere") +
  labs(x = "Net PAC role (outgoing − incoming), 15-year mean", y = NULL) +
  theme_deck +
  theme(panel.grid.major.y = element_blank(),
        axis.text.y = element_text(face = "italic", size = 15,
                                   colour = ifelse(levels(sp$lab) %in% sp$lab[sp$core], green, "#334155")))
ggsave(file.path(out, "pac_net_roles.png"), p1, width = 12, height = 6.6, dpi = 200)

# ---- 2. turnover vs abundance null ----------------------------------------------------
tv <- read.csv(file.path(src, "outputs/Data_Prep/pac_turnover_vs_null.csv")) |>
  mutate(lab = paste0(Transition_Start, "–", substr(Transition_End, 3, 4)),
         drought = -spei_min,
         lab = factor(lab, levels = lab))
fit <- nlme::gls(dev_ab ~ spei_min, data = tv, correlation = nlme::corAR1())
print(summary(fit)$tTable)
p2 <- ggplot(tv, aes(lab, dev_ab * 100, fill = drought)) +
  geom_hline(yintercept = 0, colour = slate, linewidth = 0.8) +
  geom_col(width = 0.7) +
  scale_fill_gradientn(colours = c("#CBD5E1", peach, coral, rose, plum), name = "Drought\n(−SPEI)") +
  annotate("text", x = 0.6, y = 3.6, hjust = 0, size = 6, colour = slate,
           label = "more rewiring than flower abundance predicts") +
  annotate("text", x = 0.6, y = -14.5, hjust = 0, size = 6, colour = plum,
           label = "less rewiring: network locked") +
  labs(x = NULL, y = "Turnover: observed − null (%)") +
  theme_deck +
  theme(panel.grid.major.x = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 17),
        legend.position = "right", legend.title = element_text(size = 17), legend.text = element_text(size = 14))
ggsave(file.path(out, "pac_turnover.png"), p2, width = 12, height = 6.2, dpi = 200)

# ---- 3. NMDS trajectory: pulse and press ------------------------------------------------
nm <- read.csv(file.path(src, "outputs/Data_Prep/nmds_year_scores.csv"))
spei <- bind_rows(tibble(Year = tv$Transition_Start[1], spei = tv$spei_start[1]),
                  tibble(Year = tv$Transition_End, spei = tv$spei_end))
nm <- nm |> left_join(spei, by = "Year") |> mutate(drought = -spei)
# envfit directions from outputs/MS_Main/nmds_climate_envfit_summary.txt
vec <- tibble(name = c("Drought", "Year"), x = c(0.98016, 0.11464), y = c(0.19819, 0.99341),
              r2 = c(0.5537, 0.7139)) |> mutate(xe = x * sqrt(r2) * 0.75, ye = y * sqrt(r2) * 0.75)
p3 <- ggplot(nm, aes(NMDS1, NMDS2)) +
  geom_path(colour = "#CBD5E1", linewidth = 1.2) +
  geom_segment(data = vec, aes(x = 0, y = 0, xend = xe, yend = ye, colour = I(c(coral, navy))),
               linewidth = 2, arrow = arrow(length = unit(0.4, "cm"), type = "closed")) +
  geom_text(data = vec, aes(xe, ye, label = c("drought\n(pulse)", "decade\n(press)"), colour = I(c(coral, navy))),
            nudge_x = c(0.13, 0), nudge_y = c(0, 0.09), size = 6.5, fontface = "bold", lineheight = 0.9) +
  geom_point(aes(fill = drought), shape = 21, colour = "white", size = 8, stroke = 1.2) +
  geom_text(aes(label = substr(Year, 3, 4)), size = 4.2, colour = "white", fontface = "bold") +
  scale_fill_gradientn(colours = c("#94A3B8", peach, coral, rose, plum)) +
  coord_equal() +
  labs(x = "NMDS 1", y = "NMDS 2") +
  theme_deck + theme(axis.text = element_blank())
ggsave(file.path(out, "pac_nmds.png"), p3, width = 9, height = 6.4, dpi = 200)
