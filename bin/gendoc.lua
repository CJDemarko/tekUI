#!/usr/bin/env lua

--
--	tek/app/gendoc.lua - Document generator
--	Written by Timm S. Mueller <tmueller at schulze-mueller.de>
--	See copyright notice in COPYRIGHT
--
--	Markers the source code parser reacts on are:
--
--	module("foo.bar.class", foo.bar.superclass)
--	[module directive to extract a module's class and superclass]
--
--	[beginning of a comment block]
--	---------------------------------------...
--	--
--	--	[comment block]
--	--
--	--	DEFINITION:: [definition]
--	--	ret1, ... = funcname(arg1, ...): [a function with results]
--	--	funcname(arg1, arg2, ...): [a function without results]
--	--
--	---------------------------------------...
--	[end of a comment block]
--

local db = require "tek.lib.debug"
local Markup = require "tek.class.markup"
local Args = require "tek.lib.args"

local concat = table.concat
local insert = table.insert
local remove = table.remove
local sort = table.sort

local RULE = "-------------------------------------------------------------------------------"
local PAGE = "==============================================================================="

-------------------------------------------------------------------------------
--	aquire a filesystem abstraction:
-------------------------------------------------------------------------------

local fs = { }
do
	local posix, lfs
	pcall(function() posix = require "tek.os.posix" end)
	if posix then
		function fs.readdir(path)
			assert(path)
			local d, msg = posix.opendir(path)
			assert(d, msg and "Cannot open directory '" .. path .. "' : " ..
				msg)
			return function()
				local e
				repeat
					e = d:read()
				until e ~= "." and e ~= ".."
				return e
			end
		end
		fs.stat = posix.stat
	else
		lfs = require "lfs"
		function fs.readdir(path)
			assert(path)
			local dir = lfs.dir(path)
			return function()
				local e
				repeat
					e = dir()
				until e ~= "." and e ~= ".."
				return e
			end
		end
		fs.stat = lfs.attributes
	end
end

-------------------------------------------------------------------------------
--	recursedir: recurse directory, invoke func(fullname, path, name) for
--	every entry whose filemode matches mode ("directory" or "file") and
--	its name matches pattern. mode and pattern may be nil each.
-------------------------------------------------------------------------------

function recursedir(func, path, mode, pattern)
	if fs.stat(path, "mode") == "directory" then
		for name in fs.readdir(path) do
			local fullname = path .. "/" .. name
			if (not mode or fs.stat(fullname, "mode") == mode) and
				(not pattern or name:match(pattern)) then
				func(fullname, path, name)
			end
			recursedir(func, fullname, mode, pattern)
		end
	end
end

-------------------------------------------------------------------------------
--	insertclass: assembles a class tree by feeding it pairs of
--	superclass, class pairs.
-------------------------------------------------------------------------------

function insertclass(tree, super, class, in_tree)
	local found
	if tree[super] then
		if not tree[super][class] then
			tree[super][class] = { }
		end
		found = tree[super]
	end
	if not found then
		for key, sub in pairs(tree) do
			if type(sub) == "table" then
				found = insertclass(sub, super, class, true)
				if found then break end
			end
		end
	end
	if not found and not in_tree then
		tree[super] = { [class] = { } }
		found = tree[super]
	end
	if found then
		if tree[class] then
			found[class] = tree[class]
			tree[class] = nil
		end
	end
	return found
end

-------------------------------------------------------------------------------
--	processfile: process a single Lua source file
-------------------------------------------------------------------------------

local function trimblock(tab)
	while tab[#tab]:match("^%s*$") do
		remove(tab)
	end
	return tab
end

function processfile(state, fname)

	fname = fname:match("^%./(.*)$") or fname

	local f = io.open(fname)

	local classname
	local superclass
	local shortname
	local version

	local documentation = { }
	local ret, docfunc, args
	local parser = 0 -- 0 = normal, 1 = finddoc, 2 = funcdoc

	local blocks = { }
	local block
	local function addblock(text, ...)
		insert(block, text:format(...))
	end

	for line in f:lines() do

		while true do

			-- collect documentation:

			if parser == 0 then
				if line:match("^%-%-%-%-%-%-%-%-") then
					parser = 1
					break
				end
			elseif parser == 1 then
				-- match DEFINITION::
				local def = line:match("^%-%-%s(%s*%u+::)%s*$")
				if def then
					block = { }
					parser = 2
					addblock("%s\n", def)
					break
				end
				-- match function, e.g. result = foo(bar):
				local doc
				results, docfunc, args, extra, doc = line:match(
					"^%-%-%s+(%w[%w%d%s%-.,_%[%]]-)%s*=%s*(%w[%w%d%s%-,_:.]*)%s*%(([%w%d%s%-.,_%[%]]*)%)%s*([^:]*)%s*:%s?(.*)%s*$")
				if not results then
					docfunc, args, extra, doc = line:match(
					"^%-%-%s+(%w[%w%d%s%-.,_;:]*)%s*%(([%w%d%s%-.,_%[%]]*)%)%s*([^:]*)%s*:%s?(.*)%s*$")
				end
				if docfunc and args then
					local title
					extra = extra ~= "" and (" " .. extra) or extra
					if results then
						title = ("%s = %s(%s)%s"):format(results, docfunc,
							args, extra)
					else
						title = ("%s(%s)%s"):format(docfunc, args, extra)
					end
					docfunc = docfunc:match("[^.:]+[.:]([^.:]+)") or docfunc
					block = { }
					parser = 2
					addblock(RULE .. "\n\n")
					addblock("==={ %s : %s }===\n\n",
						(shortname or classname or fname) .. ":" .. docfunc,
							title)
					if doc and doc ~= "" then
						addblock("%s\n", doc)
					end

					break
				elseif line:match("^%-%-") then
					parser = 1
					break
				else
					parser = 0
				end
			elseif parser == 2 then
				-- in comment block:
				if line:match("^%-%-%-%-%-%-%-%-") then
					block = trimblock(block)
					insert(block, 1, "\n")
					block = concat(block)
					if docfunc then
						-- this is a function, collect for sorting:
						insert(blocks, docfunc)
						blocks[docfunc] = block
					else
						-- other documentation is dumped in natural order:
						insert(documentation, block)
					end
					parser = 0
					break
				end

				local doc = line:match("^%-%-%s(.*)%s*$")
				if doc then
					addblock("%s\n", doc)
				elseif line:match("^%-%-%s*$") then
					addblock("\n")
				end

				break
			end

			if not classname then
				local p, n, b =
					line:match(
						'^%s*module%s*%(%s*"([%w.]*)%.([%w]+)"%s*,%s*([%w.]+)%s*%)')
				if p and n then
					classname = p .. "." .. n
					shortname = n
					superclass = b
				else
					local p, n = line:match('^%s*module%s*"([%w.]*)%.([%w]+)"')
					if p and n then
						classname = p .. "." .. n
						shortname = n
					end
				end
			else
				line = line:match("^(.*)%-%-.*$") or line
				local n = line:match("^%s*local%s+(%w+)%s*=%s*_M%s*$")
				if n then
					shortname = n
				end
				if not version then
					version = line:match('^%s*_VERSION%s*=%s*"(.*)"%s*$')
				end
			end

			break
		end

	end

	f:close()

	if version then
		version = version:match("^[%w%s]+%s+(%d+[%d.]*%.%d+)%s*$")
		if not version then
			io.stderr:write(
				("%s: _VERSION malformatted\n"):format(classname or fname))
		end
	end

	local record = {
		ClassName = classname,
		ShortName = shortname,
		SuperClass = superclass,
		FileName = fname,
		Version = version,
	}

	-- sort functions alphabetically, add at end:
	sort(blocks)
	for _, funcname in ipairs(blocks) do
		insert(documentation, blocks[funcname])
	end
	
	if classname then
		local doc
		if #documentation > 0 then
			insert(documentation, 1,
				("\n==( %s : %s %s )==\n"):format(classname,
					shortname, version and ("(v" .. version .. ")") or "",
						classname))
			insert(documentation, 1, "\n" .. PAGE .. "\n")
			doc = concat(documentation)
			
			insert(state.documents, classname:lower())
			state.documents[classname:lower()] = doc
			
			record.Documentation = doc
		end

		if superclass then
			local node = insertclass(state.index, superclass, classname)
			setmetatable(node[classname], record)
		else
			state.basecandidates[classname] = record
		end

	else
		if #documentation > 0 then
			insert(documentation, 1,
				("\n==( %s %s )==\n"):format(fname, version and ("(v" ..
					version .. ")") or ""))
			insert(documentation, 1, "\n" .. RULE .. "\n")
			local doc = concat(documentation)
			
			insert(state.documents, fname:lower())
			state.documents[fname:lower()] = doc
			
			record.Documentation = doc
			insert(state.miscindex, record)
		end
	end

end

-------------------------------------------------------------------------------
--	dumpclasstree: dump class tree with methods and members
-------------------------------------------------------------------------------

local function sortfunc(a, b)
	if a.type == b.type then
		return a.name < b.name
	end
	return a.type == "."
end

function dumpclasstree(state, tab, indent)

	indent = indent or 1
	local is = ("\t"):rep(indent)
	local set = { }

	for key, val in pairs(tab) do
		local data = getmetatable(val)
		insert(set, { cmp = tostring(key):lower(),
			name = data.ShortName or data.ClassName, sub = val,
			data = data, path = data.ClassName })
	end

	sort(set, function(a, b) return a.cmp < b.cmp end)

	for i, rec in ipairs(set) do

		local name, sub, data, path = rec.name, rec.sub, rec.data, rec.path

		local head
		if data.Unknown or not data.Documentation then
			if state.showempty then
				head = ("%s* %s"):format(is, name)
			end
		else
			head = ("%s* [[#%s : %s]]"):format(is, path, name)
		end

		insert(state.classdiagram, head)

		dumpclasstree(state, sub, indent + 1)
	end
end

-------------------------------------------------------------------------------
--	indextree: inserts a 'Parent' key in tree nodes' metatables
-------------------------------------------------------------------------------

function indextree(tab, parent)
	if parent then
		local data = getmetatable(tab)
		data.Parent = parent
	end
	for key, val in pairs(tab) do
		indextree(val, tab, lastname)
	end
end

-------------------------------------------------------------------------------
--	processtree: recurse filesystem, build tree, dump tree and documentation
-------------------------------------------------------------------------------

function processtree(state)

	state = state or { }
	state.from = state.from or { }
	state.index = state.index or { }
	state.basecandidates = state.basecandidates or { }
	state.documentation = { }
	state.miscindex = state.miscindex or { }
	state.documents = { }

	state.showtree = true

	local mode = fs.stat(state.from, "mode")
	if mode == "directory" then
		recursedir(function(filename)
			processfile(state, filename)
		end, state.from, "file", 	"^.*%.lua$")
	elseif mode == "file" then
		processfile(state, state.from)
	end

	if state.showtree then

		-- Class index:

		state.classdiagram = { }
		if state.heading then
			insert(state.classdiagram, RULE .. "\n")
		end
		insert(state.classdiagram, "==( Class Overview )==\n")

		for key, val in pairs(state.index) do
			local t = { key = val }
			local candidate = state.basecandidates[key]
			if candidate then
				setmetatable(val, candidate)
				state.basecandidates[key] = nil
			else
				setmetatable(val, { Methods = { }, Members = { },
					ClassName = '"' .. key .. '" [Superclass unknown]',
					Unknown = true })
			end
			indextree(t)
			dumpclasstree(state, t)
		end

		-- Library index:

		local numlibs = 0
		for key, val in pairs(state.basecandidates) do
			numlibs = numlibs + 1
		end
		if numlibs > 0 then
			insert(state.classdiagram, "\n== Modules ==\n")
			local set = { }
			for key, data in pairs(state.basecandidates) do
				insert(set, { cmp = tostring(key):lower(),
					version = data.Version,
					doc = data.Documentation,
					name = data.ShortName or data.ClassName,
					path = data.ClassName })
			end
			if #set > 0 then
				sort(set, function(a, b) return a.cmp < b.cmp end)
				for i, rec in pairs(set) do
					local head
					if rec.doc then
						head = ("\t* [[#%s : %s]]"):format(rec.path, rec.name)
					else
						head = ("\t* %s"):format(rec.name)
					end
					insert(state.classdiagram, head)
				end
			end
		end

		-- Misc. index:

		if #state.miscindex > 0 then
			insert(state.classdiagram, "\n== Miscellaneous ==\n")
			local set = { }
			for key, data in ipairs(state.miscindex) do
				insert(set, { cmp = tostring(key):lower(),
					version = data.Version,
					doc = data.Documentation,
					name = data.ShortName or data.ClassName or data.FileName,
					path = data.FileName })
			end
			sort(set, function(a, b) return a.cmp < b.cmp end)
			for i, rec in ipairs(set) do
				local head
				if rec.doc then
					head = ("\t* [[#%s : %s]]"):format(rec.path, rec.name)
				else
					head = ("\t* %s"):format(rec.name)
				end
				insert(state.classdiagram, head)
			end
		end

		insert(state.documentation, 1,
			concat(state.classdiagram, "\n") .. "\n")
	end

	-- sort document nodes alphabetically:
	sort(state.documents)
	for _, docname in ipairs(state.documents) do
		insert(state.documentation, state.documents[docname])
	end

	insert(state.documentation, "\n" .. PAGE .. "\n\n")
	insert(state.documentation, "Document generated on " .. os.date() .. "\n")

	if state.heading then
		insert(state.documentation, 1, "\n= " .. state.heading .. " =\n\n")
	end

end

-------------------------------------------------------------------------------
--	Markup specialization:
-------------------------------------------------------------------------------

local DocMarkup = Markup:newClass()

function DocMarkup:link(link)
	local funclink = link:match("^(.*%(%))$")
	if funclink then
		-- function links uniformly use colons; replace dots:
		link = funclink:gsub("%.", ":")
	end
	
	local func = link:match("^(.*)%(%)$")
	if func and self.refdoc then
		return ('<a href="%s#%s"><code>'):format(self.refdoc, func), 
			'</code></a>'
	end
	
	return Markup.link(self, link)
end

-------------------------------------------------------------------------------
--	main
-------------------------------------------------------------------------------

local template = "-f=FROM/A,-p=PLAIN/S,-i=IINDENT/N/K,-h=HELP/S," ..
	"-e=EMPTY/S,--heading/K,--header/K,--author/K,--created/K,--adddate/S," ..
	"-r=REFDOC/K,-n=NAME/F"

local args = Args.read(template, arg)

if not args or args["-h"] then

	print("Lua documentation generator")
	print("Usage: gendoc.lua [directory or filename] [options]")
	print("Available options:")
	print("  -h=HELP/S      this help")
	print("  -i=IINDENT/N/K indent character code in input [default 9]")
	print("  -p=PLAIN/S     generate formatted plain text instead of HTML")
	print("  -e=EMPTY/S     also show empty (undocumented) modules in index")
	print("  --heading/K    single-line document heading")
	print("  --header/K     read a header from the specified file")
	print("  --author/K     document author (HTML generator metadata)")
	print("  --created/K    creation date (HTML generator metadata)")
	print("  --adddate/S    add creation date (HTML generator metadata)")
	print("  -r=REFDOC/K    document implicitely referenced by functions")
	print("  -n=NAME/F      document name (rest of arguments will be used)")
	print("If a path is specified, it is scanned for files with the extension")
	print(".lua. From these files, a HTML document is generated containing a")
	print("class tree, library index and function reference from specially")
	print("designed source code comments. The result can be dumped in the")
	print("same plain text format if the -p option is given. If a file is")
	print("specified instead of a directory, it is interpreted as formatted")
	print("plain text and converted to HTML.")

else

	local state = 
	{
		from = args["-f"], 
		plain = args["-p"],
		docname = args["-n"], 
		heading = args["--heading"],
		showempty = args["-e"]
	}

	state.textdoc = ""
	
	state.created = args["--created"]
	if args["--adddate"] then
		state.created = os.date("%d-%b-%Y")
	end

	if args["--header"] then
		state.textdoc = io.open(args["--header"]):read("*a")
	end
	
	if args["-f"] and fs.stat(args["-f"], "mode") == "file" then
		-- read existing text file with markup:
		state.textdoc = state.textdoc .. io.open(args["-f"]):read("*a")
	else
		-- scan filesystem:
		processtree(state)
		-- render documentation:
		state.textdoc = state.textdoc .. concat(state.documentation)
	end

	if state.plain then
		print(state.textdoc)
	else
		DocMarkup:new 
		{ 
			input = state.textdoc, 
			docname = args["-n"],
			refdoc = args["-r"] or false,
			author = args["--author"],
			created = state.created,
			indentchar = string.char(args["-i"] or 9) 
		}:run()
	end

end
