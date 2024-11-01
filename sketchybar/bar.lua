local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
  topmost = "window",
  height = 40,
  color = colors.with_alpha(colors.black, 0.7),
  padding_right = 2,
  padding_left = 2,
})
