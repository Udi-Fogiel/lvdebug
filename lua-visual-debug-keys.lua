local lvd = require('lua-visual-debug')
local params = lvd.params
local keyval = require('luakeyval')
local process_keys = keyval.process
local scan_bool = keyval.bool
local scan_string = token.scan_string
local scan_float = token.scan_float
local inner_keys = {
    hlist = {
        show = {scanner = scan_bool},
        color = {scanner = scan_string},
        width = {scanner = scan_float}
    },
    vlist = {
        show = {scanner = scan_bool},
        color = {scanner = scan_string},
        width = {scanner = scan_float}
    },
    rule = {
        show = {scanner = scan_bool},
        color = {scanner = scan_string},
        width = {scanner = scan_float}
    },
    disc = {
        show = {scanner = scan_bool},
        color = {scanner = scan_string},
        width = {scanner = scan_float}
    },
    glue = {
        show = {scanner = scan_bool},
    },
    kern = {
        show = {scanner = scan_bool},
        negativecolor = {scanner = scan_string},
        color = {scanner = scan_string},
        width = {scanner = scan_float}
    },
    penalty = {
        show = {scanner = scan_bool},
        colorfunc = {scanner = scan_string},
    },
    glyph = {
        show = {scanner = scan_bool},
        color = {scanner = scan_string},
        width = {scanner = scan_float},
        baseline = {scanner = scan_bool}
    },
}

local messages = {
    error1 = "lua-visual-debug: Wrong syntax in \\lvdset",
    value_forbidden = 'lua-visual-debug: The key "%s" does not accept a value',
    value_required = 'lua-visual-debug: The key "%s" requires a value',
}


local function set_params(key)
    local vals = process_keys(inner_keys[key],messages)
    for k,v in pairs(vals) do
        params[key][k] = v
    end
end

local function onlyglyphs()
    for _,v in pairs(params) do
        if v.show then 
            v.show = false
        end
    end
    params.glyph.show = true
end

local function set_penalty()
    local vals = process_keys(inner_keys.penalty,messages)
    if vals.show ~= nil then
        params.penalty.show = vals.show
    end
    if vals.colorfunc then
        local func, err = load("return " .. vals.colorfunc)
        if func then
            params.penalty.colorfunc = func()
        else
            texio.write_nl('log', "lua-visual-debug: error in colorfunc: " .. err)
        end
    end
end

local outer_keys = {
    hlist = {scanner = function() return true end, func = set_params},
    vlist = {scanner = function() return true end, func = set_params},
    rule = {scanner = function() return true end, func = set_params},
    disc = {scanner = function() return true end, func = set_params},
    glue = {scanner = function() return true end, func = set_params},
    kern = {scanner = function() return true end, func = set_params},
    penalty = {scanner = function() return true end, func = set_penalty},
    glyph = {scanner = function() return true end, func = set_params},
    opacity = {scanner = scan_string},
    onlyglyphs = {default = true, func = onlyglyphs}
}

do
  if token.is_defined('lvdset') then
      texio.write_nl('log', "lua-visual-debug: redefining \\lvdset")
  end
  local function_table = lua.get_functions_table()
  local luafnalloc = luatexbase and luatexbase.new_luafunction 
    and luatexbase.new_luafunction('lvdset') or #function_table + 1
  token.set_lua('lvdset', luafnalloc)
  function_table[luafnalloc] = function() 
      local vals = process_keys(outer_keys,messages)
      params.opacity = vals.opacity or params.opacity
  end
end
