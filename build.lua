-- Identify the bundle and module
module = "l3sys-query"

scriptfiles = {"l3sys-query.lua"}
scriptmanfiles = {module .. ".1"}
sourcefiles = scriptfiles
tagfiles = {"CHANGELOG.md", "README.md", "l3sys-query.lua", "l3sys-query-tool.tex"}
typesetfiles = {"l3sys-query-tool.tex"}
unpackfiles = {}

-- Auto-generate a .1 file from the help
function  docinit_hook()
  local find = string.find
  local insert = table.insert
  local open = io.open

  local f = open("README.md","rb")
  local readme = f:read("*all")
  local date_start,date_end = find(readme,"%d%d%d%d%p%d%d%p%d%d")

  local man_t = {}
  insert(man_t,'.TH ' .. string.upper(module) .. ' 1 "'
    .. readme:sub(date_start,date_end) .. '" "LaTeX"\n')
  insert(man_t,(".SH NAME\n" .. module .. "\n"))
  insert(man_t,(".SH SYNOPSIS\n" .. module .. " <cmd> [<options>] [<args>]\n"))
  insert(man_t,".SH DESCRIPTION")

  local _,desc_start = find(readme,"## Overview")
  local desc_end,_ = find(readme,"The supported")

  local overview = readme:sub(desc_start + 2,desc_end - 2):gsub("[`_]","")
  insert(man_t,overview)

  local cmd = "texlua ./" .. module .. ".lua --help"
  local f = assert(io.popen(cmd,"r"))
  local help_text = assert(f:read("*a"))
  f:close()

  insert(man_t,(help_text:gsub("Usage.*args>]\n\n","")
  :gsub("Valid <cmd>",".SH COMMANDS\nValid <cmd>")
  :gsub("Valid <options>",".SH OPTIONS\nValid <options>")
  :gsub("Full manual",'.SH "SEE ALSO"\nFull manual')
  :gsub("Bug tracker","\nBug tracker")
  :gsub("Copyright",".SH AUTHORS\nCopyright")))

  f = assert(open(module .. ".1","wb"))
  f:write((table.concat(man_t,"\n"):gsub("\n$","")))
  f:close()
  return 0
end

-- Detail how to set the version automatically
function update_tag(file,content,tagname,tagdate)
  local gsub = string.gsub
  local match = string.match

  local iso = "%d%d%d%d%-%d%d%-%d%d"
  local url = "https://github.com/latex3/l3sys-query/compare/"
  -- update copyright
  local year = os.date("%Y")
  local oldyear = math.tointeger(year - 1)
  if match(content,"%(C%)%s*" .. oldyear .. " The LaTeX Project") then
    content = gsub(content,
      "%(C%)%s*" .. oldyear .. " The LaTeX Project",
      "(C) " .. year .. " The LaTeX Project")
  elseif match(content,"%(C%)%s*%d%d%d%d%-" .. oldyear .. " The LaTeX Project") then
    content = gsub(content,
      "%(C%)%s*(%d%d%d%d%-)" .. oldyear .. " The LaTeX Project",
      "(C) %1" .. year .. " The LaTeX Project")
  end
  -- update release date
  if match(file, "%.md$") then
    if match(file,"CHANGELOG.md") then
      local previous = match(content,"compare/(" .. iso .. ")%.%.%.HEAD")
      if tagname == previous then return content end
      content = gsub(content,
        "## %[Unreleased%]",
        "## [Unreleased]\n\n## [" .. tagname .."]")
      return gsub(content,
        iso .. "%.%.%.HEAD",
        tagname .. "...HEAD\n[" .. tagname .. "]: " .. url .. previous
          .. "..." .. tagname)
    end
    return gsub(content,
      "\nRelease " .. iso     .. "\n",
      "\nRelease " .. tagname .. "\n")
  elseif string.match(file, "%.tex$") then
    return gsub(content,
      "Release " .. iso    ,
      "Release " .. tagname)
    elseif string.match(file, "%.lua$") then
      return gsub(content,
        'release_date = "' .. iso     .. '"',
        'release_date = "' .. tagname .. '"')
  end
  return content
end

function tag_hook(tagname)
  os.execute('git commit -a -m "Step release tag"')
end
