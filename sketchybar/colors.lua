return {
  black = 0xff393552,
  white = 0xffe0def4,
  red = 0xffeb6f92,
  green = 0xff3e8fb0,
  blue = 0xff9ccfd8,
  yellow = 0xfff6c177,
  orange = 0xfff39660,
  magenta = 0xffc4a7e7,
  grey = 0xffe0def4,
  transparent = 0x00000000,

  bar = {
    bg = 0xff232136,
    border = 0xff2c2e34,
  },
  popup = {
    bg = 0xc02c2e34,
    border = 0xff7f8490
  },
  bg1 = 0xff363944,
  bg2 = 0xff414550,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
