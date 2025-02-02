# code-peek

Plugin for peeking at code definitions and make changes in the same window

## Installation

Using Lazy

```lua
{
  "felipejz/code-peek.nvim",
 config = function()
    require("code-peek").setup({ full_file = false, context_radius = 20 })
    vim.keymap.set("n", "<leader>pp", ":CodePeek<cr>")
  end,
}

```

## Usage

- :CodePeek - Shows peek window for definition under the cursor
- q closes the peek window
