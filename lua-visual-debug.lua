-- Copyright 2012-2025 Patrick Gundlach, patrick@gundla.ch
-- Copyright 2025 Udi Fogiel, udi@udifogiel.com
-- Public repository:
-- https://github.com/Udi-Fogiel/lvdebug (issues/pull requests,...) Version: V1.0, 2025-12-29
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


-- There are 65782 scaled points in a PDF point
-- Therefore we need to divide all TeX lengths by
-- this amount to get the PDF points.
local number_sp_in_a_pdf_point = tex.sp('1bp')


-- The idea is the following: at page shipout, all elements on a page are fixed.
-- TeX creates an intermediate data structure before putting that into the PDF
-- We can "intercept" that data structure and add pdf_literal (whatist) nodes,
-- that makes glues, kerns and other items visible by drawing a rule, rectangle
-- or other visual aids. This has no influence on typeset material, because
-- these pdf_literal instructions are only visible to the PDF file (PDF
-- renderer) and have no size themselves.

-- We recursively loop through the contents of boxes and look at the (linear)
-- list of items in that box. We start at the "shipout box".

-- The "algorithm" goes like this:
--
-- head = pointer_to_beginning_of_box_material
-- while head is not nil
--   if this_item_is_a_box
--     recurse_into_contents
--     draw a rectangle around the contents
--   elseif this_item_is_a_glue
--     draw a rule that has the length of that glue
--   elseif this_item_is_a_kern
--     draw a rectangle with width of that kern
--   ...
--   end
--   move pointer to the next item in the list
--   -- the pointer is "nil" if there is no next item
-- end

local HLIST = node.id("hlist")
local VLIST = node.id("vlist")
local RULE = node.id("rule")
local DIR  = node.id("dir")
local DISC = node.id("disc")
local GLUE = node.id("glue")
local KERN = node.id("kern")
local PENALTY = node.id("penalty")
local GLYPH = node.id("glyph")

local fmt = string.format
local floor = math.floor
local insert = table.insert
local table_remove = table.remove
local insert_after = node.insert_after
local insert_before = node.insert_before

local running_glue_dimen = -2^30

local params = {
    hlist = {show = true, color = "0.5 G", width = 0.1},
    vlist = {show = true, color = "0.1 G", width = 0.1},
    rule = {show = true, color = "1 0 0 RG", width = 0.4},
    disc = {show = true, color = "0 0 1 RG", width = 0.3},
    glue = {show = true},
    kern = {show = true, negativecolor = "1 0 0 rg", color = "1 1 0 rg", width = 1},
    penalty = {show = true, colorfunc = function(p) local color = "1 g" if p < 10000 then
        color = fmt("%d g", 1 - floor(p / 10000)) end return color end},
    glyph = {show = false, color = "1 0 0 RG", width = 0.1, baseline = true},
    opacity = ""
}

-- Helpers

local function math_round(num, idp)
  if idp and idp>0 then
    local mult = 10^idp
    return floor(num * mult + 0.5) / mult
  end
  return floor(num + 0.5)
end

local function new_literal(data)
  local n = node.new("whatsit", "pdf_literal")
  n.data = data
  return n
end

local function insert_literal_before(list, target, data)
  return insert_before(list, target, new_literal(data))
end

local function to_bp(sp)
  return math_round(sp / number_sp_in_a_pdf_point, 2)
end

local function pdf_rect(opacity, color, lw, x, y, w, h, mode)
  -- mode: "s" = stroke, "B" = fill+stroke
  return fmt("q %s %s %g w %g %g %g %g re %s Q",
    opacity, color, lw, x, y, w, h, mode or "s")
end

local show_page_elements

local function show_page_elements(parent)
  
  local dirstack = {}
  local currdir = parent.direction
  local head = parent.list
  
  while head do

    if head.id == HLIST or head.id == VLIST then
      local boxtype = node.type(head.id)
      local p = params[boxtype]
      show_page_elements(head)
      if p.show then
        local wd = to_bp(head.width)
        local dp = to_bp(head.depth)
        local ht = to_bp(head.height + head.depth)
        local f  = 1 - 2 * head.direction
        local x, y, w, h
        if head.id == HLIST then
          x, y, w, h = 0, -dp, f * wd, ht
        else
          x, y, w, h = 0,   0, f * wd, -ht
        end
        head.list = insert_before(head.list, head.list,
          new_literal(fmt("q %s %s %g w %g %g %g %g re s Q",
            params.opacity, p.color, p.width, x, y, w, h)))
      end
    
    elseif head.id == RULE and params.rule.show then
      if head.width ~= running_glue_dimen
       and head.height ~= running_glue_dimen
       and head.depth ~= running_glue_dimen then
        local dp = to_bp(head.depth)
        local ht = to_bp(head.height)
        parent.list = insert_literal_before(parent.list, head,
          fmt("q %s %s %g w 0 %g m 0 %g l S Q", params.opacity,
            params.rule.color, params.rule.width, -dp, ht))
      end
    
    elseif head.id == DISC and params.disc.show then
      parent.list = insert_literal_before(parent.list, head,
        fmt("q %s %s %g w 0 -1 m 0 0 l S Q",
          params.opacity, params.disc.color, params.disc.width))
    
    elseif head.id == DIR then
      if head.subtype == 0 then
          insert(dirstack,currdir)
          currdir = head.direction
      elseif #dirstack > 0 then
          currdir = table_remove(dirstack)
      end

    elseif head.id == GLUE and params.glue.show then
      local spec = head.spec or head
      local wd = spec.width
      local color = "0.5 G"
      if parent.glue_sign == 1 and parent.glue_order == spec.stretch_order then
        wd = wd + parent.glue_set * spec.stretch
        color = "0 0 1 RG"
      elseif parent.glue_sign == 2 and parent.glue_order == spec.shrink_order then
        wd = wd - parent.glue_set * spec.shrink
        color = "1 0 1 RG"
      end
      local wd_bp = to_bp(wd)
      local data
      if parent.id == HLIST then
        data = fmt("q %s [0.2] 0 d 0.5 w 0 0 m %g 0 l S Q", color, wd_bp * (1 - 2 * currdir))
      else
        data = fmt("q 0.1 G 0.1 w -0.5 0 m 0.5 0 l -0.5 %g m 0.5 %g l S [0.2] 0 d 0.5 w 0.25 0 m 0.25 %g l S Q",
          -wd_bp, -wd_bp, -wd_bp)
      end
      parent.list = insert_literal_before(parent.list, head, data)
      
    elseif head.id == KERN and params.kern.show then
      local color = head.kern < 0 and params.kern.negativecolor or params.kern.color
      local k = to_bp(head.kern)
      local f = 1 - 2 * currdir
      local w, h
      if parent.id == HLIST then
        w, h = f * k, params.kern.width
      else
        w, h = f * params.kern.width, -k
      end
      parent.list = insert_literal_before(parent.list, head,
        fmt("q %s %s 0 w 0 0 %g %g re B Q", params.opacity, color, w, h))

    elseif head.id == PENALTY and params.penalty.show then
      parent.list = insert_literal_before(parent.list, head,
        fmt("q %s 0 w 0 0 %g 1 re B Q",
          params.penalty.colorfunc(head.penalty), 1 - 2 * currdir))    
    
    elseif head.id == GLYPH and params.glyph.show then
      local p = params.glyph
      local f = 1 - 2 * currdir
      local wd = -to_bp(head.width)
      local ht =  to_bp(head.height + head.depth)
      local dp =  to_bp(head.depth)
      local baseline = (head.depth ~= 0 and p.baseline)
        and fmt("%g %g m %g %g l", 0, 0, f * wd, 0) or ""
      parent.list, head = insert_after(parent.list, head,
        new_literal(fmt("q %s %s %g w %s %g %g %g %g re s Q",
          params.opacity, p.color, p.width, baseline, 0, -dp, f * wd, ht)))
    end
    
    head = head.next
  end
  return true
end

return {
  show_page_elements = show_page_elements,
  params = params
}