# Regenerate slav_pres_hp_landscape.png without the cartoon stigma icons
suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(terra)
  library(tidyterra)
  library(patchwork)
  library(ggtext)
  library(viridis)
  library(scales)
})

base_dir <- "/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2026/Pollen_deposition_Slavkovsky_les"
proc_dir <- file.path(base_dir, "data", "processed")
tile_dir <- file.path(base_dir, "data", "external", "tiles")
tbl_dir  <- file.path(base_dir, "outputs", "tables")

col_pt <- setNames(magma(2, begin = 0.3, end = 0.8), c("CP", "HP"))

stigma <- readRDS(file.path(proc_dir, "stigma_data.rds")) |>
  filter(dataset_origin == "spatial") |>
  mutate(locality = as.character(locality), year = as.character(year),
         plant_uid = paste(locality, year, plant_id, sep = "__"))

loc <- stigma |>
  group_by(locality, year) |>
  summarise(n_plants = n_distinct(plant_id), n_stigmas = n(),
            mean_CP = mean(CP_count, na.rm = TRUE),
            mean_HP = mean(HP_count, na.rm = TRUE), .groups = "drop") |>
  left_join(readRDS(file.path(proc_dir, "locality_env.rds")) |>
              mutate(locality = as.character(locality)) |>
              distinct(locality, .keep_all = TRUE),
            by = "locality")

loc_sf <- st_as_sf(loc, coords = c("longitude", "latitude"), crs = 4326) |>
  st_transform(32633)
rgb_C <- rast(file.path(tile_dir, "rgb_central.tif"))
bbC <- st_bbox(rgb_C)

# 1. Right panels: flowerheads vs CP and HP
fh <- loc |>
  select(locality, n_flowerheads, mean_CP, mean_HP) |>
  pivot_longer(c(mean_CP, mean_HP), names_to = "pt", values_to = "m", names_prefix = "mean_") |>
  mutate(pt = factor(pt, levels = c("CP", "HP")))

rho_CP <- cor(log1p(loc$mean_CP), loc$n_flowerheads, method = "spearman", use = "complete.obs")
rho_HP <- cor(log1p(loc$mean_HP), loc$n_flowerheads, method = "spearman", use = "complete.obs")

rho_lab <- tibble(
  pt = factor(c("CP", "HP"), levels = c("CP", "HP")),
  lab = c(sprintf("\u03c1 = %+.2f", rho_CP), sprintf("\u03c1 = %+.2f", rho_HP))
)

p_fh <- ggplot(fh, aes(x = n_flowerheads, y = m)) +
  geom_smooth(aes(colour = pt, fill = pt), method = "glm", formula = y ~ log(x),
              method.args = list(family = quasipoisson), linewidth = 1.2, alpha = 0.2) +
  geom_point(aes(fill = pt), shape = 21, size = 2.8, colour = "black", stroke = 0.35) +
  geom_text(data = rho_lab, aes(label = lab), x = Inf, y = Inf, hjust = 1.1, vjust = 1.4,
            size = 4.8, fontface = "bold") +
  facet_wrap(~ pt, scales = "free_y",
             labeller = as_labeller(c(CP = "Conspecific (CP)",
                                      HP = "Heterospecific (HP)"))) +
  scale_x_log10() +
  scale_colour_manual(values = col_pt, guide = "none") +
  scale_fill_manual(values = col_pt, guide = "none") +
  labs(x = "Succisa flowerheads at the meadow", y = "Pollen grains per stigma") +
  theme_classic(base_size = 14) +
  theme(
    axis.text        = element_text(colour = "black"),
    axis.text.x      = element_text(face = "plain"),
    strip.text       = element_text(size = 15, face = "bold", colour = "#1E293B"),
    strip.background = element_blank(),
    plot.margin      = margin(5, 10, 5, 5)
  )

# 2. Left panel: HP map
rgb_wash <- rgb_C * 0.55 + 255 * 0.45

# Scale bar helper
scale_bar <- function(bb, km = 2, pos = c(0.04, 0.04), txt_size = 3.4) {
  x0 <- bb["xmin"] + pos[1] * (bb["xmax"] - bb["xmin"])
  y0 <- bb["ymin"] + pos[2] * (bb["ymax"] - bb["ymin"])
  dx <- km * 1000
  dy <- (bb["ymax"] - bb["ymin"]) * 0.012
  list(
    annotate("rect", xmin = x0, xmax = x0 + dx, ymin = y0 - dy, ymax = y0 + dy,
             fill = "black", colour = "black"),
    annotate("text", x = x0 + dx / 2, y = y0 + dy * 2.2,
             label = paste(km, "km"), size = txt_size, fontface = "bold")
  )
}

p_hpmap <- ggplot() +
  geom_spatraster_rgb(data = rgb_wash, max_col_value = 255) +
  geom_sf(data = arrange(loc_sf, mean_HP), aes(fill = mean_HP, size = mean_HP),
          shape = 21, colour = "black", stroke = 0.4) +
  scale_fill_viridis_c(option = "magma", begin = 0.15, end = 0.95, direction = -1,
                       trans = "log1p", breaks = c(0, 2, 5, 10, 20),
                       name = "HP grains per stigma") +
  scale_size_continuous(range = c(2, 7), trans = "log1p", guide = "none") +
  scale_bar(bbC, km = 2, pos = c(0.04, 0.04), txt_size = 3.4) +
  coord_sf(crs = 32633, xlim = bbC[c(1, 3)], ylim = bbC[c(2, 4)],
           expand = FALSE, datum = NA) +
  theme_void(base_size = 13) +
  theme(panel.border = element_rect(fill = NA, colour = "black", linewidth = 0.8),
        legend.position = "bottom", legend.key.width = unit(1.6, "cm"),
        legend.key.height = unit(0.35, "cm"),
        legend.title = element_text(size = 12, vjust = 0.9),
        plot.margin = margin(5, 5, 5, 5))

p_hp <- p_hpmap + p_fh + plot_layout(widths = c(1.05, 1))

out_deck1 <- "images/slav_pres_hp_landscape.png"
out_deck2 <- "docs/images/slav_pres_hp_landscape.png"
ggsave(out_deck1, p_hp, width = 12, height = 5.4, dpi = 220, bg = "white")
ggsave(out_deck2, p_hp, width = 12, height = 5.4, dpi = 220, bg = "white")
message("Successfully regenerated slav_pres_hp_landscape.png without cartoon stigma icons!")
