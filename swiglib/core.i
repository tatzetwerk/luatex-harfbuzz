%module core
#ifdef SWIGLIB_WINDOWS
%include <windows.i>;
#endif


%{
#include "src/hb.h"
#include "src/hb-ot.h"
%}



#ifdef SWIGLIB_WINDOWS
#define __MINGW32__
#endif


#ifndef HB_H
#define HB_H_IN
#endif 

#ifndef HB_EXTERN
#define HB_EXTERN extern
#endif

%ignore hb_buffer_reverse_range;

%include "src/hb-common.h";
%include "src/hb-blob.h";
%include "src/hb-common.h";
%include "src/hb-unicode.h";
%include "src/hb-blob.h";
%include "src/hb-face.h";
%include "src/hb-font.h";
%include "src/hb-buffer.h";
%include "src/hb-unicode.h";
%include "src/hb-font.h";
%include "src/hb-deprecated.h";
%include "src/hb-face.h";
%include "src/hb-font.h";
%include "src/hb-set.h";
%include "src/hb-shape.h";
%include "src/hb-shape-plan.h";
%include "src/hb-unicode.h";
%include "src/hb-version.h";
%include "src/hb.h";

%include "src/hb-ot.h";
%include "src/hb-ot-font.h";


%include "native.i"
%include "inline.i" 
%include "luacode.i" 




%include "carrays.i"
%include "cpointer.i"

%array_functions(hb_glyph_info_t, hb_glyph_info_t_array);
%array_functions(hb_glyph_position_t, hb_glyph_position_t_array);

%pointer_cast(uint32_t, unsigned long int, uint32_t_to_unsigned_long_int);
%pointer_cast(int32_t, long int, int32_t_to_long_int);
