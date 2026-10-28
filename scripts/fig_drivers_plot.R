# Figures for the "what drives what" slides, from scripts/drivers_varpart_results.csv
# (made by scripts/fig_drivers_varpart.R).  Rscript scripts/fig_drivers_plot.R
suppressMessages({library(dplyr); library(tidyr); library(ggplot2)})
out <- "images"
navy <- "#3B0F70"; plum <- "#8C2981"; rose <- "#B63679"; coral <- "#F8765C"; peach <- "#FEB47B"
green <- "#40695B"; slate <- "#64748B"; ink <- "#1E293B"; grid_col <- "#E2E8F0"
theme_deck <- theme_minimal(base_size = 24, base_family = "sans") +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = grid_col),
        axis.text = element_text(colour = "#334155"), axis.title = element_text(colour = ink),
        legend.position = "none", plot.background = element_rect(fill = "white", colour = NA))

res <- read.csv("scripts/drivers_varpart_results.csv")
lab <- c(Year = "Year", Season = "Date in season", Hour = "Hour of day",
         Space = "Position in meadow", Partner = "The other partner")
cols <- c(Year = navy, Season = plum, Hour = rose, Space = coral, Partner = green)
res <- res |> mutate(shared = pmax(alone - unique, 0),
                     resp = ifelse(grepl("^Who", response), "poll", "plant"),
                     label = factor(lab[set], levels = rev(lab)))

# ---- 1. bar panels (left: pollinators, right: plants; identical axes) ----------------

xmax <- 40
bar_panel <- function(r, title, partner_txt, show_y, ghost = FALSE) {
  tc <- function(col) if (ghost) "transparent" else col
  dd <- res |> filter(resp == r)
  long <- dd |> select(set, label, unique, shared) |>
    pivot_longer(c(unique, shared), names_to = "part", values_to = "r2") |>
    mutate(part = factor(part, levels = c("shared", "unique")),
           fill = if (ghost) "transparent" else ifelse(part == "unique", cols[set], paste0(cols[set], "55")))
  ggplot(long, aes(r2 * 100, label, fill = I(fill))) +
    geom_col(position = position_stack(reverse = TRUE), width = 0.7) +
    geom_text(data = dd, aes(x = alone * 100, y = label, label = sprintf("%.0f %%", alone * 100)),
              inherit.aes = FALSE, hjust = -0.2, size = 7, colour = tc(ink)) +
    geom_text(data = dd |> filter(set == "Partner"),
              aes(x = unique * 100 + 0.6, y = label, label = partner_txt),
              inherit.aes = FALSE, hjust = 0, size = 6, colour = tc(green), fontface = "italic") +
    scale_x_continuous(limits = c(0, xmax), breaks = seq(0, 30, 10), expand = expansion(mult = c(0, 0))) +
    labs(x = "Variation explained (%)", y = NULL, title = title,
         subtitle = sprintf("all drivers together: %.0f %%", dd$total[1] * 100)) +
    theme_deck +
    theme(plot.title = element_text(face = "bold", size = 26, colour = tc(ink)),
          plot.subtitle = element_text(size = 19, colour = tc(slate)),
          axis.text.x = element_text(colour = tc("#334155")),
          axis.title.x = element_text(colour = tc(ink)),
          panel.grid.major.x = element_line(colour = tc(grid_col)),
          axis.text.y = if (show_y) element_text(size = 22, colour = "#334155") else element_blank())
}
bars <- function(ghost_right) {
  m <- theme(plot.margin = margin(5, 20, 5, 5))
  cowplot::plot_grid(bar_panel("poll", "Who visits?", "plants", TRUE) + m + theme(plot.margin = margin(5, 20, 5, 30)),
                     bar_panel("plant", "What is visited?", "pollinators", FALSE, ghost = ghost_right) + m,
                     nrow = 1, align = "h", axis = "tb", rel_widths = c(1.55, 1))
}
ggsave(file.path(out, "drivers_bars_1.png"), bars(TRUE), width = 12, height = 5.6, dpi = 200)
ggsave(file.path(out, "drivers_bars_2.png"), bars(FALSE), width = 12, height = 5.6, dpi = 200)

# ---- 2. synthesis diagram: arrow width = unique explained variation ------------------
# time on the left, space on the right, the two partner communities in the middle
u <- function(s, r) res$unique[res$set == s & res$resp == r] * 100
dh <- function(r) u("Season", r) + u("Hour", r)          # date + hour, both < 1 %
nodes <- tibble::tribble(
  ~x,    ~y,   ~label,                          ~col,  ~size,
  1.25,  4.7,  "Year",                          navy,  10,
  1.25,  0.9,  "Date in season\n& hour of day", plum,  7.5,
  4.05,  2.8,  "Pollinators",                   ink,   10,
  7.55,  2.8,  "Plants\nvisited",               green, 10,
  10.75, 2.8,  "Position\nin meadow",           coral, 8.5
)
edges <- tibble::tribble(
  ~x,    ~y,    ~xend, ~yend, ~curv, ~val,                ~col,  ~lx,   ~ly,
  1.85,  4.35,  3.35,  3.3,   0,     u("Year", "poll"),   navy,  2.35,  3.55,
  1.85,  4.95,  7.2,   3.45,  -0.3,  u("Year", "plant"),  navy,  5.6,   4.95,
  6.6,   3.05,  5.45,  3.05,  0,     u("Partner", "poll"),  green, 5.92, 3.5,
  5.45,  2.55,  6.55,  2.55,  0,     u("Partner", "plant"), green, 5.92, 2.1,
  9.55,  2.8,   8.5,   2.8,   0,     u("Space", "plant"), coral, 8.97,  3.3,
  2.1,   1.3,   3.35,  2.3,   0,     dh("poll"),          plum,  NA,    NA,
  2.4,   0.75,  7.2,   2.15,  0.25,  dh("plant"),         plum,  NA,    NA,
  9.9,   2.3,   4.6,   2.3,   -0.35, u("Space", "poll"),  coral, NA,    NA
) |> mutate(lw = pmax(val * 0.75, 0.8), strong = val >= 1, txt = sprintf("%.0f %%", val))

seg <- function(e) {
  a <- arrow(length = unit(0.25 + 0.035 * max(e$lw), "cm"), type = "closed")
  if (e$curv == 0)
    geom_segment(data = e, aes(x, y, xend = xend, yend = yend), colour = e$col, linewidth = e$lw,
                 alpha = ifelse(e$strong, 0.95, 0.45), linetype = ifelse(e$strong, "solid", "22"),
                 arrow = a, lineend = "butt", linejoin = "mitre")
  else
    geom_curve(data = e, aes(x, y, xend = xend, yend = yend), colour = e$col, linewidth = e$lw,
               curvature = e$curv, alpha = ifelse(e$strong, 0.95, 0.45), linetype = ifelse(e$strong, "solid", "22"),
               arrow = a, lineend = "butt", ncp = 12)
}
p <- ggplot() + lapply(seq_len(nrow(edges)), function(i) seg(edges[i, ])) +
  geom_label(data = filter(edges, strong), aes(lx, ly, label = txt), colour = filter(edges, strong)$col,
             size = 8, fontface = "bold", fill = "white", border.colour = "transparent",
             label.padding = unit(0.1, "lines")) +
  geom_label(data = nodes, aes(x, y, label = label), fill = nodes$col, colour = "white", size = nodes$size,
             fontface = "bold", lineheight = 0.9, label.padding = unit(0.55, "lines"),
             label.r = unit(0.45, "lines"), border.colour = "transparent") +
  annotate("text", x = 11.85, y = 0.2, hjust = 1, size = 5.5, colour = slate,
           label = "arrow width = variation explained by that driver alone (unique fraction) · dashed: < 1 %") +
  coord_cartesian(xlim = c(0, 11.9), ylim = c(0, 5.5), expand = FALSE) +
  theme_void() + theme(plot.background = element_rect(fill = "white", colour = NA))
ggsave(file.path(out, "drivers_diagram.png"), p, width = 12, height = 6, dpi = 200)
print(edges |> select(val, txt))
