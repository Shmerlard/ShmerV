vim.opt.autoread = true

local external_change_group = vim.api.nvim_create_augroup("ShmerVExternalChanges", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group = external_change_group,
    callback = function()
        if vim.fn.getcmdwintype() == "" then
            vim.cmd("checktime")
        end
    end,
    desc = "Reload files changed outside Neovim",
})

vim.keymap.set("n", "<leader>lp", function()
    vim.cmd("silent update")

    vim.system({ "just", "format" }, {
        cwd = "/home/elad/Projects/ShmerV",
        text = true,
    }, function(result)
        vim.schedule(function()
            vim.cmd("checktime")

            if result.code == 0 then
                vim.notify("Formatting complete")
            else
                vim.notify(result.stderr, vim.log.levels.ERROR)
            end
        end)
    end)
end, { desc = "Format ShmerV" })
