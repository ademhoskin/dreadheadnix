return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  opts = {
    provider = "deepseek",
    providers = {
      deepseek = {
        __inherited_from = "openai",
        api_key_name = "ANTHROPIC_API_KEY",
        endpoint = "https://api.deepseek.com",
        model = "deepseek-v4-pro",
        max_tokens = 8192,
      },
    },
    behaviour = {
      auto_suggestions = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = true,
    },
  },
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
}
