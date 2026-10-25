# Slide figures: diurnal partitioning of the community and time-of-day pollen transfer on Succisa
# Data: Psani_clanku/2026/DiuHanPolNet/data/diurnal_interactions.csv
#       Psani_clanku/2025/Linking-Network-Structure-to-Pollen-Deposition-Mechanisms/data/*_Succisa_pratensis.csv
# Run from the Seminar_Goteborg folder:  Rscript scripts/fig_diurnal.R
suppressMessages({library(ggplot2); library(dplyr); library(ggridges)})
pc <- "../../Psani_clanku"; out <- "images"
green <- "#40695B"; coral <- "#F8765C"; slate <- "#64748B"; grid_col <- "#E2E8F0"
start_cols <- c("Succisa pratensis" = "#5B3F9A", "Centaurea jacea" = "#B0207F", "Trifolium hybridum" = "#2E9A50")
theme_deck <- theme_minimal(base_size = 22, base_family = "sans") +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = grid_col),
        axis.text = element_text(colour = "#334155"), axis.title = element_text(colour = "#1E293B"),
        plot.background = element_rect(fill = "white", colour = NA))

# ---- 1. Day profile of the plant community --------------------------------
df <- read.csv(file.path(pc, "2026/DiuHanPolNet/data/diurnal_interactions.csv")) |>
  filter(Insect_species != "Unknown", !is.na(Insect_species), Hour >= 7, Hour <= 19) |>
  mutate(t = Hour + Minute / 60)
top <- df |> count(Plant_species, sort = TRUE) |> slice_head(n = 14) |> pull(Plant_species)
sel <- union(top, names(start_cols))
ord <- df |> filter(Plant_species %in% sel) |> group_by(Plant_species) |> summarise(m = mean(t)) |> arrange(desc(m))
dp <- df |> filter(Plant_species %in% sel) |>
  mutate(Plant_species = factor(Plant_species, levels = ord$Plant_species),
         grp = ifelse(as.character(Plant_species) %in% names(start_cols), as.character(Plant_species), "other"))
fills <- c(start_cols, other = "#CBD5E1")
make_ridges <- function(highlight) {
  d <- dp; if (!highlight) d$grp <- "other"
  ggplot(d, aes(t, Plant_species, fill = grp)) +
    geom_density_ridges(scale = 1.8, rel_min_height = 0.01, colour = "white", linewidth = 0.4, bandwidth = 0.7) +
    scale_fill_manual(values = fills, guide = "none") +
    scale_x_continuous(breaks = seq(8, 18, 2), labels = paste0(seq(8, 18, 2), ":00"), limits = c(7, 19)) +
    labs(x = NULL, y = NULL) + theme_deck +
    theme(axis.text.y = element_text(face = "italic", size = 15,
          colour = ifelse(levels(dp$Plant_species) %in% names(start_cols) & highlight,
                          start_cols[levels(dp$Plant_species)], "#334155")))
}
suppressWarnings({
  ggsave(file.path(out, "diu_ridges_all.png"), make_ridges(FALSE), width = 10, height = 6.4, dpi = 200)
  ggsave(file.path(out, "diu_ridges_start.png"), make_ridges(TRUE), width = 10, height = 6.4, dpi = 200)
})
cat("Plants shown:", length(sel), " records:", nrow(dp), " years:", paste(range(df$Year), collapse = "-"), "\n")
print(ord |> mutate(m = round(m, 1)))

# ---- 2. Succisa visitors: pollen on the body through the day (2024) --------
b <- read.csv(file.path(pc, "2025/Linking-Network-Structure-to-Pollen-Deposition-Mechanisms/data/pollen_load_and_guts_2024_Succisa_pratensis.csv"))
tt <- strptime(b$time, "%I:%M:%S %p"); b$hour <- as.numeric(format(tt, "%H")) + as.numeric(format(tt, "%M")) / 60
b <- b |> filter(!is.na(suc_pra_load), !is.na(other_pollen_load), !is.na(hour), hour >= 8) |>
  mutate(own = suc_pra_load, foreign = other_pollen_load, share = own / pmax(own + foreign, 1))
m1 <- glm(round(own) ~ hour, data = b, family = quasipoisson)
m2 <- glm(round(foreign) ~ hour, data = b, family = quasipoisson)
m3 <- glm(cbind(round(own), round(foreign)) ~ hour, data = b, family = quasibinomial)
cat("n =", nrow(b), "\n"); for (m in list(m1, m2, m3)) print(round(summary(m)$coef[2, ], 4))
nd <- data.frame(hour = seq(8, 15.5, 0.1))
nd$own <- predict(m1, nd, type = "response"); nd$foreign <- predict(m2, nd, type = "response")
nd$share <- predict(m3, nd, type = "response")
xs <- scale_x_continuous(breaks = 8:15, labels = paste0(8:15, ":00"), limits = c(8, 15.6))
tl <- theme_deck + theme(panel.grid.major.y = element_line(colour = grid_col), legend.position = "top", legend.title = element_blank())

pA <- ggplot(b, aes(hour)) +
  geom_point(aes(y = own + 1, colour = "Own (Succisa) pollen"), alpha = 0.45, size = 2.6) +
  geom_line(data = nd, aes(y = own + 1, colour = "Own (Succisa) pollen"), linewidth = 1.8) +
  scale_y_log10(breaks = c(1, 11, 101, 1001), labels = c("0", "10", "100", "1 000"), limits = c(1, 5000)) +
  scale_colour_manual(values = c("Own (Succisa) pollen" = "#5B3F9A", "Foreign pollen" = coral), breaks = c("Own (Succisa) pollen", "Foreign pollen")) +
  xs + labs(x = NULL, y = "Pollen grains on the body") + tl
ggsave(file.path(out, "diu_body_own.png"), pA, width = 10, height = 6, dpi = 200)
pB <- pA +
  geom_point(aes(y = foreign + 1, colour = "Foreign pollen"), alpha = 0.35, size = 2.6, shape = 17) +
  geom_line(data = nd, aes(y = foreign + 1, colour = "Foreign pollen"), linewidth = 1.8)
ggsave(file.path(out, "diu_body_both.png"), pB, width = 10, height = 6, dpi = 200)
pC <- ggplot(b, aes(hour, share)) +
  geom_point(colour = "#5B3F9A", alpha = 0.45, size = 2.6) +
  geom_line(data = nd, aes(hour, share), colour = "#5B3F9A", linewidth = 1.8) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  xs + labs(x = NULL, y = "Share of own pollen on the body") + tl
ggsave(file.path(out, "diu_body_share.png"), pC, width = 10, height = 6, dpi = 200)
cat("Predicted own pollen at 8:30 and 14:30:", round(predict(m1, data.frame(hour = c(8.5, 14.5)), type = "response")), "\n")
cat("Predicted share at 8:30 and 14:30:", round(predict(m3, data.frame(hour = c(8.5, 14.5)), type = "response"), 2), "\n")
