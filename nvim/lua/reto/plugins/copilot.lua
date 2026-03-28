return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = "<M-CR>",
          next = "<M-n>",
          prev = "<M-p>",
        },
      },
      panel = {
        enabled = true,
        keymap = {
          open = "<M-l>",
        },
      },
    },
  },
}
