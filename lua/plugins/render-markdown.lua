return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      -- Enable rendering in these file types
      file_types = { "markdown", "Avante" },

      -- Heading icons and highlights
      heading = {
        -- Turn on / off heading icon & background
        enabled = true,
        -- Turn on / off any sign column related rendering
        sign = true,
        -- Replaces '#+' of headings
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        -- The 'level' is used to index into the array using a cycle
        -- Highlight for the heading icon and extends through the entire line
        backgrounds = {
          "RenderMarkdownH1Bg",
          "RenderMarkdownH2Bg",
          "RenderMarkdownH3Bg",
          "RenderMarkdownH4Bg",
          "RenderMarkdownH5Bg",
          "RenderMarkdownH6Bg",
        },
        -- The 'level' is used to index into the array using a clamp
        foregrounds = {
          "RenderMarkdownH1",
          "RenderMarkdownH2",
          "RenderMarkdownH3",
          "RenderMarkdownH4",
          "RenderMarkdownH5",
          "RenderMarkdownH6",
        },
      },

      -- Code block styling
      code = {
        -- Turn on / off code block & inline code rendering
        enabled = true,
        -- Turn on / off any sign column related rendering
        sign = true,
        -- Determines how code blocks & inline code are rendered
        style = "full", -- 'full': adds a block background, 'normal': just highlights inline code, 'language': adds language icon
        -- Width of the code block background
        width = "block", -- 'full': full width, 'block': width of the code block
        -- Amount of padding to add to the left of code blocks
        left_pad = 0,
        -- Amount of padding to add to the right of code blocks when width is 'block'
        right_pad = 0,
        -- Determins how the top / bottom of code block are rendered
        border = "thin", -- 'thin': use thin border characters, 'thick': use thick border characters
        -- Highlight for code blocks
        highlight = "RenderMarkdownCode",
        highlight_inline = "RenderMarkdownCodeInline",
      },

      -- Bullet points for lists
      bullet = {
        -- Turn on / off list bullet rendering
        enabled = true,
        -- Replaces '-'|'+'|'*' of 'list_item'
        icons = { "●", "○", "◆", "◇" },
        -- Highlight for the bullet icon
        highlight = "RenderMarkdownBullet",
      },

      -- Checkboxes
      checkbox = {
        -- Turn on / off checkbox state rendering
        enabled = true,
        unchecked = {
          icon = "󰄱 ",
          highlight = "RenderMarkdownUnchecked",
        },
        checked = {
          icon = "󰱒 ",
          highlight = "RenderMarkdownChecked",
        },
        custom = {
          todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
        },
      },

      -- Block quotes
      quote = {
        -- Turn on / off block quote & callout rendering
        enabled = true,
        icon = "▋",
        highlight = "RenderMarkdownQuote",
      },

      -- Pipe tables
      pipe_table = {
        -- Turn on / off pipe table rendering
        enabled = true,
        -- Determines how the table as a whole is rendered
        style = "full", -- 'full': adds a block background, 'normal': no additional rendering
        -- Highlight for table heading and delimiter
        head = "RenderMarkdownTableHead",
        row = "RenderMarkdownTableRow",
      },

      -- Callouts
      callout = {
        note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
        tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
        important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
        warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
        caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
      },
    },
  },
}
