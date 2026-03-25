local M = {}

-- Parse a Java field declaration line
-- Handles: private String name; / private final int age = 0; / protected List<String> items;
local function parse_field(line)
    local trimmed = line:match("^%s*(.-)%s*$")

    -- Match: [modifiers] type name [= value];
    local pattern = "^(.-)%s+([%w<>%[%]?,_%s]+)%s+([%w_]+)%s*[=;]"
    local modifiers, type_, name = trimmed:match(pattern)

    if not name then return nil end

    -- Clean up type (remove trailing spaces from generics)
    type_ = type_:match("^%s*(.-)%s*$")

    -- Skip static fields by default (configurable)
    if modifiers and modifiers:find("static") and not M.config.include_static then
        return nil
    end

    return { modifiers = modifiers, type = type_, name = name }
end

-- Capitalize first letter
local function capitalize(str)
    return str:sub(1, 1):upper() .. str:sub(2)
end

-- Generate getter for a field
local function make_getter(field, indent)
    local cap = capitalize(field.name)
    local prefix = (field.type == "boolean" or field.type == "Boolean") and "is" or "get"
    local lines = {
        indent .. "public " .. field.type .. " " .. prefix .. cap .. "() {",
        indent .. M.config.indent .. "return this." .. field.name .. ";",
        indent .. "}",
    }
    return lines
end

-- Generate setter for a field
local function make_setter(field, indent)
    local cap = capitalize(field.name)
    local lines = {
        indent .. "public void set" .. cap .. "(" .. field.type .. " " .. field.name .. ") {",
        indent .. M.config.indent .. "this." .. field.name .. " = " .. field.name .. ";",
        indent .. "}",
    }
    return lines
end

-- Detect indentation of the class body
local function detect_indent(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for _, line in ipairs(lines) do
        local indent = line:match("^(%s+)%S")
        if indent then return indent end
    end
    return "    "
end

-- Find the closing brace of the class (last `}` in file)
local function find_class_end(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for i = #lines, 1, -1 do
        if lines[i]:match("^}") or lines[i]:match("^%s*}") then
            return i
        end
    end
    return #lines
end

-- Check if a method already exists in the buffer
local function method_exists(bufnr, method_name)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for _, line in ipairs(lines) do
        if line:find(method_name .. "%(") then
            return true
        end
    end
    return false
end

-- Main: generate getters/setters for selected lines or current line
function M.generate(opts)
    opts = opts or {}
    local bufnr = vim.api.nvim_get_current_buf()
    local mode = opts.mode or "both" -- "getter", "setter", "both"

    -- Get line range
    local start_line, end_line
    if opts.range then
        start_line = opts.range[1]
        end_line   = opts.range[2]
    else
        local cur = vim.api.nvim_win_get_cursor(0)
        start_line = cur[1]
        end_line   = cur[1]
    end

    local indent = detect_indent(bufnr)
    local insert_at = find_class_end(bufnr)

    local new_lines = { "" } -- blank line before methods
    local generated = 0

    local raw = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

    for _, line in ipairs(raw) do
        local field = parse_field(line)
        if field then
            local skip_setter = field.modifiers and field.modifiers:find("final")

            if mode == "getter" or mode == "both" then
                local getter_name = ((field.type == "boolean" or field.type == "Boolean") and "is" or "get")
                    .. capitalize(field.name)
                if not method_exists(bufnr, getter_name) then
                    vim.list_extend(new_lines, make_getter(field, indent))
                    new_lines[#new_lines + 1] = ""
                    generated = generated + 1
                else
                    vim.notify("[java-gs] " .. getter_name .. "() already exists — skipped", vim.log.levels.WARN)
                end
            end

            if (mode == "setter" or mode == "both") and not skip_setter then
                local setter_name = "set" .. capitalize(field.name)
                if not method_exists(bufnr, setter_name) then
                    vim.list_extend(new_lines, make_setter(field, indent))
                    new_lines[#new_lines + 1] = ""
                    generated = generated + 1
                else
                    vim.notify("[java-gs] " .. setter_name .. "() already exists — skipped", vim.log.levels.WARN)
                end
            end
        end
    end

    if generated == 0 then
        vim.notify("[java-gs] No fields found or all methods already exist.", vim.log.levels.INFO)
        return
    end

    -- Insert before the last closing brace
    vim.api.nvim_buf_set_lines(bufnr, insert_at - 1, insert_at - 1, false, new_lines)
    vim.notify("[java-gs] Generated " .. generated .. " method(s).", vim.log.levels.INFO)
end

-- Generate only getters
function M.generate_getters(opts)
    opts = opts or {}
    opts.mode = "getter"
    M.generate(opts)
end

-- Generate only setters
function M.generate_setters(opts)
    opts = opts or {}
    opts.mode = "setter"
    M.generate(opts)
end

-- Setup with user config
function M.setup(user_config)
    M.config = vim.tbl_deep_extend("force", {
        indent = "    ",          -- indentation inside methods
        include_static = false,   -- skip static fields
        keymap = {
            generate_both   = "<leader>jg",
            generate_getter = "<leader>jG",
            generate_setter = "<leader>jS",
        },
    }, user_config or {})

    -- Normal mode: operate on current line
    vim.keymap.set("n", M.config.keymap.generate_both, function()
        M.generate({ mode = "both" })
    end, { desc = "Java: generate getter + setter" })

    vim.keymap.set("n", M.config.keymap.generate_getter, function()
        M.generate({ mode = "getter" })
    end, { desc = "Java: generate getter" })

    vim.keymap.set("n", M.config.keymap.generate_setter, function()
        M.generate({ mode = "setter" })
    end, { desc = "Java: generate setter" })

    -- Visual mode: operate on selected lines
    vim.keymap.set("v", M.config.keymap.generate_both, function()
        local s = vim.fn.line("'<")
        local e = vim.fn.line("'>")
        M.generate({ mode = "both", range = { s, e } })
    end, { desc = "Java: generate getter + setter (visual)" })

    vim.keymap.set("v", M.config.keymap.generate_getter, function()
        local s = vim.fn.line("'<")
        local e = vim.fn.line("'>")
        M.generate({ mode = "getter", range = { s, e } })
    end, { desc = "Java: generate getter (visual)" })

    vim.keymap.set("v", M.config.keymap.generate_setter, function()
        local s = vim.fn.line("'<")
        local e = vim.fn.line("'>")
        M.generate({ mode = "setter", range = { s, e } })
    end, { desc = "Java: generate setter (visual)" })

    -- Register user commands
    vim.api.nvim_create_user_command("JavaGS",  function() M.generate({ mode = "both" })   end, { range = true, desc = "Generate getter + setter" })
    vim.api.nvim_create_user_command("JavaGet", function() M.generate({ mode = "getter" }) end, { range = true, desc = "Generate getter" })
    vim.api.nvim_create_user_command("JavaSet", function() M.generate({ mode = "setter" }) end, { range = true, desc = "Generate setter" })
end

return M
