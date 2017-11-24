if not modules then modules = { } end modules ['harfbuzz-swig'] = {
	version   = 1.000,
	comment   = "companion to font-hb.lua",
	author    = "Kai Eigner, TAT Zetwerk",
	copyright = "TAT Zetwerk / PRAGMA ADE / ConTeXt Development Team",
	license   = "see context related readme files"
}

local hb = swiglib("hb.core", hb_location)
if not hb then
	return nil
end

hb.Face = hb.Face or {}
local Face = hb.Face

--- Extends Face to accept a file name and optional font index
-- in the constructor.
function Face.new(file, font_index)
	local i = font_index or 0
	local fontfile = assert(io.open(file, "rb"))
	local fontdata = fontfile:read("*all")
	fontfile:close()
	local blob = hb.hb_blob_create(fontdata,#fontdata,hb["HB_MEMORY_MODE_DUPLICATE"],nil,nil)
	return hb.hb_face_create(blob,i)
end

--- Lua wrapper around Harfbuzz’s hb_shape_full() function. Take language,
--  script, direction and feature string in an optional argument. Sets up the
--  buffer correctly, creates the features by parsing the features string and
--  passes it on to hb_shape_full().
--
--  Returns a table containing shaped glyphs.
hb.shape = function(font, buf, options, shaper)
	options = options or { }

	-- Apply options to buffer if they are set.
	if options.language then
		local lang = options.language
		lang  = hb.hb_language_from_string(lang, #lang)
		hb.hb_buffer_set_language(buf.buf, lang)
	end
	if options.script then
		local script = options.script
		script  = hb.hb_script_from_string(script, #script)
		hb.hb_buffer_set_script(buf.buf, script)
	end
	if options.direction then
		local dir = options.direction
		dir  = hb.hb_direction_from_string(dir, #dir)
		hb.hb_buffer_set_direction(buf.buf, dir)
	end

	-- Guess segment properties, in case all steps above have failed
	-- to set the right properties.
	buf:guess_segment_properties()

	local featurestrings = {}
	local features, num_features = nil, 0
	-- Parse features

	if type(options.features) == "string" then
		for fs in string.gmatch(options.features, '([^,]+)') do
			num_features = num_features + 1
			table.insert(featurestrings, fs)
		end
		features = hb.new_hb_feature_t_array(num_features)
		for i=1,num_features do
			local feature = hb.hb_feature_t()
			hb.hb_feature_from_string(featurestrings[i], #featurestrings[i], feature)
			hb.hb_feature_t_array_setitem(features, i-1, feature)
		end
	elseif type(options.features) == "table" then
		features = options.features
	elseif options.features then -- non-nil but not a string or table
		error("Invalid features option")
	end

	local shapers = nil
	if shaper ~= "" then
		shapers = hb.new_char_p_array(0)
		hb.char_p_array_setitem(shapers, 0, shaper)
	end

	hb.hb_shape_full(font, buf.buf, features, num_features, shapers)
end

hb.Buffer = hb.Buffer or {}
local Buffer = hb.Buffer
Buffer_mt = { __index = Buffer }

function Buffer:create()
	Buffer.buf = hb.hb_buffer_create()
end

function Buffer:add_utf8(text)
	hb.hb_buffer_add_utf8(Buffer.buf, text, #text, 0, #text)
end

function Buffer:get_glyph_infos_and_positions()
	local len = hb.hb_buffer_get_length(Buffer.buf)
	local info = hb.hb_buffer_get_glyph_infos(Buffer.buf, nil)
	local pos = hb.hb_buffer_get_glyph_positions(Buffer.buf, nil)

	local glyphs = {}
	for i=0,len-1 do
		table.insert(glyphs, {
			codepoint = hb.uint32_t_to_unsigned_long_int(hb.hb_glyph_info_t_array_getitem(info, i).codepoint),
			mask = hb.uint32_t_to_unsigned_long_int(hb.hb_glyph_info_t_array_getitem(info, i).mask),
			cluster = hb.uint32_t_to_unsigned_long_int(hb.hb_glyph_info_t_array_getitem(info, i).cluster),
			x_advance = hb.int32_t_to_long_int(hb.hb_glyph_position_t_array_getitem(pos, i).x_advance),
			y_advance = hb.int32_t_to_long_int(hb.hb_glyph_position_t_array_getitem(pos, i).y_advance),
			x_offset = hb.int32_t_to_long_int(hb.hb_glyph_position_t_array_getitem(pos, i).x_offset),
			y_offset = hb.int32_t_to_long_int(hb.hb_glyph_position_t_array_getitem(pos, i).y_offset),
		})
	end		
	return glyphs
end

function Buffer:reverse()
	hb.hb_buffer_reverse(Buffer.buf)
end

function Buffer:guess_segment_properties()
	hb.hb_buffer_guess_segment_properties(Buffer.buf)
end

function Buffer:new(o)
	o = o or {}
	setmetatable(o, Buffer_mt)
	o:create()
	return o
end

hb.Font = hb.Font or {}
function hb.Font.new(face)
	local font = hb.hb_font_create(face)
	hb.hb_font_set_scale(font, hb.hb_face_get_upem(face), hb.hb_face_get_upem(face))
	hb.hb_ot_font_set_funcs(font)
	return font
end

hb.version = hb.hb_version_string;

return hb
