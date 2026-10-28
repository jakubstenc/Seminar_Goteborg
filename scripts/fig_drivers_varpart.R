# Slide figure: what drives which part of the system?
# Variance partitioning (RDA, adjusted R2) of
#   (a) pollinator composition and (b) composition of visited plants
# by year, date within season, hour of day, space (plot position) and the other partner set.
# Data: DiuHanPolNet diurnal visit records (Handrkov, August 2011-2025).
# Run from the Seminar_Goteborg folder:  Rscript scripts/fig_drivers_varpart.R
suppressMessages({library(dplyr); library(tidyr); library(vegan); library(ggplot2)})
set.seed(1)
src <- "../../Psani_clanku/2026"
out <- "images"

navy <- "#3B0F70"; plum <- "#8C2981"; rose <- "#B63679"; coral <- "#F8765C"; peach <- "#FEB47B"
green <- "#40695B"; slate <- "#64748B"; ink <- "#1E293B"; grid_col <- "#E2E8F0"
theme_deck <- theme_minimal(base_size = 24, base_family = "sans") +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = grid_col),
        axis.text = element_text(colour = "#334155"), axis.title = element_text(colour = ink),
        legend.position = "none", plot.background = element_rect(fill = "white", colour = NA))

d <- read.csv(file.path(src, "DiuHanPolNet/data/diurnal_interactions.csv"))
xy <- read.csv(file.path(src, "HanNullNet/data/hanpolnet_plots_metadata.csv"))
# geometry field is unquoted, so columns are shifted by one: plot ID -> row names,
# X_relative -> column "sektor", Y_relative -> column "X_relative"
xy <- data.frame(Plot_ID = suppressWarnings(as.integer(rownames(xy))),
                 X = as.numeric(xy$sektor), Y = as.numeric(xy$X_relative)) |>
  filter(!is.na(Plot_ID))

# --- sample unit: plot x date x part of day -------------------------------------------
d <- d |> mutate(block = cut(Hour, c(-Inf, 10, 13, 16, Inf), labels = c("7-10", "11-13", "14-16", "17-19")),
                 sample = paste(Plot_ID, Date, block, sep = "_"))
# lump rare pollinator taxa into their family, rare plants into "other"
poll_n <- d |> count(Insect_species, wt = Interaction_count)
d <- d |> left_join(poll_n, by = "Insect_species") |>
  mutate(poll = ifelse(n >= 100, Insect_species,
                       ifelse(is.na(Insect_family) | Insect_family == "", Insect_order, Insect_family))) |>
  select(-n)
plant_n <- d |> count(Plant_species, wt = Interaction_count)
d <- d |> left_join(plant_n, by = "Plant_species") |>
  mutate(plant = ifelse(n >= 100, Plant_species, "other")) |> select(-n)

min_visits <- 5
keep <- d |> count(sample, wt = Interaction_count) |> filter(n >= min_visits) |> pull(sample)
d <- d |> filter(sample %in% keep)

wide <- function(var) {
  m <- d |> count(sample, .data[[var]], wt = Interaction_count) |>
    pivot_wider(names_from = all_of(var), values_from = n, values_fill = 0)
  r <- m$sample; m <- as.matrix(m[, -1]); rownames(m) <- r; m
}
P <- wide("poll"); Pl <- wide("plant")
Pl <- Pl[rownames(P), ]
env <- d |> group_by(sample) |>
  summarise(Year = factor(first(Year)), day = mean(OrdinalDay), hour = mean(Hour + Minute / 60),
            Plot_ID = first(Plot_ID), .groups = "drop") |>
  left_join(xy, by = "Plot_ID") |> as.data.frame()
rownames(env) <- env$sample
env <- env[rownames(P), ]
ok <- complete.cases(env)
P <- P[ok, ]; Pl <- Pl[ok, ]; env <- env[ok, ]
cat("samples:", nrow(P), " pollinator taxa:", ncol(P), " plant taxa:", ncol(Pl),
    " plots:", length(unique(env$Plot_ID)), " visits:", sum(P), "\n")

Ph <- decostand(P, "hellinger"); Plh <- decostand(Pl, "hellinger")
# partner composition summarised by PCA axes (80 % of variance at most 15 axes)
pcs <- function(Y, k = 15) {
  pc <- prcomp(Y)
  k <- min(k, which(cumsum(pc$sdev^2) / sum(pc$sdev^2) >= 0.8)[1])
  pc$x[, 1:k, drop = FALSE]
}
sets_base <- list(
  Year   = model.matrix(~ Year, env)[, -1],
  Season = poly(env$day, 2),
  Hour   = poly(env$hour, 2),
  Space  = poly(env$X, env$Y, degree = 3)
)

# unique fraction of each set = adjR2(all) - adjR2(all but that set); shared = rest
partition <- function(Y, sets) {
  big <- do.call(cbind, sets)
  full <- RsquareAdj(rda(Y, big))$adj.r.squared
  uniq <- sapply(names(sets), function(s) {
    rest <- do.call(cbind, sets[names(sets) != s])
    full - RsquareAdj(rda(Y, rest))$adj.r.squared
  })
  alone <- sapply(sets, function(X) RsquareAdj(rda(Y, X))$adj.r.squared)
  data.frame(set = names(sets), unique = uniq, alone = alone, total = full)
}
res_poll  <- partition(Ph,  c(sets_base, list(Partner = pcs(Plh))))
res_plant <- partition(Plh, c(sets_base, list(Partner = pcs(Ph))))
res_poll$response <- "Who visits\n(pollinator composition)"
res_plant$response <- "What is visited\n(plant composition)"
res <- bind_rows(res_poll, res_plant)
print(res, digits = 3)
write.csv(res, "scripts/drivers_varpart_results.csv", row.names = FALSE)

source("scripts/fig_drivers_plot.R")  # figures (can be re-run alone from the saved CSV)
