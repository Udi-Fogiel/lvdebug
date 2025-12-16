-- luakeyval Version: 0.1, 2025-12-01

local put_next = token.unchecked_put_next
local get_next = token.get_next
local scan_toks = token.scan_toks
local scan_keyword = token.scan_keyword_cs

local texerror, utfchar = tex.error, utf8.char
local format = string.format

-- local relax = token.new(token.biggest_char() + 1)
local relax
do
-- initialization of the new primitives.
  local prefix = '@lua^key&val_' -- unlikely prefix...
  while token.is_defined(prefix .. 'relax') do
    prefix = prefix .. '@lua^key&val_'
  end
  tex.enableprimitives(prefix,{'relax'})
-- Now we create new tokens with the meaning of
-- the primitives.
  local tok = token.create(prefix .. 'relax')
  relax = token.new(tok.mode, tok.command)
end

local function check_delimiter(error1, error2, key)
    local tok = get_next()
    if tok.tok ~= relax.tok then
        local tok_name = tok.csname or utfchar(tok.mode)
        texerror(format(error1, key, tok_name),{format(error2, key, tok_name)})
        put_next({tok})
    end
end

local unpack = table.unpack
local function process_keys(keys, messages, order)
    assert(type(keys) == 'table')
    local matched, vals, curr_key = true, { }
    messages = messages or { }
    local value_forbidden = messages.value_forbidden
        or 'luakeyval: The key "%s" does not accept a value'
    local value_required = messages.value_required
        or 'luakeyval: The key "%s" requires a value'
    local error1 = messages.error1
        or 'luakeyval: Wrong syntax when processing keys'
    local error2 = messages.error2
        or 'luakeyval: The last scanned key was "%s".\nUnexpected token "%s" encountered.'
    local key_list = { }
    if order then
        for _, k in ipairs(order) do
            key_list[#key_list+1] = k
        end
    else
        for k in pairs(keys) do
            key_list[#key_list+1] = k
        end
    end
    local toks = scan_toks()
    toks[#toks+1] = relax
    put_next(toks)
    while matched do
        matched = false
        for _, key in ipairs(key_list) do
            local param = keys[key]
            if scan_keyword(key) then
                matched = true
                curr_key = key
                local args = param.args or { }
                local scanner = param.scanner
                local val
                if scan_keyword('=') then
                    if scanner then
                        val = scanner(unpack(args))
                    else
                        texerror(format(value_forbidden, key))
                    end
                else
                    val = param.default
                    if val == nil then 
                        texerror(format(value_required, key))
                    end
                end
                local func = param.func
                if func then func(key,val) end
                vals[key] = val
                break
            end
        end
    end
    check_delimiter(error1, error2, curr_key or '<none>')
    return vals
end

local function scan_choice(...)
    local choices = {...}
    for _, choice in ipairs(choices) do
        if scan_keyword(choice) then
            return choice
        end
    end
    return nil
end

local function scan_bool()
    if scan_keyword('true') then 
        return true
    elseif scan_keyword('false') then
        return false
    end
    return nil
end

return {
    process = process_keys,
    choices = scan_choice,
    bool = scan_bool,
}
