return {
    {
        "kkoomen/vim-doge",
        build = ":call doge#install()", -- Runs post-install to set up binaries/docs
        config = function()
            -- Forward jump: Ctrl + k
            vim.keymap.set('n', '<C-l>', '<Plug>(doge-comment-jump-forward)')
            vim.keymap.set('i', '<C-l>', '<Plug>(doge-comment-jump-forward)')
            vim.keymap.set('x', '<C-l>', '<Plug>(doge-comment-jump-forward)')

            -- Backward jump: Ctrl + j
            vim.keymap.set('n', '<C-j>', '<Plug>(doge-comment-jump-backward)')
            vim.keymap.set('i', '<C-j>', '<Plug>(doge-comment-jump-backward)')
            vim.keymap.set('x', '<C-j>', '<Plug>(doge-comment-jump-backward)')
        end,
    }
}
