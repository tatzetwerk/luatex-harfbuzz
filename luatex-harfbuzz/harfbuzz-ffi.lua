if not modules then modules = { } end modules ['harfbuzz-ffi'] = {
	version   = 1.000,
	comment   = "companion to font-hb.lua",
	author    = "Kai Eigner, TAT Zetwerk",
	copyright = "TAT Zetwerk / PRAGMA ADE / ConTeXt Development Team",
	license   = "see context related readme files"
}

local ffi = require("ffi")

ffi.cdef[[
typedef struct hb_blob_t hb_blob_t;

typedef enum {
  HB_MEMORY_MODE_DUPLICATE,
  HB_MEMORY_MODE_READONLY,
  HB_MEMORY_MODE_WRITABLE,
  HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE
} hb_memory_mode_t;

typedef void (*hb_destroy_func_t) (void *user_data);

typedef struct hb_face_t hb_face_t;

typedef const struct hb_language_impl_t *hb_language_t;

typedef struct hb_buffer_t hb_buffer_t;

typedef enum
{
  HB_SCRIPT_COMMON,
  HB_SCRIPT_INHERITED,
  HB_SCRIPT_UNKNOWN,

  HB_SCRIPT_ARABIC,
  HB_SCRIPT_ARMENIAN,
  HB_SCRIPT_BENGALI,
  HB_SCRIPT_CYRILLIC,
  HB_SCRIPT_DEVANAGARI,
  HB_SCRIPT_GEORGIAN,
  HB_SCRIPT_GREEK,
  HB_SCRIPT_GUJARATI,
  HB_SCRIPT_GURMUKHI,
  HB_SCRIPT_HANGUL,
  HB_SCRIPT_HAN,
  HB_SCRIPT_HEBREW,
  HB_SCRIPT_HIRAGANA,
  HB_SCRIPT_KANNADA,
  HB_SCRIPT_KATAKANA,
  HB_SCRIPT_LAO,
  HB_SCRIPT_LATIN,
  HB_SCRIPT_MALAYALAM,
  HB_SCRIPT_ORIYA,
  HB_SCRIPT_TAMIL,
  HB_SCRIPT_TELUGU,
  HB_SCRIPT_THAI,

  HB_SCRIPT_TIBETAN,

  HB_SCRIPT_BOPOMOFO,
  HB_SCRIPT_BRAILLE,
  HB_SCRIPT_CANADIAN_SYLLABICS,
  HB_SCRIPT_CHEROKEE,
  HB_SCRIPT_ETHIOPIC,
  HB_SCRIPT_KHMER,
  HB_SCRIPT_MONGOLIAN,
  HB_SCRIPT_MYANMAR,
  HB_SCRIPT_OGHAM,
  HB_SCRIPT_RUNIC,
  HB_SCRIPT_SINHALA,
  HB_SCRIPT_SYRIAC,
  HB_SCRIPT_THAANA,
  HB_SCRIPT_YI,

  HB_SCRIPT_DESERET,
  HB_SCRIPT_GOTHIC,
  HB_SCRIPT_OLD_ITALIC,

  HB_SCRIPT_BUHID,
  HB_SCRIPT_HANUNOO,
  HB_SCRIPT_TAGALOG,
  HB_SCRIPT_TAGBANWA,

  HB_SCRIPT_CYPRIOT,
  HB_SCRIPT_LIMBU,
  HB_SCRIPT_LINEAR_B,
  HB_SCRIPT_OSMANYA,
  HB_SCRIPT_SHAVIAN,
  HB_SCRIPT_TAI_LE,
  HB_SCRIPT_UGARITIC,

  HB_SCRIPT_BUGINESE,
  HB_SCRIPT_COPTIC,
  HB_SCRIPT_GLAGOLITIC,
  HB_SCRIPT_KHAROSHTHI,
  HB_SCRIPT_NEW_TAI_LUE,
  HB_SCRIPT_OLD_PERSIAN,
  HB_SCRIPT_SYLOTI_NAGRI,
  HB_SCRIPT_TIFINAGH,

  HB_SCRIPT_BALINESE,
  HB_SCRIPT_CUNEIFORM,
  HB_SCRIPT_NKO,
  HB_SCRIPT_PHAGS_PA,
  HB_SCRIPT_PHOENICIAN,

  HB_SCRIPT_CARIAN,
  HB_SCRIPT_CHAM,
  HB_SCRIPT_KAYAH_LI,
  HB_SCRIPT_LEPCHA,
  HB_SCRIPT_LYCIAN,
  HB_SCRIPT_LYDIAN,
  HB_SCRIPT_OL_CHIKI,
  HB_SCRIPT_REJANG,
  HB_SCRIPT_SAURASHTRA,
  HB_SCRIPT_SUNDANESE,
  HB_SCRIPT_VAI,

  HB_SCRIPT_AVESTAN,
  HB_SCRIPT_BAMUM,
  HB_SCRIPT_EGYPTIAN_HIEROGLYPHS,
  HB_SCRIPT_IMPERIAL_ARAMAIC,
  HB_SCRIPT_INSCRIPTIONAL_PAHLAVI,
  HB_SCRIPT_INSCRIPTIONAL_PARTHIAN,
  HB_SCRIPT_JAVANESE,
  HB_SCRIPT_KAITHI,
  HB_SCRIPT_LISU,
  HB_SCRIPT_MEETEI_MAYEK,
  HB_SCRIPT_OLD_SOUTH_ARABIAN,
  HB_SCRIPT_OLD_TURKIC,
  HB_SCRIPT_SAMARITAN,
  HB_SCRIPT_TAI_THAM,
  HB_SCRIPT_TAI_VIET,

  HB_SCRIPT_BATAK,
  HB_SCRIPT_BRAHMI,
  HB_SCRIPT_MANDAIC,

  HB_SCRIPT_CHAKMA,
  HB_SCRIPT_MEROITIC_CURSIVE,
  HB_SCRIPT_MEROITIC_HIEROGLYPHS,
  HB_SCRIPT_MIAO,
  HB_SCRIPT_SHARADA,
  HB_SCRIPT_SORA_SOMPENG,
  HB_SCRIPT_TAKRI,

  HB_SCRIPT_BASSA_VAH,
  HB_SCRIPT_CAUCASIAN_ALBANIAN,
  HB_SCRIPT_DUPLOYAN,
  HB_SCRIPT_ELBASAN,
  HB_SCRIPT_GRANTHA,
  HB_SCRIPT_KHOJKI,
  HB_SCRIPT_KHUDAWADI,
  HB_SCRIPT_LINEAR_A,
  HB_SCRIPT_MAHAJANI,
  HB_SCRIPT_MANICHAEAN,
  HB_SCRIPT_MENDE_KIKAKUI,
  HB_SCRIPT_MODI,
  HB_SCRIPT_MRO,
  HB_SCRIPT_NABATAEAN,
  HB_SCRIPT_OLD_NORTH_ARABIAN,
  HB_SCRIPT_OLD_PERMIC,
  HB_SCRIPT_PAHAWH_HMONG,
  HB_SCRIPT_PALMYRENE,
  HB_SCRIPT_PAU_CIN_HAU,
  HB_SCRIPT_PSALTER_PAHLAVI,
  HB_SCRIPT_SIDDHAM,
  HB_SCRIPT_TIRHUTA,
  HB_SCRIPT_WARANG_CITI,

  HB_SCRIPT_AHOM,
  HB_SCRIPT_ANATOLIAN_HIEROGLYPHS,
  HB_SCRIPT_HATRAN,
  HB_SCRIPT_MULTANI,
  HB_SCRIPT_OLD_HUNGARIAN,
  HB_SCRIPT_SIGNWRITING,

  HB_SCRIPT_INVALID,

  _HB_SCRIPT_MAX_VALUE,
  _HB_SCRIPT_MAX_VALUE_SIGNED,

} hb_script_t;

typedef enum {
  HB_DIRECTION_INVALID,
  HB_DIRECTION_LTR,
  HB_DIRECTION_RTL,
  HB_DIRECTION_TTB,
  HB_DIRECTION_BTT
} hb_direction_t;

typedef int hb_bool_t;

typedef uint32_t hb_tag_t;

typedef struct hb_feature_t {
  hb_tag_t      tag;
  uint32_t      value;
  unsigned int  start;
  unsigned int  end;
} hb_feature_t;

typedef struct hb_font_t hb_font_t;

typedef uint32_t hb_codepoint_t;
typedef int32_t hb_position_t;
typedef uint32_t hb_mask_t;

typedef union _hb_var_int_t {
  uint32_t u32;
  int32_t i32;
  uint16_t u16[2];
  int16_t i16[2];
  uint8_t u8[4];
  int8_t i8[4];
} hb_var_int_t;

typedef struct hb_glyph_info_t {
  hb_codepoint_t codepoint;
  hb_mask_t      mask;
  uint32_t       cluster;

  /*< private >*/
  hb_var_int_t   var1;
  hb_var_int_t   var2;
} hb_glyph_info_t;

typedef struct hb_glyph_position_t {
  hb_position_t  x_advance;
  hb_position_t  y_advance;
  hb_position_t  x_offset;
  hb_position_t  y_offset;

  /*< private >*/
  hb_var_int_t   var;
} hb_glyph_position_t;

hb_blob_t *
hb_blob_create (const char        *data,
		unsigned int       length,
		hb_memory_mode_t   mode,
		void              *user_data,
		hb_destroy_func_t  destroy);

void
hb_blob_destroy (hb_blob_t *blob);

hb_face_t *
hb_face_create (hb_blob_t    *blob,
		unsigned int  index);

void
hb_face_destroy (hb_face_t *face);

hb_language_t
hb_language_from_string (const char *str, int len);

void
hb_buffer_set_language (hb_buffer_t   *buffer,
			hb_language_t  language);

hb_script_t
hb_script_from_string (const char *s, int len);

void
hb_buffer_set_script (hb_buffer_t *buffer,
		      hb_script_t  script);

hb_direction_t
hb_direction_from_string (const char *str, int len);

void
hb_buffer_set_direction (hb_buffer_t    *buffer,
			 hb_direction_t  direction);

hb_bool_t
hb_feature_from_string (const char *str, int len,
			hb_feature_t *feature);

hb_bool_t
hb_shape_full (hb_font_t          *font,
	       hb_buffer_t        *buffer,
	       const hb_feature_t *features,
	       unsigned int        num_features,
	       const char * const *shaper_list);

hb_buffer_t *
hb_buffer_create (void);

void
hb_buffer_destroy (hb_buffer_t *buffer);

void
hb_buffer_add_utf8 (hb_buffer_t  *buffer,
		    const char   *text,
		    int           text_length,
		    unsigned int  item_offset,
		    int           item_length);

unsigned int
hb_buffer_get_length (hb_buffer_t *buffer);

hb_glyph_info_t *
hb_buffer_get_glyph_infos (hb_buffer_t  *buffer,
                           unsigned int *length);

hb_glyph_position_t *
hb_buffer_get_glyph_positions (hb_buffer_t  *buffer,
                               unsigned int *length);

void
hb_buffer_reverse (hb_buffer_t *buffer);

void
hb_buffer_guess_segment_properties (hb_buffer_t *buffer);

hb_font_t *
hb_font_create (hb_face_t *face);

void
hb_font_destroy (hb_font_t *font);

void
hb_font_set_scale (hb_font_t *font,
		   int x_scale,
		   int y_scale);

void
hb_ot_font_set_funcs (hb_font_t *font);

unsigned int
hb_face_get_upem (hb_face_t *face);

const char *
hb_version_string (void);
]]

local hb = hb or {}

local harfbuzz = ffi.load(hb_location)
if not harfbuzz then
	return nil
end

hb.Face = hb.Face or {}
local Face = hb.Face
local opts, ftrs = {}, {}

--- Extends Face to accept a file name and optional font index
-- in the constructor.
function Face.new(file, font_index)
	local i = font_index or 0
	local fontfile = assert(io.open(file, "rb"))
	local fontdata = fontfile:read("*all")
	fontfile:close()
	local blob = ffi.gc(harfbuzz.hb_blob_create(fontdata,#fontdata,0,nil,nil), hb_blob_destroy)
	local face = ffi.gc(harfbuzz.hb_face_create(blob,i), hb_face_destroy) 
	return face
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
	local lang, script, dir, features, num_features
	local o = opts[(options.language or "") .. (options.script or "") .. (options.direction or "")]
	if o then
		lang = o.lang
		script = o.script
		dir = o.dir
	else
		lang = options.language
		if lang then
			lang = harfbuzz.hb_language_from_string(lang, #lang)
		end
		script = options.script
		if script then
			script = harfbuzz.hb_script_from_string(script, #script)
		end
		dir = options.direction
		if dir then
			dir = harfbuzz.hb_direction_from_string(dir, #dir)
		end
		opts[(options.language or "") .. (options.script or "") .. (options.direction or "")] = {
			lang = lang,
			script = script,
			dir = dir,
		}
	end
	local f = ftrs[(options.features or "")]
	if f then
		features = f.features
		num_features = f.num_features
	else
		local featurestrings = {}
		features, num_features = nil, 0
		-- Parse features

		if type(options.features) == "string" then
			for fs in string.gmatch(options.features, '([^,]+)') do
				num_features = num_features + 1
				table.insert(featurestrings, fs)
			end
			local feature = ffi.new("hb_feature_t[?]",num_features)
			features = feature[0]
			for i=1,num_features do
				harfbuzz.hb_feature_from_string(featurestrings[i], #featurestrings[i], feature[i-1])
			end
		elseif type(options.features) == "userdata" then
			features = options.features
		elseif options.features then -- non-nil but not a string or userdata
			error("Invalid features option")
		end

		ftrs[(options.language or "") .. (options.script or "") .. (options.direction or "") .. (options.features or "")] = {
			features = features,
			num_features = num_features,
		}
	end
	if lang then harfbuzz.hb_buffer_set_language(buf, lang) end
	if script then harfbuzz.hb_buffer_set_script(buf, script) end
	if dir then harfbuzz.hb_buffer_set_direction(buf, dir) end

	-- Guess segment properties, in case all steps above have failed
	-- to set the right properties.
	buf:guess_segment_properties()

	local shapers = shaper ~= "" and ffi.new("const char *const[?]", 0, {shaper}) or nil

	harfbuzz.hb_shape_full(font, buf, features, num_features, shapers)
end

local Buffer
Buffer_mt = {
	__index = {
		new = function()
			local buf = ffi.gc(harfbuzz.hb_buffer_create(), harfbuzz.hb_buffer_destroy)
			return buf
		end,

		 add_utf8 = function(self, text)
			harfbuzz.hb_buffer_add_utf8(self, text, #text, 0, #text)
		end,

		get_glyph_infos_and_positions = function(self)
			local len = harfbuzz.hb_buffer_get_length(self)
			local info = harfbuzz.hb_buffer_get_glyph_infos(self, nil)
			local pos = harfbuzz.hb_buffer_get_glyph_positions(self, nil)

			local glyphs = {}
			for i=0,len-1 do
				table.insert(glyphs, {
					codepoint = info[i].codepoint,
					mask = info[i].mask,
					cluster = info[i].cluster,
					x_advance = pos[i].x_advance,
					y_advance = pos[i].y_advance,
					x_offset = pos[i].x_offset,
					y_offset = pos[i].y_offset,
				})
			end		
			return glyphs
		end,
		
		reverse = function(self)
			harfbuzz.hb_buffer_reverse(self)
		end,

		guess_segment_properties = function(self)
			harfbuzz.hb_buffer_guess_segment_properties(self)
		end,
	}
}
Buffer = ffi.metatype("hb_buffer_t", Buffer_mt)
hb.Buffer = Buffer

hb.Font = hb.Font or {}
function hb.Font.new(face)
	local font = ffi.gc(harfbuzz.hb_font_create(face), harfbuzz.hb_font_destroy)
	harfbuzz.hb_font_set_scale(font, harfbuzz.hb_face_get_upem(face), harfbuzz.hb_face_get_upem(face))
	harfbuzz.hb_ot_font_set_funcs(font)
	return font
end

function hb.version()
	return ffi.string(harfbuzz.hb_version_string())
end

return hb
