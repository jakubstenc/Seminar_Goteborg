# Slide figure: flower constancy for each pollinator species x plant pair (Handrkov experiments only).
# Run from the Seminar_Goteborg folder:  Rscript scripts/fig_constancy_matrix.R
suppressMessages({library(ggplot2); library(dplyr)})
pc <- "../../Psani_clanku"
out <- "images"
navy <- "#3B0F70"; plum <- "#8C2981"; rose <- "#B63679"; coral <- "#F8765C"; peach <- "#FEB47B"
slate <- "#64748B"; ink <- "#1E293B"; grid_col <- "#E2E8F0"

v <- read.table(file.path(pc, "2025/Constancy_Preference_2025/data/Stenc_Janovsky_2025_dataset.txt"),
                header = TRUE, sep = "\t", stringsAsFactors = FALSE) |>
  filter(source == "Sedlackova_2024")
full <- c(Ach_mil = "Achillea", Ach_pta = "A. ptarmica", Ang_syl = "Angelica", Bet_off = "Betonica",
          Cen_jac = "Centaurea", Cir_can = "Cirsium", Cre_bie = "Crepis", Dau_car = "Daucus",
          Lot_cor = "Lotus", Sel_car = "Selinum", Suc_pra = "Succisa", Tri_rep = "Trifolium")
v <- v |>
  mutate(a = pmin(plant.sp1, plant.sp2), b = pmax(plant.sp1, plant.sp2),
         pair = paste(full[a], "×", full[b]),
         prop = const.trans / n.tot,
         group = factor(poll.group, levels = c("honeybee", "bumblebees", "hoverflies"),
                        labels = c("Honeybee", "Bumblebees", "Hoverflies")),
         poll = sub("^(\\w)\\w+ ", "\\1. ", poll.sp))
# pairs ordered by how many pollinators were tested on them; pollinators by group, then name
pair_ord <- v |> count(pair) |> arrange(desc(n), pair) |> pull(pair)
poll_ord <- v |> distinct(group, poll) |> arrange(group, poll) |> pull(poll)
v <- v |> mutate(pair = factor(pair, levels = pair_ord), poll = factor(poll, levels = rev(poll_ord)))

bg <- v |> distinct(group, poll) |> tidyr::crossing(pair = factor(pair_ord, levels = pair_ord))
p <- ggplot(v, aes(pair, poll, fill = prop)) +
  geom_tile(data = bg, aes(pair, poll), inherit.aes = FALSE, fill = "#F1F5F9", colour = "white", linewidth = 2) +
  geom_tile(colour = "white", linewidth = 2) +
  geom_text(aes(label = sprintf("%.0f", prop * 100), colour = I(ifelse(prop > 0.45, "white", ink))),
            size = 6.5, fontface = "bold") +
  facet_grid(group ~ ., scales = "free_y", space = "free_y") +
  scale_fill_gradientn(colours = c("#FFF4E8", peach, coral, rose, plum, navy),
                       limits = c(0, 1), labels = scales::percent, name = "Constancy") +
  scale_x_discrete(position = "top") +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 20, base_family = "sans") +
  theme(panel.grid = element_blank(),
        axis.text.x.top = element_text(angle = 40, hjust = 0, vjust = 0, colour = "#334155", size = 17),
        axis.text.y = element_text(face = "italic", colour = "#334155", size = 18),
        strip.text.y = element_text(angle = 0, hjust = 0, face = "bold", colour = ink, size = 18),
        legend.position = "right", legend.key.height = unit(1.4, "cm"),
        legend.title = element_text(colour = ink, size = 17), legend.text = element_text(size = 15),
        plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(5, 10, 5, 5))
ggsave(file.path(out, "constancy_matrix.png"), p, width = 13, height = 6.6, dpi = 200)

# How much does constancy depend on the pollinator vs on the plant pair?
m1 <- glm(cbind(const.trans, n.tot - const.trans) ~ poll.sp + pair, data = v, family = quasibinomial)
m2 <- glm(cbind(const.trans, n.tot - const.trans) ~ pair + poll.sp, data = v, family = quasibinomial)
print(anova(m1, test = "F")); print(anova(m2, test = "F"))
print(v |> filter(pair == "Centaurea × Succisa") |> select(poll, prop) |> arrange(prop))
print(v |> filter(poll %in% c("E. interruptus", "E. tenax")) |> select(poll, pair, prop))
