# Modify slav_pres_hp_landscape.png using magick in R:
# 1. Read existing image
# 2. Crop/paint over the stigma cartoon icons at the top of CP and HP
# 3. Add clean text labels for Conspecific (CP) and Heterospecific (HP)
library(magick)

img_path <- "images/slav_pres_hp_landscape.png"
img <- image_read(img_path)
info <- image_info(img)

# Create a clean white patch over the cartoon icons
# The cartoon icons are situated above the CP and HP headers.
# Let's inspect where they are in pixels:
# width is ~2640, height is ~1188 (at 220 dpi, 12x5.4 inches = 2640 x 1188)
w <- info$width
h <- info$height

# In relative terms, the right side starts around x = 0.50 * w to 0.98 * w
# The top area with the icons is from y = 0 to y = 0.20 * h
# Let's paint a crisp white rectangle over the top header area of the right panels:
# x from ~0.50 * w to w, y from 0 to ~0.20 * h
# Then draw clean bold text: "Conspecific (CP)" and "Heterospecific (HP)"

# Draw white rectangle over the icons & old CP/HP labels:
# Left panel (CP): center around x = 0.635 * w
# Right panel (HP): center around x = 0.880 * w
# Y-range of icons and labels: y = 20 to y = 230

img_clean <- image_draw(img)
rect(xleft = 0.48 * w, ytop = 0, xright = w, ybottom = 0.20 * h, col = "white", border = NA)

# Match ggplot2 font face and size
text(x = 0.635 * w, y = 0.145 * h, labels = "Conspecific (CP)", font = 2, cex = 3.6, col = "#1E293B")
text(x = 0.880 * w, y = 0.145 * h, labels = "Heterospecific (HP)", font = 2, cex = 3.6, col = "#1E293B")
dev.off()

image_write(img_clean, "images/slav_pres_hp_landscape.png")
image_write(img_clean, "docs/images/slav_pres_hp_landscape.png")

message("Successfully updated slav_pres_hp_landscape.png!")
