-- Optura colorscheme — gold-led, charcoal/off-white. Brand: https://optura.ai
-- Variant via vim.o.background: "dark" (default) | "light".

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.g.colors_name = "optura"

local light = (vim.g.optura_variant == "light") or (vim.g.optura_variant ~= "dark" and vim.o.background == "light")

local p = light and {
  bg          = "#f0eee4", bg_alt      = "#e8e4dc", bg_float    = "#ffffff",
  fg          = "#1a1616", fg_dim      = "#3a3732", fg_muted    = "#56524a", fg_faint = "#7a756a",
  cursor      = "#8b6914",
  selection   = "#d9ecf7",
  border      = "#d6d0c2", border_strong = "#a9a396",
  gold        = "#d0ae50", gold_dark   = "#8b6914",
  teal        = "#61c2ab", teal_dark   = "#2a7d6a",
  purple      = "#420d41", purple_soft = "#7e3d8a",
  blue        = "#202e42", blue_light  = "#d9ecf7",
  red         = "#a33b3b", red_soft    = "#c8595a",
  charcoal    = "#1a1616", off_white   = "#f0eee4",
  -- Roles on light bg
  string      = "#2a7d6a", -- dark teal
  number      = "#8b6914", -- dark gold
  keyword     = "#420d41", -- purple
  func        = "#8b6914", -- dark gold
  type_       = "#202e42", -- dark blue
  constant    = "#8b6914",
  operator    = "#56524a",
  param       = "#1a1616",
  comment     = "#7a756a",
  diff_add    = "#e5f2ee", diff_change = "#faf1dc", diff_delete = "#f6e2e2",
  diag_err    = "#a33b3b", diag_warn   = "#8b6914", diag_info = "#202e42", diag_hint = "#2a7d6a",
} or {
  bg          = "#1a1616", bg_alt      = "#211d1c", bg_float    = "#262320",
  fg          = "#f0eee4", fg_dim      = "#d6d0c2", fg_muted    = "#a9a396", fg_faint = "#7a756a",
  cursor      = "#d0ae50",
  selection   = "#420d41",
  border      = "#332d2b", border_strong = "#3d3634",
  gold        = "#d0ae50", gold_dark   = "#8b6914",
  teal        = "#61c2ab", teal_dark   = "#2a7d6a",
  purple      = "#420d41", purple_soft = "#7e3d8a",
  blue        = "#202e42", blue_light  = "#d9ecf7",
  red         = "#a33b3b", red_soft    = "#c8595a",
  charcoal    = "#1a1616", off_white   = "#f0eee4",
  -- Roles on dark bg
  string      = "#7ed3c0", -- bright teal (bumped for legibility on tinted bgs)
  number      = "#e6c876", -- bright gold
  keyword     = "#a86ab8", -- soft purple (lightened)
  func        = "#e6c876", -- bright gold
  type_       = "#d9ecf7", -- light blue
  constant    = "#f0d68a",
  operator    = "#b8b2a4",
  param       = "#f0eee4",
  comment     = "#8e887b",
  diff_add    = "#1f2e2a", diff_change = "#2e2820", diff_delete = "#3a1f1f",
  diag_err    = "#c8595a", diag_warn   = "#d0ae50", diag_info = "#d9ecf7", diag_hint = "#61c2ab",
}

local set = function(group, opts) vim.api.nvim_set_hl(0, group, opts) end

-- Editor base
set("Normal",        { fg = p.fg, bg = p.bg })
set("NormalFloat",   { fg = p.fg, bg = p.bg_float })
set("NormalNC",      { fg = p.fg_dim, bg = p.bg })
set("FloatBorder",   { fg = p.border_strong, bg = p.bg_float })
set("FloatTitle",    { fg = p.gold, bg = p.bg_float, bold = true })
set("Cursor",        { fg = p.bg, bg = p.cursor })
set("CursorLine",    { bg = p.bg_alt })
set("CursorColumn",  { bg = p.bg_alt })
set("CursorLineNr",  { fg = p.gold, bold = true })
set("LineNr",        { fg = p.fg_faint })
set("SignColumn",    { bg = p.bg })
set("VertSplit",     { fg = p.border })
set("WinSeparator",  { fg = p.border })
set("ColorColumn",   { bg = p.bg_alt })
set("Visual",        { bg = p.selection })
set("Search",        { fg = p.bg, bg = p.gold })
set("IncSearch",     { fg = p.bg, bg = p.teal })
set("CurSearch",     { fg = p.bg, bg = p.teal_dark, bold = true })
set("MatchParen",    { fg = p.gold, bold = true, underline = true })
set("NonText",       { fg = p.border })
set("Whitespace",    { fg = p.border })
set("EndOfBuffer",   { fg = p.bg })
set("Folded",        { fg = p.fg_muted, bg = p.bg_alt })
set("FoldColumn",    { fg = p.fg_faint, bg = p.bg })
set("WildMenu",      { fg = p.bg, bg = p.gold })
set("Directory",     { fg = p.teal })
set("Title",         { fg = p.gold, bold = true })
set("Question",      { fg = p.teal })
set("MoreMsg",       { fg = p.teal })
set("ErrorMsg",      { fg = p.red, bold = true })
set("WarningMsg",    { fg = p.gold_dark, bold = true })
set("ModeMsg",       { fg = p.fg, bold = true })
set("Conceal",       { fg = p.fg_muted })

-- Statusline / tabline
set("StatusLine",    { fg = p.fg, bg = p.bg_alt })
set("StatusLineNC",  { fg = p.fg_faint, bg = p.bg_alt })
set("TabLine",       { fg = p.fg_muted, bg = p.bg_alt })
set("TabLineSel",    { fg = p.bg, bg = p.gold, bold = true })
set("TabLineFill",   { bg = p.bg_alt })

-- Pmenu
set("Pmenu",         { fg = p.fg, bg = p.bg_float })
set("PmenuSel",      { fg = p.bg, bg = p.gold, bold = true })
set("PmenuSbar",     { bg = p.bg_alt })
set("PmenuThumb",    { bg = p.gold_dark })

-- Syntax
set("Comment",       { fg = p.comment, italic = true })
set("Constant",      { fg = p.constant })
set("String",        { fg = p.string })
set("Character",     { fg = p.string })
set("Number",        { fg = p.number })
set("Boolean",       { fg = p.number, bold = true })
set("Float",         { fg = p.number })
set("Identifier",    { fg = p.param })
set("Function",      { fg = p.func })
set("Statement",     { fg = p.keyword })
set("Conditional",   { fg = p.keyword })
set("Repeat",        { fg = p.keyword })
set("Label",         { fg = p.keyword })
set("Operator",      { fg = p.operator })
set("Keyword",       { fg = p.keyword, italic = true })
set("Exception",     { fg = p.red })
set("PreProc",       { fg = p.purple_soft })
set("Include",       { fg = p.purple_soft })
set("Define",        { fg = p.purple_soft })
set("Macro",         { fg = p.purple_soft })
set("PreCondit",     { fg = p.purple_soft })
set("Type",          { fg = p.type_ })
set("StorageClass",  { fg = p.type_ })
set("Structure",     { fg = p.type_ })
set("Typedef",       { fg = p.type_ })
set("Special",       { fg = p.teal })
set("SpecialChar",   { fg = p.teal })
set("Tag",           { fg = p.teal })
set("Delimiter",     { fg = p.fg_muted })
set("SpecialComment",{ fg = p.teal, italic = true })
set("Debug",         { fg = p.red_soft })
set("Underlined",    { fg = p.teal, underline = true })
set("Error",         { fg = p.red, bold = true })
set("Todo",          { fg = p.bg, bg = p.gold, bold = true })

-- Diff
set("DiffAdd",       { bg = p.diff_add })
set("DiffChange",    { bg = p.diff_change })
set("DiffDelete",    { fg = p.red_soft, bg = p.diff_delete })
set("DiffText",      { bg = p.diff_change, bold = true })

-- Diagnostics
set("DiagnosticError", { fg = p.diag_err })
set("DiagnosticWarn",  { fg = p.diag_warn })
set("DiagnosticInfo",  { fg = p.diag_info })
set("DiagnosticHint",  { fg = p.diag_hint })
set("DiagnosticUnderlineError", { sp = p.diag_err, undercurl = true })
set("DiagnosticUnderlineWarn",  { sp = p.diag_warn, undercurl = true })
set("DiagnosticUnderlineInfo",  { sp = p.diag_info, undercurl = true })
set("DiagnosticUnderlineHint",  { sp = p.diag_hint, undercurl = true })

-- Treesitter (legacy + modern @* groups)
set("@comment",            { link = "Comment" })
set("@string",             { link = "String" })
set("@number",             { link = "Number" })
set("@boolean",            { link = "Boolean" })
set("@function",           { link = "Function" })
set("@function.builtin",   { fg = p.teal })
set("@function.call",      { link = "Function" })
set("@method",             { link = "Function" })
set("@constructor",        { fg = p.gold, bold = true })
set("@parameter",          { fg = p.param })
set("@variable",           { fg = p.fg })
set("@variable.builtin",   { fg = p.purple_soft, italic = true })
set("@property",           { fg = p.fg })
set("@field",              { fg = p.fg })
set("@keyword",            { link = "Keyword" })
set("@keyword.operator",   { fg = p.keyword })
set("@keyword.return",     { fg = p.keyword, bold = true })
set("@type",               { link = "Type" })
set("@type.builtin",       { fg = p.type_, italic = true })
set("@constant",           { link = "Constant" })
set("@constant.builtin",   { fg = p.gold, bold = true })
set("@tag",                { fg = p.teal })
set("@tag.attribute",      { fg = p.gold })
set("@punctuation.bracket",{ fg = p.fg_muted })
set("@punctuation.delimiter",{ fg = p.fg_muted })
set("@operator",           { link = "Operator" })
set("@namespace",          { fg = p.type_ })
set("@text.title",         { link = "Title" })
set("@text.literal",       { link = "String" })
set("@text.uri",           { fg = p.teal, underline = true })
set("@text.emphasis",      { italic = true })
set("@text.strong",        { bold = true })
set("@text.warning",       { link = "WarningMsg" })
set("@text.danger",        { link = "ErrorMsg" })
set("@text.todo",          { link = "Todo" })

-- LSP semantic tokens
set("@lsp.type.namespace",  { link = "@namespace" })
set("@lsp.type.type",       { link = "@type" })
set("@lsp.type.class",      { link = "@type" })
set("@lsp.type.enum",       { link = "@type" })
set("@lsp.type.interface",  { link = "@type" })
set("@lsp.type.struct",     { link = "@type" })
set("@lsp.type.parameter",  { link = "@parameter" })
set("@lsp.type.variable",   { link = "@variable" })
set("@lsp.type.property",   { link = "@property" })
set("@lsp.type.function",   { link = "@function" })
set("@lsp.type.method",     { link = "@method" })
set("@lsp.type.macro",      { link = "Macro" })

-- Git signs
set("GitSignsAdd",    { fg = p.teal_dark })
set("GitSignsChange", { fg = p.gold })
set("GitSignsDelete", { fg = p.red })

-- Telescope
set("TelescopeBorder",        { fg = p.border_strong, bg = p.bg_float })
set("TelescopePromptBorder",  { fg = p.gold, bg = p.bg_float })
set("TelescopeSelection",     { bg = p.bg_alt, fg = p.gold, bold = true })
set("TelescopeMatching",      { fg = p.gold, bold = true })

-- Which-key / Trouble / Notify (lightweight)
set("WhichKey",        { fg = p.gold })
set("WhichKeyGroup",   { fg = p.teal })
set("WhichKeyDesc",    { fg = p.fg })
set("WhichKeySeparator", { fg = p.fg_faint })

-- Terminal ANSI (when nvim opens :terminal)
vim.g.terminal_color_0  = p.charcoal
vim.g.terminal_color_1  = "#a33b3b"
vim.g.terminal_color_2  = light and "#2a7d6a" or "#2a7d6a"
vim.g.terminal_color_3  = light and "#8b6914" or "#d0ae50"
vim.g.terminal_color_4  = "#202e42"
vim.g.terminal_color_5  = "#420d41"
vim.g.terminal_color_6  = light and "#2a7d6a" or "#61c2ab"
vim.g.terminal_color_7  = light and "#56524a" or "#d6d0c2"
vim.g.terminal_color_8  = light and "#7a756a" or "#56524a"
vim.g.terminal_color_9  = "#c8595a"
vim.g.terminal_color_10 = light and "#2a7d6a" or "#61c2ab"
vim.g.terminal_color_11 = light and "#d0ae50" or "#e6c876"
vim.g.terminal_color_12 = light and "#202e42" or "#d9ecf7"
vim.g.terminal_color_13 = light and "#420d41" or "#7e3d8a"
vim.g.terminal_color_14 = light and "#61c2ab" or "#7ed3c0"
vim.g.terminal_color_15 = light and "#1a1616" or "#ffffff"
