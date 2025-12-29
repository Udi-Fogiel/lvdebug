#!/usr/bin/env texlua

-- Identify the bundle and module
bundle = ""
module = "lua-visual-debug"

stdengine    = "luatex"
checkengines = {"luatex"}
checkruns = 1
sourcefiles = {"*.opm", "*.sty", "*.lua"}
installfiles = sourcefiles
auxfiles = {"*.aux", "*.lof", "*.lot", "*.toc", '*.ref'}
docfiledir = "./doc"
textfiles = {"*.md", "LICENSE"}
typesetexe = "lualatex"
typesetfiles = {"lvdebug-doc.tex"}
typesetdemofiles = {"sample.tex", "sample-plain.tex"}
docfiles = {"strut.png", "lvdebugdetail1-num.png"}
ctanzip = module
tdsroot = "luatex"
packtdszip = true
flatten = false

specialformats = specialformats or { }
specialformats.optex  = {luatex = {binary = "optex", format = ""}}
specialformats.plain  = {luatex = {binary = "luahbtex", format = ""}}
specialtypesetting = specialtypesetting or {}
specialtypesetting["sample-plain.tex"] = {cmd = "luatex -interaction=nonstopmode"}

tdslocations =
  {
    "tex/optex/" .. module .. "/*.opm",
    "tex/luatex/" .. module .. "/*.sty",
    "tex/luatex/" .. module .. "/*.lua",
  }

tagfiles = {"*.opm", "*.sty", "*.lua", "doc/lvdebug-doc.tex", "*.md"}
function update_tag(file,content,tagname,tagdate)
  if string.match(file, "%.opm$") then
    return string.gsub(content,
      "version {%d+%.%d+, %d%d%d%d%-%d%d%-%d%d",
      "version {" .. tagname .. ", " .. tagdate)
  elseif string.match(file, "%.lua$") then
    return string.gsub(content,
      "Version: V%d+%.%d+, %d%d%d%d%-%d%d%-%d%d",
      "Version: V" .. tagname .. ", " .. tagdate)
  elseif string.match(file, "%.sty$") then
    return string.gsub(content,
      "} %[%d%d%d%d%-%d%d%-%d%d v%d+%.%d+\n",
      "} [" .. tagdate .. " v" .. tagname .. "\n")
  elseif string.match(file, "%.md$") then
    return string.gsub(content,
      "Package version: %d%d%d%d%-%d%d%-%d%d v%d+%.%d+\n",
      "Package version: " .. tagdate .. " v" .. tagname .. "\n")
  elseif string.match(file, "%.tex$") then
    return string.gsub(content,
      "The lua-visual-debug package (V%d+%.%d+)",
      "The lua-visual-debug package (V" .. tagname .. ")")

  end
end

function pre_release()
    call({"."}, "tag")
    call({"."}, "ctan", {config = options['config']})
    run(".", "zip -d " .. module .. ".zip " .. module .. ".tds.zip")
    rm(".", "*.pdf")
end

target_list["prerelease"] = { func = pre_release, 
			desc = "update tags, generate pdfs, build zip for ctan"}
