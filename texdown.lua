title = "Untitled"
author = "Unknown author"
documentclass = "report"

local filename
local includes = {{"graphicx"}}

--- Adds a package and optional arguments to
--  the generated document.
--  @package Name of package to include as a string
--  @arguments Arguments to package as a string
function include(package, arguments)
	table.insert(includes, {package,arguments})
end

local function parseArguments()
	if #arg ~= 1 then
		io.stderr:write("Invalid arguments.\n")
		io.stderr:write("Usage: texdown INPUTFILE\n")
		os.exit(1)
	end
	filename = arg[1]
end

--- Reads each line of given file into
--  a table of strings
--  @filename File to read
--	@return Table of strings
local function readFile(filename)
	local lines = {}
	for line in io.lines(filename) do
		table.insert(lines, line)
	end
	table.insert(lines, "")
	return lines
end

local function parseFile(lines)
	local inItemize = false
	local inEnumerate = false

	output = {}

	for lineno, line in ipairs(lines) do
		local parse = true

		-- Don't parse lines prepended with % signs
		if string.match(line, "^[ \t]*%%.*") then
			line = line:gsub("^[ \t]*%%[ \t]*(.*)", "%1")
			goto done
		end

		-- Execute lines prepended with $ signs
		if string.match(line, "^[ \t]*%$.*") then
			local code = string.match(line, "^[ \t]*%$(.*)", 1)
			local result = assert(loadstring(code))()
			if type(result) == "string" then
				line = result
			else
				goto skip
			end
		end

		-- Subsubsection header
		line = line:gsub("### (.*)", "\\subsubsection{%1}")
		-- Subsection header
		line = line:gsub("## (.*)", "\\subsection{%1}")
		-- Section header
		line = line:gsub("# (.*)", "\\section{%1}")

		-- Itemize item
		if string.match(line, "^[ \t]*[%*%+%-] (.*)") then
			if inItemize == false then
				table.insert(output, "\\begin{itemize}")
				inItemize = true
			end
			line = line:gsub("^[ \t]*[%*%+%-] (.*)", " \\item %1")
		else
			if inItemize == true then
				inItemize = false
				table.insert(output, "\\end{itemize}")
			end
		end

		-- Enumerate item
		if string.match(line, "^[ \t]*%d%. (.*)") then
			if inEnumerate == false then
				table.insert(output, "\\begin{enumerate}")
				inEnumerate = true
			end
			line = line:gsub("^[ \t]*%d%. (.*)", " \\item %1")
		else
			if inEnumerate == true then
				inEnumerate = false
				table.insert(output, "\\end{enumerate}")
			end
		end

		-- Bold
		line = line:gsub("%*%*([^%*]+)%*%*", "\\textbf{%1}")
		-- Italic
		line = line:gsub("%*([^%*]+)%*", "\\textit{%1}")

		-- Images
		line = line:gsub("!%[(.*)%]%[(.*)%]%[(.*)%]%((.*)%)", [[\begin{figure} \begin{center} \includegraphics[%3]{%4} \end{center} \caption{%1} \label{%2} \end{figure}]])
		line = line:gsub("!%[(.*)%]%[(.*)%]%((.*)%)", [[\begin{figure} \begin{center} \includegraphics{%3} \end{center} \caption{%1} \label{%2} \end{figure}]])

		-- Footnote
		line = line:gsub("%^%[%[(.-)%]%]", "\\footnote{%1}")
		-- References
		line = line:gsub("%[%[(.-)%]%]", "\\ref{%1}")

		-- A goto statement? Really?!
		::done::

		-- Replace line
		if line then
			table.insert(output, line)
		end

		-- Don't insert line at all
		::skip::
	end
	return output
end

local function emitLatex(lines)
	io.write("\\documentclass[a4paper]{"..documentclass.."}\n")
	for i,v in ipairs(includes) do
		if v[2] then
			io.write("\\usepackage["..v[2].."]{"..v[1].."}\n")
		else
			io.write("\\usepackage{"..v[1].."}\n")
		end
	end
	io.write("\\title{"..title.."}\n")
	io.write("\\author{"..author.."}\n")
	io.write("\\begin{document}\n")
	io.write("\\maketitle\n")
	io.write("\\tableofcontents\n")

	for i,v in ipairs(lines) do
		io.write(v)
		io.write("\n")
	end
	io.write("\\end{document}\n")
end

local function main()
	-- Parse input arguments
	parseArguments()

	-- Read entire input file into buffer
	local input = readFile(filename)

	-- Parse lines as Markdown
	local output = parseFile(input)

	-- Emit
	emitLatex(output)
end

main()
