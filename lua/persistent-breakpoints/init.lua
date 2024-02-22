local cfg = require("persistent-breakpoints.config")
local inmem_bps = require("persistent-breakpoints.inmemory")
local utils = require("persistent-breakpoints.utils")

local M = {}

M.setup = function(_cfg)
  _cfg = _cfg or {}
  local tmp_config = vim.tbl_deep_extend("force", cfg, _cfg)
  for key, val in pairs(tmp_config) do
    cfg[key] = val
  end
  inmem_bps.bps = utils.load_bps(utils.get_bps_path()) -- {'filename':breakpoints_table}

  -- load all buffers with a breakpoint set
  vim.schedule(function()
    if vim.bo.filetype ~= "gitcommit" then
      for file in pairs(inmem_bps.bps) do
        local bufnr = vim.fn.bufadd(file)
        vim.fn.bufload(bufnr)
        vim.fn.setbufvar(bufnr, "&buflisted", true)
      end
    end
  end)

  utils.create_path(cfg.save_dir)
  if tmp_config.load_breakpoints_event ~= nil then
    local aug = vim.api.nvim_create_augroup("persistent-breakpoints-load-breakpoint", {
      clear = true,
    })
    vim.api.nvim_create_autocmd(
      tmp_config.load_breakpoints_event,
      { callback = require("persistent-breakpoints.api").load_breakpoints, group = aug }
    )
    vim.api.nvim_create_autocmd(
      { "DirChanged" },
      { callback = require("persistent-breakpoints.api").reload_breakpoints, group = aug }
    )
  end
end

return M
