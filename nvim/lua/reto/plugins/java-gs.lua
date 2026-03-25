return {
    dir = vim.fn.stdpath("config") .. "/lua/java-gs",
    ft = "java",
    config = function()
        require("java-gs").setup()
    end,
}
