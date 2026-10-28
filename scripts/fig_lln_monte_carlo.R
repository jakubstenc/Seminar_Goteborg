# Generate the redesigned 8-panel Monte Carlo simulation figure for Seminar Göteborg 2026
# Featuring prominent Year labels on the left side and CP / HP headers at the top.
# Usage: Rscript scripts/fig_lln_monte_carlo.R

seminar <- normalizePath(".")
paper <- normalizePath("../../Psani_clanku/2025/Linking-Network-Structure-to-Pollen-Deposition-Mechanisms")

setwd(paper)
src <- readLines("scripts/Analysis_FML_Z.R")
stop_at <- grep("MARK: MANUSCRIPT FIGURES AND TABLES", src)[1] - 1
src <- src[1:stop_at]
src <- sub("^new_packages <-.*", "packages <- packages[packages %in% rownames(installed.packages())]; new_packages <- character(0)", src)
src <- sub('plot_layout(guides = "collect") &', 'plot_layout(guides = "collect") +', src, fixed = TRUE)
src <- sub('theme(legend.position = "bottom") &', 'theme(legend.position = "bottom") +', src, fixed = TRUE)
pdf(NULL)
eval(parse(text = src), envir = globalenv())
invisible(dev.off())

setwd(seminar)
library(ggplot2)
library(patchwork)
library(cowplot)

# Stigma icon paths
img_cp <- file.path(seminar, "images", "pathway", "TPD.png")
img_hp <- file.path(seminar, "images", "pathway", "TPD_HP.png")

make_mc_plot <- function(emp, svd_pool, n_vis, col_obs, img_path, is_bottom = FALSE) {
  set.seed(42)
  sim <- replicate(n_sim, sum(sample(svd_pool, size = n_vis, replace = TRUE)))
  
  ks_res <- ks.test(emp, sim)
  ov_res <- overlapping::overlap(list(emp, sim))
  
  annot_text <- sprintf("Overlap: %.1f%%   KS D = %.3f", ov_res$OV * 100, ks_res$statistic)
  
  df <- data.frame(
    Value = c(emp, sim),
    Type = factor(
      c(rep("Observed TPD", length(emp)), rep("Simulated (Averaged SVDs)", length(sim))),
      levels = c("Observed TPD", "Simulated (Averaged SVDs)")
    )
  )
  
  max_x_val <- as.numeric(quantile(df$Value, 0.98))
  
  p <- ggplot(df, aes(x = Value, fill = Type)) +
    geom_density(alpha = 0.65, color = "white", linewidth = 0.3) +
    coord_cartesian(xlim = c(0, max_x_val)) +
    scale_fill_manual(values = c("Observed TPD" = col_obs, "Simulated (Averaged SVDs)" = "gray50")) +
    theme_classic(base_size = 13) +
    labs(
      subtitle = annot_text,
      x = if (is_bottom) "Pollen count" else NULL,
      y = "Density"
    ) +
    theme(
      plot.subtitle = element_text(size = 12, face = "bold", color = "#222222", margin = margin(t = 2, b = 3)),
      axis.title.x = element_text(size = 12, face = "bold", margin = margin(t = 4, b = 2)),
      axis.title.y = element_text(size = 11, color = "gray25"),
      axis.text = element_text(size = 10.5),
      legend.position = "none",
      plot.margin = margin(t = 2, r = 6, b = 2, l = 4)
    )
  
  img <- magick::image_read(img_path)
  p_drawn <- cowplot::ggdraw(p) +
    cowplot::draw_image(img, x = 0.81, y = 0.44, width = 0.15, height = 0.44)
  
  return(p_drawn)
}

# Generate subplots
pA <- make_mc_plot(emp_CP_global, global_emp_svd_cp, n_vis_global, col_global, img_cp, is_bottom = FALSE)
pB <- make_mc_plot(emp_HP_global, global_emp_svd_hp, n_vis_global, col_global, img_hp, is_bottom = FALSE)

pC <- make_mc_plot(emp_CP_22, global_emp_svd_cp, n_vis_22, viridis_cols[1], img_cp, is_bottom = FALSE)
pD <- make_mc_plot(emp_HP_22, global_emp_svd_hp, n_vis_22, viridis_cols[1], img_hp, is_bottom = FALSE)

pE <- make_mc_plot(emp_CP_23, global_emp_svd_cp, n_vis_23, viridis_cols[2], img_cp, is_bottom = FALSE)
pF <- make_mc_plot(emp_HP_23, global_emp_svd_hp, n_vis_23, viridis_cols[2], img_hp, is_bottom = FALSE)

pG <- make_mc_plot(emp_CP_24, global_emp_svd_cp, n_vis_24, viridis_cols[3], img_cp, is_bottom = TRUE)
pH <- make_mc_plot(emp_HP_24, global_emp_svd_hp, n_vis_24, viridis_cols[3], img_hp, is_bottom = TRUE)

# Label constructors
make_row_label <- function(title_text, subtitle_text = NULL, col = "#222222") {
  p <- ggplot() +
    annotate("text", x = 0.5, y = if (is.null(subtitle_text)) 0.5 else 0.58, 
             label = title_text, size = 6.0, fontface = "bold", color = col, hjust = 0.5)
  if (!is.null(subtitle_text)) {
    p <- p + annotate("text", x = 0.5, y = 0.35, 
                      label = subtitle_text, size = 3.8, color = "gray40", hjust = 0.5)
  }
  p + theme_void() + 
    coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
    theme(plot.margin = margin(0, 4, 0, 4))
}

make_col_header <- function(title_text, col = "#222222") {
  ggplot() +
    annotate("text", x = 0.5, y = 0.45, label = title_text, size = 6.2, fontface = "bold", color = col, hjust = 0.5) +
    theme_void() +
    coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
    theme(plot.margin = margin(2, 0, 4, 0))
}

# Headers and rows
header_row <- (plot_spacer() | 
               make_col_header("Conspecific Pollen (CP)", "#40695B") | 
               make_col_header("Heterospecific Pollen (HP)", "#8C2981")) +
  plot_layout(widths = c(0.13, 1, 1))

r1 <- (make_row_label("Global", "All years", col_global) | pA | pB) + plot_layout(widths = c(0.13, 1, 1))
r2 <- (make_row_label("2022", NULL, viridis_cols[1]) | pC | pD) + plot_layout(widths = c(0.13, 1, 1))
r3 <- (make_row_label("2023", NULL, viridis_cols[2]) | pE | pF) + plot_layout(widths = c(0.13, 1, 1))
r4 <- (make_row_label("2024", NULL, viridis_cols[3]) | pG | pH) + plot_layout(widths = c(0.13, 1, 1))

# Legend
dummy_df <- data.frame(
  Value = 1,
  Type = factor(
    c("Observed TPD (Global)", "Observed TPD (2022)", "Observed TPD (2023)", "Observed TPD (2024)", "Simulated (Averaged SVDs)"), 
    levels = c("Observed TPD (Global)", "Observed TPD (2022)", "Observed TPD (2023)", "Observed TPD (2024)", "Simulated (Averaged SVDs)")
  )
)
dummy_p <- ggplot(dummy_df, aes(x = Value, fill = Type)) + 
  geom_density() + 
  scale_fill_manual(values = c(
    "Observed TPD (Global)" = col_global, 
    "Observed TPD (2022)" = viridis_cols[1],
    "Observed TPD (2023)" = viridis_cols[2],
    "Observed TPD (2024)" = viridis_cols[3],
    "Simulated (Averaged SVDs)" = "gray50"
  )) +
  theme_classic() + 
  theme(
    legend.position = "bottom", 
    legend.title = element_blank(), 
    legend.text = element_text(size = 12, face = "bold"),
    legend.key.size = unit(0.7, "cm")
  ) + 
  guides(fill = guide_legend(nrow = 1))

leg_plot <- cowplot::ggdraw(cowplot::get_legend(dummy_p))

p_full <- (header_row / r1 / r2 / r3 / r4 / leg_plot) +
  plot_layout(heights = c(0.18, 1, 1, 1, 1, 0.18))

out_file <- file.path(seminar, "images", "lln_fig_monte_carlo.png")
ggsave(out_file, plot = p_full, width = 11.5, height = 8.5, dpi = 250, bg = "white")
message("Successfully saved: ", out_file)

# Copy to docs/images
docs_out <- file.path(seminar, "docs", "images", "lln_fig_monte_carlo.png")
file.copy(out_file, docs_out, overwrite = TRUE)
message("Successfully copied to: ", docs_out)
