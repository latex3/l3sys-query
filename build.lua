-- Identify the bundle and module
module = "l3sys-query"

scriptfiles = {"l3sys-query.lua"}
sourcefiles = scriptfiles
typesetfiles = {"l3sys-query.tex"}
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
  insert(man_t,(".SH SYNOPSIS\n Usage " .. module .. " <cmd> [<options>] [<args>]\n"))
  insert(man_t,".SH DESCRIPTION")

  local _,desc_start = find(readme,"## Overview")
  local desc_end,_ = find(readme,"The supported")

  local overview = readme:sub(desc_start + 2,desc_end - 2):gsub("[`_]","")
  insert(man_t,overview)

  local cmd = "./" .. module .. ".lua --help"
  local f = assert(io.popen(cmd,"r"))
  local help_text = assert(f:read("*a"))
  f:close()

  insert(man_t,(help_text:gsub("\nUsage.*args>]\n\n","")
  :gsub("Valid commands",".SH COMMANDS\nValid commands")
  :gsub("Valid options",".SH OPTIONS\nValid options")
  :gsub("Full manual",'.SH "SEE ALSO"\nFull manual')
  :gsub("Bug tracker","\nBug tracker")
  :gsub("Copyright",".SH AUTHORS\nCopyright")))

  f = assert(open(module .. ".1","wb"))
  f:write((table.concat(man_t,"\n"):gsub("\n$","")))
  f:close()
  return 0
end
