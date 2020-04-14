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

local getnext            = nuts.getnext
local setnext            = nuts.setnext
local getprev            = nuts.getprev
local setprev            = nuts.setprev
local getid              = nuts.getid
local getfont            = nuts.getfont
local setfont            = node.direct.setfont
local getsubtype         = nuts.getsubtype
local setsubtype         = nuts.setsubtype
local getchar            = nuts.getchar
local setchar            = nuts.setchar
local getdisc            = nuts.getdisc
local setdisc            = nuts.setdisc
local getwidth           = nuts.getwidth
local setwidth           = nuts.setwidth
--local setheight          = nuts.setheight
local setoffsets         = nuts.setoffsets
local setcomponents      = nuts.setcomponents
local getkern            = nuts.getkern
local setkern            = nuts.setkern

local copy_node          = nuts.copy
local copy_node_list     = nuts.copy_list
local find_node_tail     = nuts.tail
local flush_list         = nuts.flush_list
local free_node          = nuts.free
local new_node           = nuts.new
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

utf = utf or (unicode and unicode.utf8) or { }

local function deldisc(head)
	local current, next, ok = head, nil, false
	while current do
		next = getnext(current)
		if getid(current) == disc_code then
			ok = true
			local c_pre, c_post, c_replace = getdisc(current)
			local current_replace = copy_node_list(c_replace)
			flush_list(c_pre)
			flush_list(c_post)
			flush_list(c_replace)
			setdisc(current,nil,nil,nil)
			if current_replace then
				if current == head then head = current_replace else setnext(getprev(current),current_replace) end
				setprev(current_replace,getprev(current))
				if getnext(current) then setprev(getnext(current),find_node_tail(current_replace)) end
				setnext(find_node_tail(current_replace),getnext(current))
				current_replace = nil
			else
				if current == head then head = getnext(current) else setnext(getprev(current),getnext(current)) end
				if getnext(current) then setprev(getnext(current),getprev(current)) end
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
--		texio.write_nl("Warning: discretionaries deleted in "..ok)
	end
	return head
end

local function equalnode(n, m)
	if not n and not m then return true end
	if not n or not m then return false end
	if getid(n) ~= getid(m) then return false end
	if getid(n) == glyph_code then return getfont(n) == getfont(m) and getchar(n) == getchar(m) end
	if getid(n) == glue_code then return true end
	if getid(n) == kern_code then return getkern(n) == getkern(m) end
	if getid(n) == disc_code then
		local c_pre, c_post, c_replace = getdisc(n)
		local d_pre, d_post, d_replace = getdisc(m)
		local ok = true
		while c_pre do
			if not equalnode(c_pre, d_pre) then ok = false end
			c_pre = getnext(c_pre)
			if d_pre then d_pre = getnext(d_pre) else break end
		end
		if not ok or c_pre or d_pre then return false end
		ok = true
		while c_post do
			if not equalnode(c_post, d_post) then ok = false end
			c_post = getnext(c_post)
			if d_post then d_post = getnext(d_post) else break end
		end
		if not ok or c_post or d_post then return false end
		ok = true
		while c_replace do
			if not equalnode(c_replace, d_replace) then ok = false end
			c_replace = getnext(c_replace)
			if d_replace then d_replace = getnext(d_replace) else break end
		end
		if not ok or c_replace or d_replace then return false end
		return true	
	end
--	texio.write_nl("Warning: comparing nodes of type "..node.type(getid(n)))
	return false
end

local function int(x) return x-x%1 end

local function hbnodes(head,start,stop,text,font,rlmode,startglue,stopglue)
	if start then
		local buf = hb.Buffer.new()
		buf:add_utf8(startglue..text..stopglue)

		local tfmdata = fontdata[font]
		local tfmdata_shared = tfmdata.shared
		local hb_font = tfmdata_shared.hb_font
		local factor = tfmdata.parameters.factor
		local marks = tfmdata.resources.marks or {}
		local spacewidth = tfmdata_shared.spacewidth
		local cptochar = tfmdata_shared.cptochar

		local opts = tfmdata_shared.opts
		opts.direction = rlmode < 0 and "rtl" or "ltr"

		if start ~= head then
			prev = getprev(start)
		else
			prev = nil
		end

		local n, nn, clusterstart, clusterstop = nil, nil, nil, nil
		local glyphs, nodebuf = {}, {}
		if hb.shape(hb_font, buf, opts, tfmdata_shared.shaper) then
			if rlmode < 0 then
				buf:reverse()
			end
			glyphs = buf:get_glyph_infos_and_positions()

			clusterstart = string.len(startglue)
			clusterstop = clusterstart
			local c = start
			while c and c~=stop do
				nodebuf[clusterstop] = c
				clusterstop=clusterstop+string.len(utf.char(getchar(c) or 0x0020))
				c = getnext(c)
			end
		end

		local prevglue = nil
		local k, v, vnext = next(glyphs)

		if not v then
			setprev(start,nil)
			if stop then
				setnext(getprev(stop),nil)
			end
			flush_list(start)
			nn = prev
			if not nn then
				head = stop
			end
		end

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
				setprev(components,nil)
				setnext(lastcomp,nil)
			end

			n, nn = nil, nil
			if char == 0x0020 or char == 0x00A0 then
				local diff = v.x_advance - spacewidth
				if cluster >= clusterstart and cluster < clusterstop then
					n = nodebuf[cluster]
					if getid(n) == glue_code then
						n = copy_node(n)
						if diff ~= 0 then
							setwidth(n,(int(diff * factor + .5) + getwidth(n)))
						end
						prevglue = n
					else
						n = new_kern(int((diff+spacewidth) * factor + .5))
						prevglue = nil
					end
					if components then
						flush_list(components)
						components = nil
					end
				else
					if diff ~= 0 then
						if prevglue then
							setwidth(prevglue,getwidth(prevglue) + int(diff * factor + .5))
						else
							nn = new_kern(int(diff * factor + .5))
						end
					end
					prevglue = nil
				end
				if n and nn then
					if rlmode < 0 then
						n, nn = nn, n
					end
					setnext(n,nn)
					setprev(nn,n)
				end

			else
				n = nodebuf[cluster]
				if getid(n) == glyph_code then
					n = copy_node(n)
				else
					n = new_node("glyph")
					setfont(n,font)
				end
				if components and components == lastcomp then
					flush_list(components)
					components = nil
				end
				setchar(n,char)
				if components then
					setcomponents(n,components)
					setsubtype(n,2)
				end
				if rlmode >= 0 then
					setoffsets(n,int(v.x_offset * factor + .5),int(v.y_offset * factor + .5))
--					setwidth(n,int(v.x_advance * factor + .5))
--					setheight(n,int(v.y_advance * factor + .5))
					if v.x_advance ~= int(getwidth(n) / factor + .5) then
						nn = new_kern(int(v.x_advance * factor + .5) - getwidth(n))
						setnext(n,nn)
						setprev(nn,n)
					end
				else
--					setwidth(n,int(v.x_advance * factor + .5))
--					setheight(n,int(v.y_advance * factor + .5))
					if marks[char] then
						setoffsets(n,-int(v.x_offset * factor + .5),int(v.y_offset * factor + .5))
					else
						setoffsets(n,0,int(v.y_offset * factor + .5))
						local kern = int((v.x_advance - v.x_offset) * factor + .5) - getwidth(n)
						if kern ~= 0 then
							if prevglue then
								setwidth(prevglue,getwidth(prevglue) + kern)
							else
								nn = new_kern(kern)
								n, nn = nn, n
								setnext(n,nn)
								setprev(nn,n)
							end
						end
						kern = int(v.x_offset * factor + .5)
						if kern ~= 0 then
							local tmp = nn or n
							nn = new_kern(kern)
							setprev(nn,tmp)
							setnext(tmp,nn)
						end
					end
				end
				prevglue = nil
			end
			
			if n and not nn then
				nn = n
			elseif nn and not n then
				n = nn
			end
			if n then
				if prev then
					setnext(prev,n)
					setprev(n,prev)
				else
					setprev(n,nil)
					head = n
				end
				prev = nn
			else
				nn = prev
			end
			v = vnext
		end
		if stop then
			setprev(stop,nn)
		end
		if nn then
			setnext(nn,stop)
		end
	end

	return head, nil, ""
end

local function harfbuzz(head,font,attr,direction,n,startglue,stopglue)
	if not fontdata[font].shared.shaper then
		return head
	end
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
			text = text .. utf.char(char)
			current = getnext(current)
		elseif id == disc_code then
			local pre, post, currentnext = nil, nil, getnext(current)
			local c_pre, c_post, c_replace = getdisc(current)
			local current_pre = copy_node_list(c_pre)
			local current_post = copy_node_list(c_post)
			local current_replace = copy_node_list(c_replace)
			flush_list(c_pre)
			flush_list(c_post)
			flush_list(c_replace)
			setdisc(current,nil,nil,nil)
			if startrlmode >= 0 then
				if start then
					pre = copy_node_list(start, current)
					stop = getprev(current)
					setprev(current,getprev(start))
					if start == head then head = current end
					if getprev(start) then setnext(getprev(start),current) end
					setnext(stop,current_pre)
					if current_pre then setprev(current_pre,stop) end
					current_pre = start
					setprev(current_pre,nil)
					start, stop, startrlmode = nil, nil, rlmode
				end
				while currentnext and ((getid(currentnext) == glyph_code and getfont(currentnext) == font and getsubtype(currentnext) < 256) or getid(currentnext) == disc_code) do stop = currentnext currentnext = getnext(currentnext) end
				if currentnext and getid(currentnext) == glue_code then
--					local width = getwidth(currentnext)
--					if width > 0 or getsubtype(currentnext) == 13 then
					if getsubtype(currentnext) == 13 then
						stopglue = glue_to_hb
					else
						stopglue = ""
					end
				end
				if stop then
					post = copy_node_list(getnext(current), getnext(stop))
					if current_post then
						setprev(getnext(current),find_node_tail(current_post))
						setnext(find_node_tail(current_post),getnext(current))
					else
						setprev(getnext(current),nil)
						current_post = getnext(current)
					end
					if getnext(stop) then setprev(getnext(stop),current) end
					setnext(current,getnext(stop))
					setnext(stop,nil)
					stop = nil
				end
				if pre then
					if current_replace then setprev(current_replace,find_node_tail(pre)) end
					setnext(find_node_tail(pre),current_replace)
					current_replace = pre
					pre = nil
				end
				if post then
					if current_replace then
						setprev(post,find_node_tail(current_replace))
						setnext(find_node_tail(current_replace),post)
					else
						current_replace = post
					end
					post = nil
				end

				text = ""

			elseif rlmode < 0 then
--				texio.write_nl("Warning: discretionary found while in rlmode")
				head, start, text = hbnodes(head,start,current,text,font,rlmode,startglue,"")
				startglue = ""
			end

			current_pre = harfbuzz(current_pre,font,attr,direction,n,startglue,"")
			current_post = harfbuzz(current_post,font,attr,direction,n,"",stopglue)
			current_replace = harfbuzz(current_replace,font,attr,direction,n,startglue,stopglue)
			startglue, stopglue = "", ""

			local cpost, creplace, cpostnew, creplacenew, newcurrent = find_node_tail(current_post), find_node_tail(current_replace), nil, nil, nil
			while cpost and equalnode(cpost, creplace) do
				cpostnew = cpost
				creplacenew = creplace
				if creplace then creplace = getprev(creplace) end
				cpost = getprev(cpost)
			end

			if cpostnew then
				if cpostnew == current_post then current_post = nil else setnext(getprev(cpostnew),nil) end
				flush_list(cpostnew) cpostnew = nil

				if creplacenew == current_replace then current_replace = nil else setnext(getprev(creplacenew),nil) end
				local c = getnext(current)
				setnext(current,creplacenew)
				setprev(creplacenew,current)
				local creplacenewtail = find_node_tail(creplacenew)
				if c then setprev(c,creplacenewtail) end
				setnext(creplacenewtail,c)
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
				if current_pre then setprev(current_pre,nil) end
				setnext(cprenew,nil)
				flush_list(cpre) cpre = nil

				creplace = current_replace
				current_replace = getnext(creplacenew)
				if current_replace then setprev(current_replace,nil) end
				setprev(creplace,getprev(current))
				if current == head then head = creplace end
				if getprev(current) then setnext(getprev(current),creplace) end
				setnext(creplacenew,current)
				setprev(current,creplacenew)
			end
			setdisc(current,current_pre,current_post,current_replace)
			current = currentnext
		elseif id == glue_code then
			if rlmode >= 0 then
--				local width = getwidth(current)
--				if width > 0 or getsubtype(current) == 13 then
				if getsubtype(current) == 13 then
					head, start, text = hbnodes(head,start,current,text,font,rlmode,startglue,glue_to_hb)
					startglue, stopglue = glue_to_hb, ""
				else
					head, start, text = hbnodes(head,start,current,text,font,rlmode,startglue,"")
					startglue, stopglue = "", ""
				end
			else
--				local width = getwidth(current)
--				if width > 0 or getsubtype(current) == 13 then
				if getsubtype(current) == 13 then
					if not start then
						start = current
						startrlmode = rlmode
					end
					text = text .. " "
				else
					head, start, text = hbnodes(head,start,current,text,font,rlmode,startglue,stopglue)
					startglue, stopglue = "", ""
				end
			end
			current = getnext(current)
		else
			head, start, text = hbnodes(head,start,current,text,font,rlmode,startglue,stopglue)
			startglue, stopglue = "", ""
			if id == math_code then	--TODO
				current = end_of_math(current)
			elseif id == dir_code then
				topstack, rlmode = txtdirstate(current,dirstack,topstack,rlparmode)
				if topstack == 0 then
					rlmode = rlparmode
				end
				if rlmode == -1 then
					direction = "TRT"
				else
					direction = "TLT"
				end
			elseif id == localpar_code then
				rlparmode, rlmode = pardirstate(current)
				if rlmode == -1 then
					direction = "TRT"
				else
					direction = "TLT"
				end
			end
			current = getnext(current)
		end

	end
	if text ~= "" and start then
		head, start, text = hbnodes(head,start,current,text,font,rlmode,startglue,stopglue)
	end

	return head, true
end


local function initializeharfbuzz(tfmdata)
	local features, featurestring, localopts, localshaper = tfmdata.shared.features, "", {}, ""
	for k,v in next, features do
		if k == "harfbuzz" then
			if (type(v) == "string" and v == "yes") or (type(v) == "boolean" and v) then
				localshaper = ""
			elseif (type(v) == "string" and v == "no") or (type(v) == "boolean" and not v) then
				return
			elseif type(v) == "string" then
				localshaper = v
			end
		elseif k == "analyze" or k == "features" or k  == "devanagari" or k == "spacekern" or k == "checkmarks" then
		elseif k == "mode" and v == "base" then
--			texio.write_nl("Warning: mode of harfbuzz fonts should be node!")
		elseif k == "mode" and v == "node" then
		elseif k == "language" and type(v) == "string" then
			localopts.language = v
		elseif k == "script" and type(v) == "string" then
			localopts.script = v
		elseif string.len(k) == 4 then
			if (type(v) == "string" and v == "yes") or (type(v) == "boolean" and v) then
				featurestring = featurestring .. "+" .. tostring(k) .. ","
			elseif (type(v) == "string" and v == "no") or (type(v) == "boolean" and not v) then
				featurestring = featurestring .. "-" .. tostring(k) .. ","
			elseif type(v) == "string" then
				featurestring = featurestring .. "+" .. tostring(k) .. "=" .. v .. ","
			end
		end
	end
	if featurestring ~= "" then
		localopts.features = featurestring
	end
	tfmdata.shared.opts = localopts
	tfmdata.shared.shaper = localshaper

	local keepfeatures = {}
	keepfeatures["tlig"] = features["tlig"]
	keepfeatures["trep"] = features["trep"]
	keepfeatures["tcom"] = features["tcom"]
	keepfeatures["anum"] = features["anum"]
	tfmdata.shared.features = keepfeatures

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

local scripts = { }

local scripts_one = { "deva", "mlym", "beng", "gujr", "guru", "knda", "orya", "taml", "telu" }
local scripts_two = { "dev2", "mlm2", "bng2", "gjr2", "gur2", "knd2", "ory2", "tml2", "tel2" }

local nofscripts = #scripts_one

local methods = fonts.analyzers.methods

for i=1,nofscripts do
	local methods_orig_one = methods[scripts_one[i]]
	local methods_orig_two = methods[scripts_two[i]]

	methods[scripts_one[i]] = function(head,font,attr)
		local tfmdata = fontdata[font]
		if tfmdata.specification.features.normal.harfbuzz then
			return head, true
		end
		return methods_orig_one(head,font,attr)
	end

	methods[scripts_two[i]] = function(head,font,attr)
		local tfmdata = fontdata[font]
		if tfmdata.specification.features.normal.harfbuzz then
			return head, true
		end
		return methods_orig_two(head,font,attr)
	end
end
