# Slide illustration: whole-day network vs hourly slices (Global generalists, local specialists)
# Conceptual only: node identities and links are illustrative, not data.
# The daily network is the union of the three hourly networks, so the audience sees
# that a "generalist" in the daily web is a series of short specialised bouts.
# Run from the Seminar_Goteborg folder:  Rscript scripts/fig_diu_concept.R
suppressMessages({library(ggplot2); library(dplyr); library(tibble)})
out <- "images"

navy <- "#3B0F70"; rose <- "#B63679"; coral <- "#F8765C"; green <- "#40695B"
slate <- "#64748B"; ink <- "#1E293B"; faint <- "#E2E8F0"; grey_link <- "#94A3B8"
hour_cols <- c(`09:00` = navy, `12:00` = rose, `15:00` = coral)

n_pol <- 6; n_pl <- 5
links <- tribble(
  ~pol, ~pl, ~hour,
  1, 1, "09:00", 2, 1, "09:00", 2, 2, "09:00", 3, 1, "09:00",
  3, 3, "12:00", 4, 3, "12:00", 4, 4, "12:00", 5, 2, "12:00",
  3, 5, "15:00", 5, 4, "15:00", 6, 5, "15:00", 6, 4, "15:00")
focal <- 3   # pollinator that is active all day but switches plants

# panel geometry: x offset and width
panels <- tribble(
  ~panel,   ~x0,  ~w,
  "day",     0,   9,
  "09:00",  13.2, 6.2,
  "12:00",  21.4, 6.2,
  "15:00",  29.6, 6.2)
y_pol <- 1; y_pl <- 0

node_xy <- function(x0, w) {
  bind_rows(
    tibble(type = "pol", id = 1:n_pol, x = x0 + seq(0, w, length.out = n_pol), y = y_pol),
    tibble(type = "pl",  id = 1:n_pl,  x = x0 + seq(w * 0.1, w * 0.9, length.out = n_pl), y = y_pl))
}
nodes <- panels |> rowwise() |> do(cbind(panel = .$panel, node_xy(.$x0, .$w))) |> ungroup()

edge_xy <- function(l, pan) {
  np <- filter(nodes, panel == pan)
  l |> mutate(panel = pan,
              x = np$x[np$type == "pol"][pol], y = y_pol,
              xend = np$x[np$type == "pl"][pl], yend = y_pl)
}
e_day <- edge_xy(links, "day")
e_hr <- bind_rows(lapply(names(hour_cols), function(h) edge_xy(filter(links, hour == h), h)))

# activity of nodes per hour
act <- bind_rows(
  links |> transmute(hour, type = "pol", id = pol),
  links |> transmute(hour, type = "pl", id = pl)) |> distinct() |> mutate(active = TRUE)
nodes <- nodes |>
  left_join(act, by = c("panel" = "hour", "type", "id")) |>
  mutate(active = ifelse(panel == "day", TRUE, !is.na(active)),
         fill = case_when(panel == "day" ~ slate,
                          active ~ hour_cols[panel],
                          TRUE ~ faint),
         shape = ifelse(type == "pol", 21, 22),
         is_focal = type == "pol" & id == focal & active)

ctr <- function(p) with(filter(panels, panel == p), x0 + w / 2)

g <- ggplot() +
  # links (focal pollinator's daily links keep their hour colour)
  geom_segment(data = filter(e_day, pol != focal), aes(x, y, xend = xend, yend = yend),
               colour = grey_link, linewidth = 1.1, alpha = 0.8) +
  geom_segment(data = filter(e_day, pol == focal), aes(x, y, xend = xend, yend = yend, colour = hour),
               linewidth = 1.8) +
  geom_segment(data = e_hr, aes(x, y, xend = xend, yend = yend, colour = hour), linewidth = 1.8) +
  # focal pollinator ring
  geom_point(data = filter(nodes, is_focal), aes(x, y), shape = 21, size = 11.5, stroke = 1.6,
             colour = ink, fill = NA) +
  # nodes
  geom_point(data = nodes, aes(x, y, fill = I(fill), shape = I(shape)), size = 8, colour = "white", stroke = 1.2) +
  scale_colour_manual(values = hour_cols, guide = "none") +
  # row labels
  annotate("text", x = -0.7, y = y_pol, label = "Pollinators", hjust = 1, size = 6.5, colour = ink) +
  annotate("text", x = -0.7, y = y_pl, label = "Plants", hjust = 1, size = 6.5, colour = ink) +
  # panel titles
  annotate("text", x = ctr("day"), y = 1.55, label = "Whole day", size = 8, fontface = "bold", colour = ink) +
  annotate("text", x = sapply(names(hour_cols), ctr), y = 1.55, label = names(hour_cols),
           size = 8, fontface = "bold", colour = hour_cols) +
  # captions
  annotate("text", x = ctr("day"), y = -0.55, size = 6, colour = slate, lineheight = 0.95,
           label = "everyone looks like\na generalist") +
  annotate("text", x = ctr("12:00"), y = -0.55, size = 6, colour = slate, lineheight = 0.95,
           label = "few partners per hour, and they change from hour to hour") +
  # arrow: split by hour
  annotate("segment", x = 9.9, xend = 12.2, y = 0.5, yend = 0.5, colour = ink, linewidth = 1.3,
           arrow = arrow(length = unit(0.22, "cm"), type = "closed")) +
  annotate("text", x = 11.05, y = 0.72, label = "split\nby hour", size = 5.5, colour = ink, lineheight = 0.9) +
  # rewiring arrows between hours
  annotate("segment", x = c(19.75, 27.95), xend = c(21.05, 29.25), y = 0.5, yend = 0.5, colour = slate,
           linewidth = 1.1, linetype = "22", arrow = arrow(length = unit(0.22, "cm"), type = "closed")) +
  annotate("text", x = c(20.4, 28.6), y = 0.68, label = "rewiring", size = 4.8, colour = slate,
           fontface = "italic") +
  coord_cartesian(xlim = c(-4.2, 36.2), ylim = c(-0.85, 1.85), clip = "off") +
  theme_void() +
  theme(plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(12, 10, 5, 10))

ggsave(file.path(out, "diu_conceptual.png"), g, width = 13, height = 4.9, dpi = 200)
file.copy(file.path(out, "diu_conceptual.png"), file.path("docs/images", "diu_conceptual.png"), overwrite = TRUE)
