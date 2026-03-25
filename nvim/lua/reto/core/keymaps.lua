local opts = { noremap = true, silent = true }

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set({ "n", "i", "v", "s" }, "<M-c>", "<C-c>", {
    desc = "Alt+c acts like Ctrl+c",
})

vim.keymap.set("i", "<M-l>", "<C-o>$", {desc = "End of line (insert)" })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", {desc = "moves lines down in visual selection" })
vim.keymap.set("v", "K", ":m '>-2<CR>gv=gv", {desc = "moves lines up in visual selection" })

vim.keymap.set("n", "<C-c>", ":nohl<CR>", {desc = "Clear search hl", silent = true })

--split management
vim.keymap.set("n", "<leader>sh", "<C-w>v", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sv", "<C-w>s", { desc = "Split window horizontally" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })
--split movement
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left split" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower split" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper split" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right split" })

vim.keymap.set("v", "<", "<gv", opts)
vim.keymap.set("v", ">", ">gv", opts)

vim.keymap.set("n", "<leader>fh", function()
  local filename = vim.fn.expand("%:t")
  local author = "Reto Althaus"

  local filepath = vim.fn.expand("%:p")
  local stat = vim.loop.fs_stat(filepath)

  local created

  if stat and stat.mtime then
    -- existing file → use first modification time
    created = os.date("%d-%m-%Y", stat.mtime.sec)
  else
    -- new unsaved file → use today
    created = os.date("%d-%m-%Y")
  end

  local header = {
    "/**",
    " * ----------------------------------------",
    " *  File Name:  " .. filename,
    " *  Author:     " .. author,
    " *  Created:    " .. created,
    " * ----------------------------------------",
    " */",
    "",
  }

  vim.api.nvim_buf_set_lines(0, 0, 0, false, header)
end, { desc = "Insert file header" })

