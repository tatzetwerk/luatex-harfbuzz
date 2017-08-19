if not modules then modules = { } end modules ['font-hb'] = {
	version   = 1.000,
	comment   = "companion to font-ini.mkiv",
	author    = "Kai Eigner, TAT Zetwerk",
	copyright = "TAT Zetwerk / PRAGMA ADE / ConTeXt Development Team",
	license   = "see context related readme files"
}

glue_to_hb = glue_to_hb or " "

local fonts              = fonts
local otf                = fonts.handlers.otf
local otffeatures        = fonts.constructors.newfeatures("otf")
local txtdirstate        = otf.helpers.txtdirstate
local pardirstate        = otf.helpers.pardirstate

local nodes              = nodes
local nuts               = nodes.nuts
local tonode             = nuts.tonode
local tonut              = nuts.tonut

local getfield           = nuts.getfield
local setfield           = nuts.setfield
local getnext            = nuts.getnext
local getprev            = nuts.getprev
local getid              = nuts.getid
local getfont            = nuts.getfont
local getsubtype         = nuts.getsubtype
local setsubtype         = nuts.setsubtype
local getchar            = nuts.getchar

local copy_node          = nuts.copy
local copy_node_list     = nuts.copy_list
local find_node_tail     = nuts.tail
local flush_list         = nuts.flush_list
local free_node          = nuts.free
local new_node           = nuts.new
local setkern            = nuts.setkern or function(n,k) setfield(n,"kern",k) end
local end_of_math        = nuts.end_of_math

local thekern = new_node("kern",0)
local new_kern = function(k)
	local n = copy_node(thekern)
	setkern(n,k)
	return n
end

local nodecodes          = nodes.nodecodes
local glyph_code         = nodecodes.glyph
local glue_code          = nodecodes.glue
local disc_code          = nodecodes.disc
local kern_code          = nodecodes.kern
local math_code          = nodecodes.math
local dir_code           = nodecodes.dir
local localpar_code      = nodecodes.localpar

local fonthashes         = fonts.hashes
local fontdata           = fonthashes.identifiers

local nodes_handlers_protectglyphs = nodes.handlers.protectglyphs
function nodes.handlers.protectglyphs(head)
	nodes_handlers_protectglyphs(head)
	for n in node.traverse_id(disc_code,head) do
		if n.pre then nodes_handlers_protectglyphs(n.pre) end
		if n.post then nodes_handlers_protectglyphs(n.post) end
		if n.replace then nodes_handlers_protectglyphs(n.replace) end
	end
end

local function deldisc(head)
	local current, next, ok = head, nil, false
	while current do
		next = getnext(current)
		if getid(current) == disc_code then
			ok = true
			local current_replace = copy_node_list(getfield(current,"replace"))
			flush_list(getfield(current,"pre")) setfield(current,"pre",nil)
			flush_list(getfield(current,"post")) setfield(current,"post",nil)
			flush_list(getfield(current,"replace")) setfield(current,"replace",nil)
			if current_replace then
				if current == head then head = current_replace else setfield(getprev(current),"next",current_replace) end
				setfield(current_replace,"prev",getprev(current))
				if getnext(current) then setfield(getnext(current),"prev",find_node_tail(current_replace)) end
				setfield(find_node_tail(current_replace),"next",getnext(current))
				current_replace = nil
			else
				if current == head then head = getnext(current) else setfield(getprev(current),"next",getnext(current)) end
				if getnext(current) then setfield(getnext(current),"prev",getprev(current)) end
			end
			free_node(current)
		end
		current = next
	end
	if ok then
		local current, ok = head, ""
		while current do
			if getid(current) == glyph_code then
				if getchar(current) < 128 then 
					ok = ok..string.char(getchar(current))
				else
					ok = ok.."["..fonts.mappings.tounicode16(getchar(current)).."]"
				end
			end
			current = getnext(current)
		end
		texio.write_nl("Warning: discretionaries deleted in "..ok)
	end
	return head
end

local function equalnode(n, m)
	if not n and not m then return true end
	if not n or not m then return false end
	if getid(n) ~= getid(m) then return false end
	if getid(n) == glyph_code then return getfont(n) == getfont(m) and getchar(n) == getchar(m) end
	if getid(n) == glue_code then return true end
	if getid(n) == kern_code then return getfield(n,"kern") == getfield(m,"kern") end
	if getid(n) == disc_code then
		local c, d, ok = getfield(n,"pre"), getfield(m,"pre"), true
		while c do
			if not equalnode(c, d) then ok = false end
			c = getnext(c)
			if d then d = getnext(d) else break end
		end
		if not ok or c or d then return false end
		local c, d, ok = getfield(n,"post"), getfield(m,"post"), true
		while c do
			if not equalnode(c, d) then ok = false end
			c = getnext(c)
			if d then d = getnext(d) else break end
		end
		if not ok or c or d then return false end
		local c, d, ok = getfield(n,"replace"), getfield(m,"replace"), true
		while c do
			if not equalnode(c, d) then ok = false end
			c = getnext(c)
			if d then d = getnext(d) else break end
		end
		if not ok or c or d then return false end
		return true	
	end
	texio.write_nl("Warning: comparing nodes of type "..node.type(getid(n)))
	return false
end

local function int(x) return x-x%1 end

local function hbnodes(head,start,stop,text,font,rlmode,startglue,stopglue)
	if start then
		local buf = hb.Buffer.new()
		buf:add_utf8(startglue..text..stopglue)

		local tfmdata = fontdata[font]
		local hb_font = tfmdata.shared.hb_font
		local factor = tfmdata.parameters.factor
		local marks = tfmdata.resources.marks or {}
		local spacewidth = tfmdata.shared.spacewidth
		local cptochar = tfmdata.shared.cptochar

		local opts = tfmdata.shared.opts
		opts.direction = rlmode < 0 and "rtl" or "ltr"

		hb.shape(hb_font, buf, opts)

		if rlmode < 0 then
			buf:reverse()
		end
		local glyphs = buf:get_glyph_infos_and_positions()

		local n, nn, prev = nil, nil, nil
		if start ~= head then
			prev = getfield(start,"prev")
		else
			prev = nil
		end

		local clusterstart = string.len(startglue)
		local clusterstop = clusterstart
		local c, nodebuf = start, {}
		while c and c~=stop do
			nodebuf[clusterstop] = c
			clusterstop=clusterstop+string.len(unicode.utf8.char(getchar(c) or 0x0020))
			c = getnext(c)
		end

		local k, v, vnext = next(glyphs)
		while v do
			local char = cptochar[v.codepoint]
			local cluster = v.cluster

			k, vnext = next(glyphs, k)
			local clusternext = vnext and vnext.cluster or clusterstop
			local components, lastcomp = nil, nil
			for ck=cluster,clusternext-1 do
				local nodebufck = nodebuf[ck]
				if nodebufck then
					lastcomp = nodebufck
					components = components or lastcomp
				end
			end
			if components then
				setfield(components,"prev",nil)
				setfield(lastcomp,"next",nil)
			end

			n, nn = nil, nil
			if char == 0x0020 or char == 0x00A0 then
				local diff = v.x_advance - spacewidth
				if diff ~= 0 then
					nn = new_kern(int(diff * factor + .5))
 				end
				if cluster >= clusterstart and cluster < clusterstop then
					n = nodebuf[cluster]
					if getid(n) == glue_code then
						n = copy_node(n)
					else
						n = new_kern(int(spacewidth * factor + .5))
					end
					if components then
						flush_list(components)
						components = nil
					end
				end
				if n and nn then
					if rlmode < 0 then
						n, nn = nn, n
					end
					setfield(n,"next",nn)
					setfield(nn,"prev",n)
				end

			else
				n = nodebuf[cluster]
				if getid(n) == glyph_code then
					n = copy_node(n)
				else
					n = new_node("glyph")
					setfield(n,"font",font)
				end
				if components and components == lastcomp then
					flush_list(components)
					components = nil
				end
				setfield(n,"char",char)
				if components then
					setfield(n,"components",components)
					setfield(n,"subtype",2)
				end
				if rlmode >= 0 then
					setfield(n,"xoffset",int(v.x_offset * factor + .5))
					setfield(n,"yoffset",int(v.y_offset * factor + .5))
--					setfield(n,"width",int(v.x_advance * factor + .5))
--					setfield(n,"height",int(v.y_advance * factor + .5))
					if v.x_advance ~= int(getfield(n,"width") / factor + .5) then
						nn = new_kern(int(v.x_advance * factor + .5) - getfield(n,"width"))
						setfield(n,"next",nn)
						setfield(nn,"prev",n)
					end
				else
					setfield(n,"yoffset",int(v.y_offset * factor + .5))
--					setfield(n,"width",int(v.x_advance * factor + .5))
--					setfield(n,"height",int(v.y_advance * factor + .5))
					if marks[char] then
						setfield(n,"xoffset",-int(v.x_offset * factor + .5))
					else
						setfield(n,"xoffset",0)
						local kern = int((v.x_advance - v.x_offset) * factor + .5) - getfield(n,"width")
						if kern ~= 0 then
							nn = new_kern(kern)
							n, nn = nn, n
							setfield(n,"next",nn)
							setfield(nn,"prev",n)
						end
						kern = int(v.x_offset * factor + .5)
						if kern ~= 0 then
							local tmp = nn or n
							nn = new_kern(kern)
							setfield(nn,"prev",tmp)
							setfield(tmp,"next",nn)
						end
					end
				end
			end
			
			if n and not nn then
				nn = n
			elseif nn and not n then
				n = nn
			end
			if n then
				if prev then
					setfield(prev,"next",n)
					setfield(n,"prev",prev)
				else
					setfield(n,"prev",nil)
					head = n
				end
				prev = nn
			else
				nn = prev
			end
			v = vnext
		end
		if stop then
			setfield(nn,"next",stop)
			setfield(stop,"prev",nn)
		else
			setfield(nn,"next",nil)
		end
	end

	return head, nil, ""
end

local function harfbuzz(head,font,attr,direction,n,startglue,stopglue)
	head = tonut(head)
	local rlparmode = direction == "TRT" and -1 or 0
	local rlmode    = rlparmode
	local dirstack  = { }
	local topstack  = 0
	local startglue, stopglue = startglue or "", stopglue or ""
	local dirstack, rlparmode, topstack, text = { }, 0, 0, ""
	local current, start, stop, startrlmode = head, nil, nil, rlmode
	while current do
		local id = getid(current)
		if id == glyph_code and getfont(current) == font and getsubtype(current) < 256 then
			if not start then
				start = current
				startrlmode = rlmode
			end
			local char = getchar(current)
			text = text .. unicode.utf8.char(char)
			current = getnext(current)
		elseif id == disc_code then
			local pre, post, currentnext = nil, nil, getnext(current)
			local current_pre, current_post, current_replace = copy_node_list(getfield(current,"pre")), copy_node_list(getfield(current,"post")), copy_node_list(getfield(current,"replace"))
			flush_list(getfield(current,"pre")) setfield(current,"pre",nil)
			flush_list(getfield(current,"post")) setfield(current,"post",nil)
			flush_list(getfield(current,"replace")) setfield(current,"replace",nil)
			if startrlmode >= 0 then
				if start then
					pre = copy_node_list(start, current)
					stop = getprev(current)
					setfield(current,"prev",getprev(start))
					if start == head then head = current end
					if getprev(start) then setfield(getprev(start),"next",current) end
					setfield(stop,"next",current_pre)
					if current_pre then setfield(current_pre,"prev",stop) end
					current_pre = start
					setfield(current_pre,"prev",nil)
					start, stop, startrlmode = nil, nil, rlmode
				end
				while currentnext and ((getid(currentnext) == glyph_code and getfont(currentnext) == font and getsubtype(currentnext) < 256) or getid(currentnext) == disc_code) do stop = currentnext currentnext = getnext(currentnext) end
				if currentnext and getid(currentnext) == glue_code then
					local width = getfield(currentnext,"width")
					if width and width > 0 then
						stopglue = glue_to_hb
					else
						stopglue = ""
					end
				end
				if stop then
					post = copy_node_list(getnext(current), getnext(stop))
					if current_post then
						setfield(getnext(current),"prev",find_node_tail(current_post))
						setfield(find_node_tail(current_post),"next",getnext(current))
					else
						setfield(getnext(current),"prev",nil)
						current_post = getnext(current)
					end
					if getnext(stop) then setfield(getnext(stop),"prev",current) end
					setfield(current,"next",getnext(stop))
					setfield(stop,"next",nil)
					stop = nil
				end
				if pre then
					if current_replace then setfield(current_replace,"prev",find_node_tail(pre)) end
					setfield(find_node_tail(pre),"next",current_replace)
					current_replace = pre
					pre = nil
				end
				if post then
					if current_replace then
						setfield(post,"prev",find_node_tail(current_replace))
						setfield(find_node_tail(current_replace),"next",post)
					else
						current_replace = post
					end
					post = nil
				end

				text = ""

			elseif rlmode < 0 then
				texio.write_nl("Warning: discretionary found while in rlmode")
				head, start, text = hbnodes(head,start,current,text,font,rlmode,startglue,"")
				startglue = ""
			end

			current_pre = tonut(harfbuzz(tonode(current_pre),font,attr,direction,n,startglue,""))
			current_post = tonut(harfbuzz(tonode(current_post),font,attr,direction,n,"",stopglue))
			current_replace = tonut(harfbuzz(tonode(current_replace),font,attr,direction,n,startglue,stopglue))
			startglue, stopglue = "", ""

			local cpost, creplace, cpostnew, creplacenew, newcurrent = find_node_tail(current_post), find_node_tail(current_replace), nil, nil, nil
			while cpost and equalnode(cpost, creplace) do
				cpostnew = cpost
				creplacenew = creplace
				if creplace then creplace = getprev(creplace) end
				cpost = getprev(cpost)
			end

			if cpostnew then
				if cpostnew == current_post then current_post = nil else setfield(getprev(cpostnew),"next",nil) end
				flush_list(cpostnew) cpostnew = nil

				if creplacenew == current_replace then current_replace = nil else setfield(getprev(creplacenew),"next",nil) end
				local c = getnext(current)
				setfield(current,"next",creplacenew)
				setfield(creplacenew,"prev",current)
				local creplacenewtail = find_node_tail(creplacenew)
				if c then setfield(c,"prev",creplacenewtail) end
				setfield(creplacenewtail,"next",c)
				newcurrent=creplacenewtail
			end

			current_replace = deldisc(current_replace)	-- when luatex is able to deal with nested discretionaries this line can be removed
			current_post = deldisc(current_post)		-- when luatex is able to deal with nested discretionaries this line can be removed

			local cpre, creplace, cprenew, creplacenew = current_pre, current_replace, nil, nil
			while cpre and equalnode(cpre, creplace) do
				cprenew = cpre
				creplacenew = creplace
				if creplace then creplace = getnext(creplace) end
				cpre = getnext(cpre)
			end

			if cprenew then
				cpre = current_pre
				current_pre = getnext(cprenew)
				if current_pre then setfield(current_pre,"prev",nil) end
				setfield(cprenew,"next",nil)
				flush_list(cpre) cpre = nil

				creplace = current_replace
				current_replace = getnext(creplacenew)
				if current_replace then setfield(current_replace,"prev",nil) end
				setfield(creplace,"prev",getprev(current))
				if current == head then head = creplace end
				if getprev(current) then setfield(getprev(current),"next",creplace) end
				setfield(creplacenew,"next",current)
				setfield(current,"prev",creplacenew)
			end
			setfield(current,"pre",current_pre) setfield(current,"post",current_post) setfield(current,"replace",current_replace)
			current = currentnext
		elseif id == glue_code then
			if rlmode >= 0 then
				local width = getfield(current,"width")
				if width and width > 0 then
					head, start, text = hbnodes(head,start,current,text,font,rlmode,startglue,glue_to_hb)
					startglue, stopglue = glue_to_hb, ""
				else
					head, start, text = hbnodes(head,start,current,text,font,rlmode,startglue,"")
					startglue, stopglue = "", ""
				end
			else
				if not start then
					start = current
					startrlmode = rlmode
				end
				text = text .. " "
			end
			current = getnext(current)
		else
			head, start, text = hbnodes(head,start,current,text,font,rlmode,startglue,stopglue)
			startglue, stopglue = "", ""
			if id == math_code then	--TODO
				current = end_of_math(current)
				current = getnext(current)
			elseif id == dir_code then
				current, topstack, rlmode = txtdirstate(current,dirstack,topstack,rlparmode)
				if topstack == 0 then
					rlmode = rlparmode
				end
				if rlmode == -1 then
					direction = "TRT"
				else
					direction = "TLT"
				end
			elseif id == localpar_code then
				current, rlparmode, rlmode = pardirstate(current)
				if rlmode == -1 then
					direction = "TRT"
				else
					direction = "TLT"
				end
			else
				current = getnext(current)
			end
		end

	end
	if text ~= "" and start then
		head, start, text = hbnodes(head,start,current,text,font,rlmode,startglue,stopglue)
	end

	return tonode(head), true
end


local function initializeharfbuzz(tfmdata)
	local resources        = tfmdata.resources
	local filename         = resources.filename
	local face             = hb.Face.new(filename)
	tfmdata.shared.hb_font = hb.Font.new(face)

	tfmdata.shared.cptochar = {}
	local cptochar = tfmdata.shared.cptochar
	local characters   = tfmdata.shared.rawdata.descriptions
	for k,v in next, characters do
		cptochar[v.index] = k
		if k == 0x0020 or (k == 0x00A0 and not tfmdata.shared.spacewidth) then
			tfmdata.shared.spacewidth = v.width
		end
	end
	
	local features, featurestring, localopts = tfmdata.shared.features, "", {}
	for k,v in next, features do
		if k == "harfbuzz" or k == "analyze" or k == "features" or k  == "devanagari" or k == "spacekern" then
		elseif k == "mode" and v == "base" then
--			texio.write_nl("Warning: mode of harfbuzz fonts should be node!")
		elseif k == "mode" and v == "node" then
		elseif (type(v) == "string" and v == "yes") or (type(v) == "boolean" and v) then
			featurestring = featurestring .. "+" .. tostring(k) .. ","
		elseif (type(v) == "string" and v == "no") or (type(v) == "boolean" and not v) then
			featurestring = featurestring .. "-" .. tostring(k) .. ","
		elseif type(v) == "string" then
			if k == "language" then
				localopts.language = v
			elseif k == "script" then
				localopts.script = v
			end
		end
	end
	if featurestring ~= "" then
		localopts.features = featurestring
	end
	tfmdata.shared.opts = localopts

	local keepfeatures = {}
	keepfeatures["tlig"] = features["tlig"]
	keepfeatures["trep"] = features["trep"]
	keepfeatures["tcom"] = features["tcom"]
	keepfeatures["anum"] = features["anum"]
	tfmdata.shared.features = keepfeatures
end

otffeatures.register {
	name        = "harfbuzz",
	description = "harfbuzz",
	initializers = {
		node = initializeharfbuzz,
	},
	processors = {
		node = harfbuzz,
	},
}

local methods      = fonts.analyzers.methods
local methods_deva = methods.deva

function methods.deva(head,font,attr)
	local tfmdata = fontdata[font]
	if tfmdata.specification.features.normal.harfbuzz then
		return head, true
	end
	return methods_deva(head,font,attr)
end
