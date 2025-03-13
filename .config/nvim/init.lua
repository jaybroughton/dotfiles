-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- General settings configuration

vim.opt.number = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.ignorecase = true

-- Setup lazy.nvim
require("lazy").setup({
	{ "williamboman/mason.nvim" },
	{ "williamboman/mason-lspconfig.nvim" },
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
	{ "nvim-tree/nvim-tree.lua", dependencies = "nvim-tree/nvim-web-devicons" },
	{ "nvim-telescope/telescope.nvim", dependencies = "nvim-lua/plenary.nvim" },
	{ "neovim/nvim-lspconfig" },
	{ "nvim-lualine/lualine.nvim" },
	{ "hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		}
	},
	{ "folke/tokyonight.nvim",
		opts = {
			style = "night",
		},
		config = function(_, opts)
			require("tokyonight").setup(opts)
			vim.cmd [[colorscheme tokyonight]]
		end,
	}
})


-- Configure nvim-treesitter
require("nvim-treesitter.configs").setup({
	ensure_installed = { "lua", "vim", "python", "javascript", "typescript", "html", "css", "php" },
	highlight = { enable = true },
	indent = { enable = true },
})

-- Configure nvim-tree
require("nvim-tree").setup({
	view = { width = 30 },
	renderer = { group_empty = true },
	filters = { dotfiles = true },
})

vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>")

	-- Automatically start nvim-tree on nvim process
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			vim.cmd("NvimTreeOpen")
			if vim.fn.argc() > 0 then
				vim.cmd("wincmd p") -- Switch to previous file buffer
			end
		end,
	})

	-- Close nvim-tree when quitting the last buffer
	vim.api.nvim_create_autocmd("BufEnter", {
  		group = vim.api.nvim_create_augroup("NvimTreeClose", { clear = true }),
  		pattern = "NvimTree_*",
  		callback = function()
    			local layout = vim.api.nvim_call_function("winnr", { "$" })
			if layout == 1 and vim.api.nvim_buf_get_option(0, "filetype") == "NvimTree" then
				vim.cmd("quit")
			end
		end,
	})

-- Configure telescope
require("telescope").setup({
	defaults = {
		mappings = {
			i = { ["<C-u>"] = false }, -- Clear input
		},
	},
})
vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>")
vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>")
vim.keymap.set("n", "<leader>fb", ":Telescope buffers<CR>")

-- Configure mason.nvim
require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = { "lua_ls", "vimls", "pyright", "ts_ls", "html", "cssls", "intelephense", "yamlls", "jsonls" },
	automatic_installation = true,
})

-- Configure nvim-lspconfig
local lspconfig = require("lspconfig")
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

local on_attach = function(client, bufnr)
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
end

lspconfig.lua_ls.setup{
  on_attach = on_attach,
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }, -- Recognize 'vim' global for Neovim
      },
    },
  }
}
lspconfig.vimls.setup{ on_attach = on_attach }
lspconfig.pyright.setup{ on_attach = on_attach }
lspconfig.ts_ls.setup{ on_attach = on_attach }
lspconfig.html.setup{ on_attach = on_attach }
lspconfig.cssls.setup{ on_attach = on_attach }
lspconfig.intelephense.setup{ on_attach = on_attach }

-- Configure nvim-cmp
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = {
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
  },
})

	-- Ensure nvim-csp LSP capabilities are passed to servers
	local capabilities = require("cmp_nvim_lsp").default_capabilities()
	lspconfig.lua_ls.setup{
		on_attach = on_attach,
		capabilities = capabilities,
		settings = {
			Lua = {
				diagnostics = {
					globals = { 'vim' },
				},
			},
		}
	}

	lspconfig.vimls.setup{ on_attach = on_attach, capabilities = capabilities }
	lspconfig.pyright.setup{ on_attach = on_attach, capabilities = capabilities }
	lspconfig.ts_ls.setup{ on_attach = on_attach, capabilities = capabilities }
	lspconfig.html.setup{ on_attach = on_attach, capabilities = capabilities }
	lspconfig.cssls.setup{ on_attach = on_attach, capabilities = capabilities }
	lspconfig.intelephense.setup{ on_attach = on_attach, capabilities = capabilities }
	lspconfig.yamlls.setup{ on_attach = on_attach, capabilities = capabilities }
	lspconfig.jsonls.setup{ on_attach = on_attach, capabilities = capabilities }

-- Configure lualine.nvim
require("lualine").setup({
  options = {
    theme = "tokyonight",
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },
    lualine_c = { "filename" },
    lualine_x = { "encoding", "fileformat", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
})
