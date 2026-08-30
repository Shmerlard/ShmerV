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
