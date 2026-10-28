# Extra analyses of the Freudenfeld et al. (2025) Handrkov data for the deck
#   1. Load purity: share of the catch-plant's own pollen in each insect's load
#   2. Carrier vs flower: variance in load and purity due to pollinator group vs catch plant
#   4. Pollen transported per group per year (visit density x mean load) and community stability
#   5. Pollen-transport network vs visitation network
# Run from Seminar_Goteborg:  Rscript scripts/fig_freud_more.R
suppressMessages({library(readxl); library(dplyr); library(tidyr); library(ggplot2); library(lme4)})

src <- "../../Psani_clanku/2024/Martin/martin_clanek_rko/clanek1"
out <- "images"
green <- "#40695B"; navy <- "#3B0F70"; plum <- "#8C2981"; rose <- "#B63679"
coral <- "#F8765C"; peach <- "#FEB47B"; slate <- "#64748B"; grid_col <- "#E2E8F0"
order_cols <- c(Hymenoptera = navy, Diptera = coral, Lepidoptera = plum, Coleoptera = green)
theme_deck <- theme_minimal(base_size = 24, base_family = "sans") +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_blank(),
        axis.text = element_text(colour = "#334155"), axis.title = element_text(colour = "#1E293B"),
        legend.position = "top", legend.title = element_blank(),
        plot.background = element_rect(fill = "white", colour = NA))
cv <- function(x) sd(x) / mean(x)

# ---- data -------------------------------------------------------------------
# NB: pol_skl and dru_pol_skl are two counts of the same slide (cele_sklo = their sum,
# opr_pol_skl = load per 1/4 body); pollen identity comes from the composition table.
p <- read_excel(file.path(src, "stery_zakl_tab.xlsx")) |>
  mutate(load = opr_pol_skl, order = ifelse(order %in% names(order_cols), order, "Other"),
         t = suppressWarnings(as.numeric(`čas`)) * 24)
comp <- read.delim(file.path(src, "slozeni_pylu_proc.txt"), colClasses = c(ID = "character"))
ptypes <- setdiff(names(comp), "ID")
m <- match(p$id, comp$ID)                                       # match by insect ID, not row
p$own <- sapply(seq_len(nrow(p)), function(i)
  if (is.na(m[i]) || !(p$kytka2[i] %in% ptypes)) NA_real_ else comp[m[i], p$kytka2[i]])
cat("insects:", nrow(p), " with composition:", sum(!is.na(p$own)), "\n")

# ---- 1. purity per group ---------------------------------------------------
hover <- p |> filter(family == "Syrphidae") |> distinct(skup_opr) |> pull()
pur <- p |> filter(!is.na(own)) |> group_by(skup_opr, order) |>
  summarise(n = n(), med = median(own), q1 = quantile(own, .25), q3 = quantile(own, .75), .groups = "drop") |>
  filter(n >= 10) |> arrange(med)
print(pur, n = 50)
pd <- p |> filter(!is.na(own), skup_opr %in% pur$skup_opr) |>
  mutate(skup_opr = factor(skup_opr, levels = pur$skup_opr))
pur$skup_opr <- factor(pur$skup_opr, levels = pur$skup_opr)
lab_face <- ifelse(levels(pur$skup_opr) %in% hover, "bold.italic", "italic")

g_pur <- ggplot(pd, aes(skup_opr, own * 100)) +
  geom_point(aes(colour = order), position = position_jitter(width = 0.18, height = 0, seed = 1),
             alpha = 0.3, size = 1.6, show.legend = FALSE) +
  geom_errorbar(data = pur, aes(x = skup_opr, ymin = q1 * 100, ymax = q3 * 100, colour = order),
                inherit.aes = FALSE, width = 0, linewidth = 1.1) +
  geom_point(data = pur, aes(x = skup_opr, y = med * 100, fill = order), inherit.aes = FALSE,
             shape = 21, colour = "white", size = 4, stroke = 0.8) +
  scale_colour_manual(values = c(order_cols, Other = slate)) +
  scale_fill_manual(values = c(order_cols, Other = slate)) +
  guides(fill = guide_legend(override.aes = list(size = 5))) +
  labs(x = NULL, y = "Own pollen in the load (%)\n(plant the insect was caught on)") +
  theme_deck +
  theme(axis.text.x = element_text(angle = 50, hjust = 1, size = 14, face = lab_face))
ggsave(file.path(out, "freud_purity.png"), g_pur, width = 11, height = 6.2, dpi = 200)
ggsave(file.path("docs", out, "freud_purity.png"), g_pur, width = 11, height = 6.2, dpi = 200)

# ---- 2. carrier vs flower -----------------------------------------------------
vshare <- function(fit) { v <- as.data.frame(VarCorr(fit)); setNames(v$vcov / sum(v$vcov), v$grp) }
m_load <- lmer(log10(load + 1) ~ (1 | skup_opr) + (1 | kytka2), data = p)
m_pur  <- lmer(qlogis(pmin(pmax(own, 0.01), 0.99)) ~ (1 | skup_opr) + (1 | kytka2), data = filter(p, !is.na(own)))
vs <- rbind(load = vshare(m_load), purity = vshare(m_pur)); print(round(vs, 3))
vp <- as.data.frame(vs) |> mutate(what = c("Pollen load", "Own-pollen share")) |>
  pivot_longer(c(skup_opr, kytka2), names_to = "src", values_to = "share") |>
  mutate(src = factor(ifelse(src == "skup_opr", "Pollinator group", "Plant it was caught on"),
                      levels = c("Pollinator group", "Plant it was caught on")),
         what = factor(what, levels = c("Pollen load", "Own-pollen share")))
g_vp <- ggplot(vp, aes(what, share * 100, fill = src)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  geom_text(aes(label = sprintf("%.0f %%", share * 100)), position = position_dodge(width = 0.75),
            vjust = -0.4, size = 7.5, colour = "#1E293B") +
  scale_fill_manual(values = c("Pollinator group" = coral, "Plant it was caught on" = green)) +
  scale_y_continuous(limits = c(0, 62), expand = expansion(mult = c(0, 0))) +
  labs(x = NULL, y = "Variance explained (%)") + theme_deck
ggsave(file.path(out, "freud_carrier_vs_flower.png"), g_vp, width = 9, height = 6.2, dpi = 200)
ggsave(file.path("docs", out, "freud_carrier_vs_flower.png"), g_vp, width = 9, height = 6.2, dpi = 200)

# time of day (pooled), for the notes
print(summary(lm(log10(load + 1) ~ t, data = p))$coef["t", ])
print(summary(lm(own ~ t, data = p))$coef["t", ])

# ---- 4. pollen transported per group per year ---------------------------------
d <- read_excel(file.path(src, "density_roky.xlsx")) |>
  mutate(denzita = as.numeric(denzita), skupina = recode(skupina, Calliphoridae = "Lucilia")) |>
  filter(!is.na(denzita))
ml <- p |> group_by(skup_opr) |> summarise(mload = mean(load), order = first(order))
tr <- d |> inner_join(ml, by = c("skupina" = "skup_opr")) |> mutate(transport = denzita * mload)
cat("groups in transport:", n_distinct(tr$skupina), "\n")
tot <- tr |> group_by(rok) |> summarise(transport = sum(transport), visits = sum(denzita))
gcv <- tr |> group_by(skupina) |> summarise(cv = cv(transport), mean = mean(transport)) |> filter(mean > 0)
w_cv <- with(gcv, sum(cv * mean) / sum(mean))                   # abundance-weighted mean group CV
sync <- var(tot$transport) / sum(tapply(tr$transport, tr$skupina, sd))^2   # Loreau & de Mazancourt phi
stab <- c(cv_total = cv(tot$transport), cv_total_visits = cv(tot$visits),
          median_group_cv = median(gcv$cv), weighted_group_cv = w_cv, synchrony = sync)
print(round(stab, 2))
share <- tr |> group_by(skupina) |> summarise(T = sum(transport), V = sum(denzita)) |>
  mutate(T = T / sum(T), V = V / sum(V)) |> arrange(desc(T)); print(head(share, 12))

top <- share$skupina[1:6]
tr_plot <- tr |> mutate(grp = ifelse(skupina %in% top, skupina, "Other groups")) |>
  group_by(rok, grp) |> summarise(transport = sum(transport), .groups = "drop") |>
  mutate(grp = factor(grp, levels = c(top, "Other groups")))
pal6 <- c(navy, coral, rose, green, plum, peach, "#CBD5E1")
g_tr1 <- ggplot(tr_plot, aes(rok, transport / 1000, fill = grp)) +
  geom_area(colour = "white", linewidth = 0.3) +
  scale_fill_manual(values = setNames(pal6, levels(tr_plot$grp))) +
  scale_x_continuous(breaks = 2011:2021) +
  labs(x = NULL, y = "Pollen transported\n(thousand grains per survey)") +
  theme_deck + theme(legend.text = element_text(face = "italic", size = 17)) +
  guides(fill = guide_legend(nrow = 2))
ggsave(file.path(out, "freud_transport_1_stack.png"), g_tr1, width = 11, height = 6.2, dpi = 200)
ggsave(file.path("docs", out, "freud_transport_1_stack.png"), g_tr1, width = 11, height = 6.2, dpi = 200)

cvd <- gcv |> filter(skupina %in% top) |> transmute(what = skupina, cv, kind = "group") |>
  bind_rows(tibble(what = c("Median of all groups", "Whole community"),
                   cv = c(median(gcv$cv), cv(tot$transport)), kind = c("median", "total"))) |>
  mutate(what = factor(what, levels = what[order(-cv)]))
g_tr2 <- ggplot(cvd, aes(what, cv, fill = kind)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = sprintf("%.2f", cv)), vjust = -0.4, size = 7, colour = "#1E293B") +
  scale_fill_manual(values = c(group = "#CBD5E1", median = slate, total = green), guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(x = NULL, y = "CV of pollen transport\nacross years (2011–2021)") +
  theme_deck + theme(axis.text.x = element_text(angle = 30, hjust = 1, size = 17))
ggsave(file.path(out, "freud_transport_2_cv.png"), g_tr2, width = 11, height = 6.2, dpi = 200)
ggsave(file.path("docs", out, "freud_transport_2_cv.png"), g_tr2, width = 11, height = 6.2, dpi = 200)

# ---- 5. transport network vs visitation network ---------------------------------

# visitation profile at Handrkov 2020-2021 (diurnal transects), mapped to the same groups / pollen types
v <- read.csv("../../Psani_clanku/2026/DiuHanPolNet/data/diurnal_interactions.csv") |> filter(Year %in% 2020:2021)
gmap <- function(sp, fam, ord) dplyr::case_when(
  sp == "Apis_mellifera" ~ "Apis", sp == "Bombus_lapidarius" ~ "Bombus lapidarius",
  sp == "Bombus_pascuorum" ~ "Bombus pascuorum", sp == "Bombus_terrestris_agg" ~ "Bombus terrestris",
  fam == "Halictidae" ~ "Halictidae", fam == "Melittidae" ~ "Melittidae",
  fam %in% c("Andrenidae", "Colletidae", "Megachilidae") | grepl("^(Bombus|Nomada|Epeoloides|Anthophila)", sp) ~ "Other bees",
  fam == "Tenthredinidae" ~ "Tenthredinidae", fam == "Cerambycidae" ~ "Cerambycidae",
  fam == "Mordellidae" ~ "Mordella", fam == "Cantharidae" ~ "Rhagonycha",
  sp == "Chrysogaster_sp" ~ "Chrysogaster", sp == "Episyrphus_balteatus" ~ "Episyrphus",
  sp == "Eristalis_arbustorum" ~ "Eristalis arbustorum", sp == "Eristalis_interrupta" ~ "Eristalis interruptus",
  sp == "Eristalis_pertinax" ~ "Eristalis pertinax", sp == "Eristalis_tenax" ~ "Eristalis tenax",
  sp == "Helophilus_hybridus" ~ "Helophilus hybridus", sp == "Helophilus_pendulus" ~ "Helophilus pendulus",
  sp == "Helophilus_trivittatus" ~ "Helophilus trivittatus", sp == "Platycheirus_Melanostoma_agg" ~ "Melanostoma",
  grepl("^Parasyrphus", sp) ~ "Parasyrphus", sp == "Sphaerophoria_agg" ~ "Sphaerophoria",
  sp == "Syritta_pipiens" ~ "Syritta", sp == "Syrphus_agg" ~ "Syrphus", fam == "Syrphidae" ~ "Other Syrphidae",
  fam == "Calliphoridae" ~ "Lucilia", fam == "Sarcophagidae" ~ "Sarcophagidae",
  grepl("^(Phasia|Gymnosoma|Cylindromyia)", sp) ~ "Small Tachinidae", fam == "Tachinidae" ~ "Tachinidae",
  sp == "Satyrini_other" ~ "Coenonympha", grepl("^Pieris", sp) ~ "Pieris", sp == "Zygaena_sp" ~ "Zygaena",
  TRUE ~ NA_character_)
pmap <- function(pl) dplyr::case_when(
  grepl("^Achillea", pl) ~ "Ach_sp", pl == "Centaurea jacea" ~ "Cen_jac",
  grepl("^(Leontodon|Crepis|Hieracium|Hypochaeris|Taraxacum|Pilosella|Tragopogon|Scorzoneroides|Picris)", pl) ~ "Cichor",
  pl == "Cirsium palustre" ~ "Cir_pal", pl == "Daucus carota" ~ "Dau_car", grepl("^Galium", pl) ~ "Gal_sp",
  pl == "Heracleum sphondylium" ~ "Her_sph", grepl("^Hypericum", pl) ~ "Hyp_sp",
  pl == "Lathyrus pratensis" ~ "Lat_pra", pl == "Lotus corniculatus" ~ "Lot_cor",
  pl == "Lysimachia vulgaris" ~ "Lys_vul", pl == "Lythrum salicaria" ~ "Lyt_sal",
  pl == "Pimpinella saxifraga" ~ "Pim_sax", pl == "Plantago lanceolata" ~ "Pla_lan",
  grepl("^Potentilla", pl) ~ "Pot_sp", pl == "Prunella vulgaris" ~ "Pru_vul", grepl("^Ranunculus", pl) ~ "Ran_sp",
  pl == "Sanguisorba officinalis" ~ "San_off", pl == "Selinum carvifolia" ~ "Sel_car",
  grepl("^(Senecio|Leucanthemum|Jacobaea)", pl) ~ "SenLeu", pl == "Serratula tinctoria" ~ "Ser_tin",
  pl == "Succisa pratensis" ~ "Suc_pra", grepl("^Trifolium", pl) ~ "Tri_sp", TRUE ~ "Ostatni")
vv <- v |> mutate(skup_opr = gmap(Insect_species, Insect_family, Insect_order), ptype = pmap(Plant_species)) |>
  filter(!is.na(skup_opr)) |> group_by(skup_opr, ptype) |> summarise(visits = sum(Interaction_count), .groups = "drop")
cat("mapped visits 2020-21:", sum(vv$visits), "of", sum(v$Interaction_count), "\n")

# Pollen profile of each group = grains of each pollen type (load x composition).
# Insects were caught on chosen plants (157 of 618 on Selinum), so individuals are reweighted
# so that, within a group, their catch plants follow that group's visit distribution.
vg <- vv |> group_by(skup_opr) |> mutate(Vs = visits / sum(visits)) |> ungroup() |> select(skup_opr, kytka2 = ptype, Vs)
cp <- p |> filter(!is.na(m)) |> select(id, skup_opr, kytka2, load) |> bind_cols(comp[m[!is.na(m)], ptypes]) |>
  group_by(skup_opr, kytka2) |> mutate(nk = n()) |> ungroup() |>
  left_join(vg, by = c("skup_opr", "kytka2")) |> mutate(w = ifelse(is.na(Vs), 0, Vs / nk))
cat("insects with weight > 0:", sum(cp$w > 0), "\n")
pp <- cp |> pivot_longer(all_of(ptypes), names_to = "ptype", values_to = "f") |>
  group_by(skup_opr, ptype) |> summarise(grains = sum(w * f * load), .groups = "drop")

net <- full_join(pp, vv, by = c("skup_opr", "ptype")) |> replace_na(list(grains = 0, visits = 0)) |>
  group_by(skup_opr) |> mutate(P = grains / sum(grains), V = visits / sum(visits), nv = sum(visits)) |>
  ungroup() |> filter(is.finite(P), is.finite(V))
# per group: overlap of pollen and visit profiles (sum of minima, 0-1)
ov <- net |> group_by(skup_opr) |> summarise(overlap = sum(pmin(P, V)), nv = first(nv)) |>
  filter(nv >= 30) |> arrange(overlap); print(ov, n = 40)
# community level: each group's pollen profile scaled by its number of visits
cw <- net |> mutate(Pg = P * nv) |> group_by(ptype) |> summarise(P = sum(Pg), V = sum(visits)) |>
  mutate(P = P / sum(P), V = V / sum(V)) |> arrange(desc(P)); print(cw, n = 30)

keep_g <- ov$skup_opr[ov$nv >= 100]   # well-sampled groups only, for readability
keep_p <- cw |> filter(ptype != "Ostatni") |> mutate(s = P + V) |> arrange(desc(s)) |> slice(1:12) |> pull(ptype)
pname <- c(Ach_sp = "Achillea", Cen_jac = "Centaurea", Cichor = "Cichorieae", Cir_pal = "Cirsium", Dau_car = "Daucus",
           Gal_sp = "Galium", Her_sph = "Heracleum", Hyp_sp = "Hypericum", Lat_pra = "Lathyrus", Lot_cor = "Lotus",
           Lys_vul = "Lysimachia", Lyt_sal = "Lythrum", Pim_sax = "Pimpinella", Pla_lan = "Plantago", Pot_sp = "Potentilla",
           Pru_vul = "Prunella", Ran_sp = "Ranunculus", San_off = "Sanguisorba", Sel_car = "Selinum", SenLeu = "Senecio/Leuc.",
           Ser_tin = "Serratula", Suc_pra = "Succisa", Tri_sp = "Trifolium", Ostatni = "Other")
hm <- net |> filter(skup_opr %in% keep_g, ptype %in% keep_p) |>
  select(skup_opr, ptype, Visits = V, Pollen = P) |>
  pivot_longer(c(Visits, Pollen), names_to = "net", values_to = "share") |>
  mutate(net = factor(net, levels = c("Visits", "Pollen")),
         skup_opr = factor(skup_opr, levels = rev(keep_g)),
         ptype = factor(pname[ptype], levels = pname[keep_p]))
g_net <- ggplot(hm, aes(ptype, skup_opr, fill = share * 100)) +
  geom_tile(colour = "white", linewidth = 0.6) +
  facet_wrap(~net, labeller = as_labeller(c(Visits = "Visits: which flowers they visit",
                                             Pollen = "Pollen: whose pollen they carry"))) +
  scale_fill_gradientn(colours = c("#F8FAFC", peach, coral, rose, navy), limits = c(0, 100),
                       name = "% of the\ngroup's total") +
  labs(x = NULL, y = NULL) + theme_deck +
  theme(axis.text.x = element_text(angle = 50, hjust = 1, size = 15, face = "italic"),
        axis.text.y = element_text(size = 15, face = "italic"), strip.text = element_text(size = 18, face = "bold"),
        legend.position = "right", legend.title = element_text(size = 13), legend.text = element_text(size = 12),
        panel.grid = element_blank())
ggsave(file.path(out, "freud_transport_network.png"), g_net, width = 13, height = 6.4, dpi = 200)
ggsave(file.path("docs", out, "freud_transport_network.png"), g_net, width = 13, height = 6.4, dpi = 200)

# community: pollen share vs visit share per plant
cwp <- cw |> filter(ptype %in% keep_p) |> mutate(plant = factor(pname[ptype], levels = pname[keep_p])) |>
  pivot_longer(c(V, P), names_to = "what", values_to = "share") |>
  mutate(what = factor(ifelse(what == "V", "Share of visits", "Share of carried pollen"),
                       levels = c("Share of visits", "Share of carried pollen")))

ann <- tibble(
  plant = factor(c("Selinum", "Succisa", "Potentilla", "Sanguisorba", "Trifolium"), levels = pname[keep_p]),
  y = c(15.5, 12.3, 10.8, 9.6, 4.6),
  label = c("+2×", "-3×", "+2×", "-3×", "-7×"),
  col = c("#1B6B4A", "#C2410C", "#1B6B4A", "#C2410C", "#C2410C")
)

g_cw <- ggplot(cwp, aes(plant, share * 100, fill = what)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.75) +
  geom_text(data = ann, aes(x = plant, y = y, label = label, colour = I(col)),
            inherit.aes = FALSE, fontface = "bold", size = 6.2) +
  scale_fill_manual(values = c("Share of visits" = "#94A3B8", "Share of carried pollen" = "#B63679")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08)), breaks = seq(0, 30, by = 10)) +
  labs(x = NULL, y = "% of the whole community") + theme_deck +
  theme(axis.text.x = element_text(angle = 40, hjust = 1, size = 18, face = "italic"),
        legend.text = element_text(size = 18),
        panel.grid = element_blank())
ggsave(file.path(out, "freud_transport_vs_visits.png"), g_cw, width = 13.5, height = 6.2, dpi = 220)
ggsave(file.path("docs", out, "freud_transport_vs_visits.png"), g_cw, width = 13.5, height = 6.2, dpi = 220)

saveRDS(list(pur = pur, vs = vs, stab = stab, share = share, ov = ov, cw = cw), "scripts/freud_more_results.rds")
