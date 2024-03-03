#!/usr/bin/env texlua

--[[

File l3sys-query.lua Copyright (C) 2024 The LaTeX Project

-----------------------------------------------------------------------

The development version of the bundle can be found at

   https://github.com/latex3/lsys-query

for those people who are interested.

--]]

--
-- Details of the script itself, etc.
--
local copyright = "Copyright (C) 2024 The LaTeX Project\n"
local release_date = "2024-03-03"
local script_desc = "System queries for LaTeX using Lua\n"
local script_name = "l3sys-query"

--
-- Setup for the CLI: commands and options
--
local cmd_list =
  {
  }
local option_list =
  {
    help =
      {
        desc  = "Prints this message and exits",
        short = "h",
        type  = "boolean"
      },
    version =
      {
        desc = "Prints version information and exits",
        short = "v",
        type  = "boolean"
      }
  }

--
-- Local copies of globals used here
--
local io     = io
local stderr = io.stderr

local lfs        = lfs
local currentdir = lfs.currentdir
local dir        = lfs.dir

local string = string
local find   = string.find
local gmatch = string.gmatch
local match  = string.match
local rep    = string.rep
local sub    = string.sub

local table  = table
local concat = table.concat
local insert = table.insert
local sort   = table.sort

--
-- Support functions and data
--

-- Convert a file glob into a pattern for use by e.g. string.gub
-- Based on https://github.com/davidm/lua-glob-pattern
-- Simplified substantially: "[...]" syntax not supported as is not
-- required by the file patterns used by the team. Also note style
-- changes to match coding approach in rest of this file.
--
-- License for original globtopattern
--[[

   (c) 2008-2011 David Manura.  Licensed under the same terms as Lua (MIT).

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
  (end license)

--]]
local function glob_to_pattern(glob)

  local pattern = "^" -- pattern being built
  local i = 0 -- index in glob
  local char -- char at index i in glob
  
  -- escape pattern char
  local function escape(char)
    return match(char,"^%w$") and char or "%" .. char
  end
  
  -- Convert tokens.
  while true do
    i = i + 1
    char = sub(glob,i,i)
    if char == "" then
      pattern = pattern .. "$"
      break
    elseif char == "?" then
      pattern = pattern .. "."
    elseif char == "*" then
      pattern = pattern .. ".*"
    elseif char == "[" then -- ]
      -- Ignored
      print("[...] syntax not supported in globs!")
    elseif char == "\\" then
      i = i + 1
      char = sub(glob,i,i)
      if char == "" then
        pattern = pattern .. "\\$"
        break
      end
      pattern = pattern .. escape(char)
    else
      pattern = pattern .. escape(char)
    end
  end
  return pattern
end

-- Initial data for the command line parser
local cmd = "help"
local options = {}
local spec = ""

do
  -- Turn long/short options into two lookup tables
  local long_options = {}
  local short_options = {}
  for k,v in pairs(option_list) do
    if v.short then
      short_options[v.short] = k
    end
    long_options[k] = k
  end

  -- Minor speed-up
  local arg = arg

  -- arg[1] is a special case: must be a command or a very limited
  -- subset (--help|-h or --version|-v)
  local a = arg[1]
  if a then
    -- No options are allowed in position 1, so filter those out
    if a == "--version" or a == "-v" then
      cmd = "version"
    elseif not match(a,"^%-") then
      cmd = a
    end
  end

  -- Stop here if help or version is required
  if cmd == "help" or cmd == "version" then
    return
  end

  -- An auxiliary to grab all file names into a string:
  -- this reflects the fact that the use case for l3sys-query doesn't
  -- allow quoting spaces
  local function tidy(num)
    local t = {}
    for i = num,#arg do
      insert(t,arg[i])
    end
    return concat(t," ")
  end

  -- Examine all other arguments
  -- Use a while loop rather than for as this makes it easier
  -- to grab arg for optionals where appropriate
  local i = 2
  while i <= #arg do
    local a = arg[i]
    -- Terminate search for options
    if a == "--" then
      spec = tidy(i + 1)
      return
    end

    -- Look for optionals
    local opt
    local optarg
    local opts
    -- Look for and option and get it into a variable
    if match(a,"^%-") then
      if match(a,"^%-%-") then
        opts = long_options
        local pos = find(a,"=")
        if pos then
          opt = sub(a,3,pos - 1)
          optarg = sub(a,pos + 1)
        else
          opt = sub(a,3)
        end
      else
        opts = short_options
        opt = sub(a,2,2)
        -- Only set optarg if it is there
        if #a > 2 then
          optarg = sub(a,3)
        end
      end

      -- Now check that the option is valid and sort out the argument
      -- if required
      local optname = opts[opt]
      if optname then
        -- Tidy up arguments
        if option_list[optname].type == "boolean" then
          if optarg then
            local opt = "-" .. (match(a,"^%-%-") and "-" or "") .. opt
            stderr:write("Value not allowed for option " .. opt .. "\n")
            cmd = "help"
            return
          end
        else
          if not optarg then
            optarg = arg[i + 1]
            if not optarg then
              stderr:write("Missing value for option " .. a .. "\n")
              cmd = "help"
              return
            end
            i = i + 1
          end
        end
      else
        stderr:write("Unknown option " .. a .. "\n")
        cmd = "help"
        return
      end

      -- Store the result
      if optarg then
        if option_list[optname].type == "string" then
          options[optname] = optarg
        else
          local opts = options[optname] or {}
          for hit in gmatch(optarg,"([^,%s]+)") do
            insert(opts,hit)
          end
          options[optname] = opts
        end
      else
        options[optname] = true
      end
      i = i + 1
    end

    -- Collect up the remaining arguments
    if not opt then
      spec = tidy(i)
      break
    end
  end
end

--
-- The functions for commands
--

local function help()
  -- Find the longest entry to pad
  local function format_list(list)
    local longest = 0
    for k,_ in pairs(list) do
      if k:len() > longest then
        longest = k:len()
      end
    end
    -- Sort the list
    local t = {}
    for k,_ in pairs(list) do
      insert(t,k)
    end
    sort(t)
    return t,longest
  end

  -- 'Header' of fixed info
  print("Usage: " .. script_name .. " <cmd> [<options>] [<spec>]\n")
  print("Valid targets are:")

  -- Sort the commands, pad the descriptions, print
  local t,longest = format_list(cmd_list)
  for _,k in ipairs(t) do
    local cmd = cmd_list[k]
    local filler = rep(" ",longest - k:len() + 1)
    if cmd.desc then
      print("   " .. k .. filler .. cmd.desc)
    end
  end

  -- Same for the options
  print("\nValid options are:")
  t,longest = format_list(option_list)
  for _,k in ipairs(t) do
    local opt = option_list[k]
    local filler = rep(" ",longest - k:len() + 1)
    if opt.desc then
      if opt.short then
        print("   --" .. k .. "|-" .. opt.short .. filler .. opt.desc)
      else
        print("   --" .. k .. "   " .. filler .. opt.desc)
      end
    end
  end
  
  -- Postamble
  print("\nFull manual available via 'texdoc " .. script_name .. "'\n.")
  print("Repository : https://github.com/latex3/" .. script_name)
  print("Bug tracker: https://github.com/latex3/" .. script_name .. "/issues")
  print("\n" .. copyright)
end

-- The aim here is to convert a user file specification (if given) into a 
-- Lua pattern, and then to do a listing.
local function ls(spec)
  local spec = spec or "*"
  -- On Windows, "texlua" will expand globs itself: this can be suppressed by
  -- surrounding with "'". Formally, this only needs one "'" at one end, but
  -- that seems extremely unlikely, so rather strip exactly one pair of
  -- surrounding "'". That means that "l3sys-query" can always be called with
  -- a glob argument surrounded by "'...'" and will work independent of
  -- platform.
  if match(spec,"^'") and match(spec,"'$") then
    spec = sub(spec,2,-2)
  end
  -- Look for absolute paths or any trying to leave the confines of the current
  -- directory: this is not supported.
  if match(spec,"%.%.") or 
     match(spec,"^/") or 
     match(spec,"^\\") or 
     match(spec,"[a-zA-Z]:") then
    return
  end
  -- Tidy up and convert to a pattern.
  if not path then
    path = "."
    glob = spec
  end
  local pattern = glob_to_pattern(glob)
  -- So that files have the appropriate partial path at the start in all cases,
  -- define a printing path that can always be used.
  local print_path = ""
  if path ~= "." then print_path = path .. "/" end
  -- Build a table of entries, excluding "." and "..", and return as a string
  -- with one entry per line.
  local t = {}
  for entry in dir(path) do
    if match(entry,pattern) and entry ~= "." and entry ~= ".." then
      insert(t,print_path .. entry)
    end
  end
  return concat(t,"\n")
end

-- A simple rename
local function pwd()
  return currentdir()
end

local function version()
  return "\n" .. script_name .. ": " .. script_desc .. "\nRelease " 
    .. release_date .. "\n" .. copyright
end
