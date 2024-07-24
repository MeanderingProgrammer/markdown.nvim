local logger = require('render-markdown.logger')
local state = require('render-markdown.state')
local ts = require('render-markdown.ts')

---@class render.md.LatexCache
---@field expressions table<string, string[]>

---@type render.md.LatexCache
local cache = {
    expressions = {},
}

---@class render.md.handler.Latex: render.md.Handler
local M = {}

---@param root TSNode
---@param buf integer
---@return render.md.Mark[]
M.parse = function(root, buf)
    local latex = state.config.latex
    if not latex.enabled then
        return {}
    end
    if vim.fn.executable(latex.converter) ~= 1 then
        logger.debug('Executable not found: ' .. latex.converter)
        return {}
    end
    if latex.lines_above < 0 then
        logger.debug('lines_above must be greater than or equal to 0')
        return {}
    end
    if latex.lines_below < 0 then
        logger.debug('lines_below must be greater than or equal to 0')
        return {}
    end

    local info = ts.info(root, buf)
    logger.debug_node_info('latex', info)

    local expressions = cache.expressions[info.text]
    if expressions == nil then
        local raw_expression = vim.fn.system(latex.converter, info.text)
        expressions = vim.split(raw_expression, '\n')
        table.remove(expressions, nil)

        for i=1, latex.lines_above do
            table.insert(expressions, 1, '')
        end

        for i=1, latex.lines_below do
            table.insert(expressions, '')
        end

        cache.expressions[info.text] = expressions
    end

    local latex_lines = vim.tbl_map(function(expression)
        return { { expression, latex.highlight } }
    end, expressions)

    ---@type render.md.Mark
    local latex_mark = {
        conceal = false,
        start_row = info.start_row,
        start_col = info.start_col,
        opts = {
            end_row = info.end_row,
            end_col = info.end_col,
            virt_lines = latex_lines,
            virt_lines_above = true,
        },
    }
    return { latex_mark }
end

return M
