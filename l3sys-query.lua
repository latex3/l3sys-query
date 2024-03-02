#!/usr/bin/env texlua

--[[

File l3sys-query.lua Copyright (C) 2024 The LaTeX Project

-----------------------------------------------------------------------

The development version of the bundle can be found at

   https://github.com/latex3/lsys-query

for those people who are interested.

--]]

-- Local copies of globals used here
local lfs        = lfs
local currentdir = lfs.currentdir

local string = string
local match  = string.match
local sub    = string.sub

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

-- A simple rename
local function pwd()
  return currentdir()
end
