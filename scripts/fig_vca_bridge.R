# Regenerate slav_pres_vca_bridge.png without the cartoon stigma icons
library(tidyverse)
library(ggtext)
library(viridis)

vca_file <- "/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2026/Pollen_deposition_Slavkovsky_les/outputs/tables/presentation_vca_bridge.csv"
vca <- read_csv(vca_file, show_col_types = FALSE)

col_lvl <- setNames(magma(4, begin = 0.3, end = 0.9),
                    c("Between", "Date", "Plant", "Stigma"))

site_lab <- c(Handrkov   = "One meadow, 3 years<br><span style='font-size:12pt;color:#555555'>K Handrkovu 2022–2024</span>",
              Slavkovsky = "60 meadows, one landscape<br><span style='font-size:12pt;color:#555555'>Slavkovský les 2022–2023</span>")

vca_plot <- vca |>
  mutate(
    level_lab = case_when(
      level == "Between" ~ "Between years / meadows",
      level == "Plant"   ~ "Plant",
      TRUE               ~ "Stigma"),
    level_lab = factor(level_lab, levels = c("Between years / meadows", "Plant", "Stigma")),
    pt = factor(pt, levels = c("CP", "HP")),
    site = factor(site, levels = c("Handrkov", "Slavkovsky"))
  )

p_vca <- ggplot(vca_plot, aes(x = pt, y = pct, fill = level_lab)) +
  geom_col(width = 0.62, colour = "black", linewidth = 0.4,
           position = position_stack(reverse = TRUE)) +
  geom_text(aes(label = ifelse(pct >= 4, paste0(round(pct), "%"), "")),
            position = position_stack(vjust = 0.5, reverse = TRUE),
            size = 5.2, fontface = "bold",
            colour = ifelse(vca_plot$level == "Between", "white", "black")) +
  facet_wrap(~ site, labeller = as_labeller(site_lab)) +
  scale_fill_manual(values = c("Between years / meadows" = col_lvl[["Between"]],
                               "Plant" = col_lvl[["Plant"]],
                               "Stigma" = col_lvl[["Stigma"]]),
                    name = "Variance source") +
  scale_x_discrete(labels = c(CP = "Conspecific (CP)",
                              HP = "Heterospecific (HP)")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.02)),
                     labels = \(x) paste0(x, "%")) +
  labs(x = NULL, y = "% of total variance") +
  theme_classic(base_size = 15) +
  theme(axis.text        = element_text(colour = "black"),
        axis.text.x      = element_text(face = "bold", size = 13, colour = "#1E293B"),
        axis.title.y     = element_text(size = 14, face = "plain"),
        strip.text       = element_markdown(size = 14, face = "bold", lineheight = 1.15),
        strip.background = element_blank(),
        panel.spacing.x  = unit(2.2, "lines"),
        legend.position  = "bottom",
        legend.title     = element_text(face = "plain", size = 13),
        legend.text      = element_text(size = 12))

out_deck <- "images/slav_pres_vca_bridge.png"
ggsave(out_deck, p_vca, width = 9.5, height = 5.8, dpi = 220, bg = "white")
message("Saved ", out_deck)
