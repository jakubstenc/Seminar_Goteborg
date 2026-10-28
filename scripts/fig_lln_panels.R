# Export the individual panels of the multi-panel LLN-paper figures, so the slides can
# show them one by one (full slide each) before the combined figure.
# Re-runs the analysis part of the paper script (no changes to it) and saves the
# panel objects.   Rscript scripts/fig_lln_panels.R
seminar <- normalizePath(".")
paper <- normalizePath("../../Psani_clanku/2025/Linking-Network-Structure-to-Pollen-Deposition-Mechanisms")
out <- file.path(seminar, "images", "lln_panels")
dir.create(out, showWarnings = FALSE, recursive = TRUE)

setwd(paper)
src <- readLines("scripts/Analysis_FML_Z.R")
stop_at <- grep("MARK: MANUSCRIPT FIGURES AND TABLES", src)[1] - 1   # analysis only
src <- src[1:stop_at]
# load only installed packages (e.g. Bioconductor 'sva' is listed but never used)
src <- sub("^new_packages <-.*", "packages <- packages[packages %in% rownames(installed.packages())]; new_packages <- character(0)", src)
# patchwork '&' with a theme fails under ggplot2 >= 4 (S7); use '+' for the composite
src <- sub('plot_layout(guides = "collect") &', 'plot_layout(guides = "collect") +', src, fixed = TRUE)
src <- sub('theme(legend.position = "bottom") &', 'theme(legend.position = "bottom") +', src, fixed = TRUE)
pdf(NULL)                                                           # swallow print()s
eval(parse(text = src), envir = globalenv())
invisible(dev.off())

library(ggplot2); library(patchwork)
big <- theme(text = element_text(size = 17),
             plot.title = element_text(size = 20, face = "bold"),
             plot.subtitle = element_text(size = 15))
save <- function(p, name, w = 11, h = 6.2, add_theme = TRUE) {
  if (add_theme && inherits(p, "ggplot") && !inherits(p, "patchwork")) p <- p + big
  ggsave(file.path(out, paste0(name, ".png")), p, width = w, height = h, dpi = 200, bg = "white")
  message("saved ", name)
}

# 1. Body load and single-visit deposition (fig_body_svd): 4 panels.
#    Icons re-drawn as in the paper script, but on the enlarged plots.
icon <- function(p, img, s) cowplot::ggdraw(p + big) +
  cowplot::draw_image(img, x = 0.98, y = 0.98, hjust = 1, vjust = 1, width = s, height = s)
save(icon(p_eff_body,  "images/Pollen_load_CP.png", 0.15), "body_svd_A", add_theme = FALSE)
save(icon(p_mess_body, "images/Pollen_load_HP.png", 0.15), "body_svd_B", add_theme = FALSE)
save(icon(p_eff,       "images/SVD.png",            0.22), "body_svd_C", add_theme = FALSE)
save(icon(p_mess,      "images/SVD_HP.png",         0.22), "body_svd_D", add_theme = FALSE)

# 2. CV and means (fig_cv_plot): 4 panels; legends were collected in the composite
leg <- theme(legend.position = "bottom")
save(p_cv + big + leg,        "cv_A", add_theme = FALSE)
save(p_cv_year + big + leg,   "cv_B", add_theme = FALSE)
save(p_mean_comp + big + leg, "cv_C", add_theme = FALSE)
save(p_mean_year + big + leg, "cv_D", add_theme = FALSE)

# 3. Model + variance components (fig_model_vca)
p_model_big <- cowplot::ggdraw(p_model + big) +
  cowplot::draw_image("images/TPD_HP.png", x = 0.13, y = 0.85, hjust = 0.5, vjust = 0.5, width = 0.16, height = 0.16) +
  cowplot::draw_image("images/TPD.png", x = 0.80, y = 0.30, hjust = 0.5, vjust = 0.5, width = 0.16, height = 0.16)
save(p_model_big, "vca_A", add_theme = FALSE)
save(p_var + big,  "vca_B", add_theme = FALSE)

# 4. Monte Carlo (fig_monte_carlo): one slide per row (CP + HP side by side) + legend
leg_plot2 <- cowplot::ggdraw(cowplot::get_legend(dummy_p + guides(fill = guide_legend(nrow = 2))))
for (k in 1:4) {
  pr <- list(c("pA", "pB"), c("pC", "pD"), c("pE", "pF"), c("pG", "pH"))[[k]]
  p <- (get(pr[1]) + get(pr[2])) / leg_plot2 + plot_layout(heights = c(1, 0.14))
  save(p, paste0("mc_", k), w = 8.4, h = 4.2, add_theme = FALSE)   # small canvas -> larger text
}

# 5. Community stability (backup): 4 panels
save(p_composition,       "stab_A", w = 11, h = 6.2)
save(p_plant_composition, "stab_B", w = 11, h = 6.2)
save(p_similarity,        "stab_C", w = 11, h = 6.2)
save(p_plant_similarity,  "stab_D", w = 11, h = 6.2)

# 6. Abundance in space and time (backup): 3 panels with icons
save(cowplot::ggdraw(p_abundance + big) +
       cowplot::draw_image(img_plant, x = 0.17, y = 0.55, width = 0.10, height = 0.20), "spt_A", w = 11, h = 5.5, add_theme = FALSE)
save(cowplot::ggdraw(p_visitation + big) +
       cowplot::draw_image(img_pollinator, x = 0.17, y = 0.55, width = 0.10, height = 0.20), "spt_B", w = 11, h = 5.5, add_theme = FALSE)
save(cowplot::ggdraw(p_visitation_per_plant + big) +
       cowplot::draw_image(img_plant, x = 0.14, y = 0.55, width = 0.08, height = 0.16) +
       cowplot::draw_image(img_pollinator, x = 0.20, y = 0.55, width = 0.08, height = 0.16), "spt_C", w = 11, h = 5.5, add_theme = FALSE)
