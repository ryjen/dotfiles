local utils = require("config.utils")

-- Colemak/HNEI directional mappings.
local directional_modes = { "n", "v" }
utils.map(directional_modes, "n", "j")
utils.map(directional_modes, "e", "k")
utils.map(directional_modes, "i", "l")
-- h remains h.

-- Preserve access to the original motions/actions shadowed above.
utils.map(directional_modes, "k", "i")
utils.map(directional_modes, "j", "n")
utils.map(directional_modes, "l", "e")

-- Faster navigation with CTRL.
utils.map(directional_modes, "<C-h>", "5h")
utils.map(directional_modes, "<C-n>", "5j")
utils.map(directional_modes, "<C-e>", "5k")
utils.map(directional_modes, "<C-i>", "5l")

-- Faster navigation is normal navigation in insert mode.
utils.map("i", "<C-h>", "<Left>")
utils.map("i", "<C-n>", "<Down>")
utils.map("i", "<C-e>", "<Up>")
utils.map("i", "<C-i>", "<Right>")

utils.map("n", "<leader><CR>", "i<CR><Esc>")

-- Start spell checker.
utils.map("n", "<C-p>", ":set spell spelllang=en_ca<CR>")

utils.map("n", "<leader>k", ":bp<CR>")
utils.map("n", "<leader>m", ":bn<CR>")
utils.map("n", "<leader>K", ":tabp<CR>")
utils.map("n", "<leader>M", ":tabn<CR>")
utils.map("n", "<leader>x", ":bd<CR>")
utils.map("n", "<leader>X", ":tabclose<CR>")
