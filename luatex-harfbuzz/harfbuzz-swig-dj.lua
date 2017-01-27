if not modules then modules = { } end modules ['harfbuzz-swig-dj'] = {
	version   = 1.000,
	comment   = "companion to font-hb.lua",
	author    = "Kai Eigner, TAT Zetwerk",
	copyright = "TAT Zetwerk / PRAGMA ADE / ConTeXt Development Team",
	license   = "see context related readme files"
}

local hb = swiglib("hb_deepak.luaharfbuzz", hb_location)
if not hb then
	return nil
end

local Face = hb.Face

--- Extends Face to accept a file name and optional font index
-- in the constructor.
function Face.new(file, font_index)
  local i = font_index or 0
  local fontfile = io.open(file, "rb")
  local fontdata = fontfile:read("*all")
  fontfile:close()

  local blob = hb.Blob.new(fontdata)

  return hb.Face.new_from_blob(blob,i)
end

--- Lua wrapper around Harfbuzz’s hb_shape_full() function. Take language,
--  script, direction and feature string in an optional argument. Sets up the
--  buffer correctly, creates the features by parsing the features string and
--  passes it on to hb_shape_full().
--
--  Returns a table containing shaped glyphs.
hb.shape = function(font, buf, options)
  options = options or { }

  -- Apply options to buffer if they are set.
  if options.language then buf:set_language(options.language) end
  if options.script then buf:set_script(options.script) end
  if options.direction then buf:set_direction(options.direction) end

  -- Guess segment properties, in case all steps above have failed
  -- to set the right properties.
  buf:guess_segment_properties()

  local features = {}

  -- Parse features
  if type(options.features) == "string" then
    for fs in string.gmatch(options.features, '([^,]+)') do
      if string.len(fs) == 5 then
        table.insert(features, hb.Feature.new(fs))
      end
    end
  elseif type(options.features) == "table" then
    features = options.features
  elseif options.features then -- non-nil but not a string or table
    error("Invalid features option")
  end

  return hb.shape_full(font,buf,features)
end

local buffer_metatable = getmetatable(hb.Buffer)

if buffer_metatable and not buffer_metatable.add_utf8 then
	function buffer_metatable.add_utf8(self, text, item_offset, item_length)
	  item_offset = item_offset or 0
	  item_length = item_length or -1
	  return self:add_utf8_c(text,item_offset,item_length)
	end
end

return hb
