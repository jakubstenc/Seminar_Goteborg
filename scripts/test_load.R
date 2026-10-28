library(ggplot2)
library(grid)
library(png)

# Test loading badges and kytky
b_ran <- readPNG("images/badges/story_badge_ranunculus.png")
b_ach <- readPNG("images/badges/story_badge_achillea_flower.png")
b_suc <- readPNG("images/badges/story_badge_succisa_flower.png")
b_san <- readPNG("images/badges/story_badge_sanguisorba.png")
b_cen <- readPNG("images/badges/story_badge_centaurea.png")

k_ran <- readPNG("images/kytky/Ran_acr.png")
k_ach <- readPNG("images/kytky/Ach_pta.png")
k_leu <- readPNG("images/kytky/Leu_vul.png")
k_ly  <- readPNG("images/kytky/Ly_vul.png")

cat("Loaded test PNGs successfully\n")
