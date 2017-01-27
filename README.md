# _luatex-harfbuzz_

[HarfBuzz] as OpenType engine in [LuaTeX], [LaTeX], and [ConTeXt]

[Harfbuzz]:http://harfbuzz.org
[LuaTeX]:http://www.luatex.org
[LaTeX]:https://www.latex-project.org
[ConTeXt]:http://wiki.contextgarden.net

## Contents

* [Overview](#overview)
* [Quick results via FFI](#quick-results-via-ffi)
* [SwigLib bindings](#swiglib-bindings)
* [Contact](#contact)

## Overview

#### HarfBuzz
HarfBuzz is an OpenType text shaping engine used in software like Firefox, Chromium, XeTeX, and LibreOffice.

#### LuaTeX, LuaLaTeX, and ConTeXt
LuaTeX is a version of TeX that uses Lua as an embedded scripting language. Via the use of Lua scripts the TeX functionality can be extended in various ways, for example with respect to the rendering of OpenType fonts.

#### _Luatex-harfbuzz_ as alternative rendering engine
LuaTex, LuaLaTeX, and ConTeXt already have a powerful rendering engine at their disposal, namely the ConTeXt OpenType engine, which is able to handle many different font features and scripts. _Luatex-harfbuzz_ provides the use of HarfBuzz as alternative rendering engine.

The approach chosen is a hybrid one in which much of the processes – except the actual rendering, which is done by HarfBuzz – relies on ConTeXt code that is already at hand in LuaTex, LuaLaTeX, and ConTeXt.

#### Installing and using _Luatex-harfbuzz_
There are several ways of installing and using _luatex-harfbuzz_. Binding HarfBuzz to LuaTex can be done via [FFI] and via [SwigLib]. The route via FFI is much more simple because it only involves installing HarfBuzz whereas the route via SwigLib also involves compiling libraries and (in the case of Mac OS X) recompiling LuaTeX. Quick results can therefore be obtained via FFI. However, the use of FFI is sometimes advised against because of security risks.

[FFI]:http://luajit.org/ext_ffi.html
[SwigLib]:http://www.luatex.org/swiglib.html

#### Feel free to add
This reference is written for the use of _luatex-harfbuzz_ on Mac OS X. In principle, however, the approach should also work on other platforms. Please feel free to add instructions for other platforms.

In principle, the applied method is not restricted to the HarfBuzz engine. Please feel free to add materials for other OpenType engines (such as graphite2, which is also available in Homebrew).

## Quick results via FFI

#### Install MacTeX 2016, Homebrew, and HarfBuzz

Download MacTeX.pkg (2016) from http://www.tug.org/mactex/mactex-download.html and run the installer. When asked, also install the Mac OS X command line developer tools.

Install Homebrew:
```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Install HarfBuzz (the result is /usr/local/Cellar/harfbuzz/1.4.1/lib/libharfbuzz.0.dylib):
```
brew install harfbuzz
```

#### Prepare LuaJitLaTeX
MacTeX 2016 does not create a luajitlatex executable and its accompanying format file. These can be created manually:
```
cd /usr/local/texlive/2016/texmf-var/web2c/luajittex/
sudo luajittex -ini -jobname=luajitlatex \* lualatex.ini
cd /usr/local/texlive/2016/bin/x86_64-darwin
sudo ln -s luajittex luajitlatex
sudo texhash
```

#### Test FFI
Now _luatex-harfbuzz_ should already work via FFI, which can be tested by means of the example files in the luatex-harfbuzz folder. FFI requires that LuaTeX, LuaLaTeX, and ConTeXt are executed using [JIT]:

[JIT]:http://luajit.org/luajit.html

```
luajittex example-luatex-ffi
luajitlatex example-lualatex-ffi
context --jit example-context-ffi
```
Note that the ConTeXt OpenType engine engine is in constant development and that the version installed by means of MacTeX 2016 is not the most recent one. For a fair comparison between the ConTeXt OpenType engine and HarfBuzz, a recent beta version should be used.

The ConTeXt OpenType engine can be updated by updating ConTeXt. For instructions, see the manual of [luatools]. (This manual is also helpful for tackling problems related to running ConTeXt.)

[luatools]:http://www.pragma-ade.com/general/manuals/tools-mkiv.pdf

Additionaly, for LuaLaTeX the luaotfload package can be updated, for instance by means of the [TeX Live Utility].

[TeX Live Utility]:http://tex.stackexchange.com/questions/55437/how-do-i-update-my-tex-distribution/55438#55438

## SwigLib bindings
Alternative to the FFI route, binding HarfBuzz to LuaTex can also be done via SwigLib. This involves:
* Installing MacTeX 2016, Homebrew, and HarfBuzz
* In the case of Mac OS X: compiling LuaTeX with the --nostrip flag
* Compiling libraries

#### Install MacTeX 2016, Homebrew, and HarfBuzz
See above.

#### Compile no-stripped LuaTeX in Mac OS X
The distributed LuaTeX for Mac OS X is compiled in such a way that all the symbols are stripped out of the binary. Therefore, dynamically linked .so libraries can’t locate the symbols they need. In order to bind HarfBuzz via SwigLib it is required to compile a LuaTeX binary from SVN and build it with the --nostrip flag, and then replace the existing LuaTeX binary with the new binary (see: [http://tex.stackexchange.com/questions/278329/symbol-not-found-error-when-using-lua-c-so-module-with-lualatex]).

[http://tex.stackexchange.com/questions/278329/symbol-not-found-error-when-using-lua-c-so-module-with-lualatex]:http://tex.stackexchange.com/questions/278329/symbol-not-found-error-when-using-lua-c-so-module-with-lualatex

Download LuaTeX in a temporary folder from https://foundry.supelec.fr/svn/luatex/trunk (password = anonsvn):
```
svn checkout --username anonsvn https://foundry.supelec.fr/svn/luatex/trunk
```

Install LuaTeX (and immediately also LuaJitTeX) in the downloaded trunk folder (compiling LuaTeX requires Xcode Command Line Tools and pkg-config which are already installed during the installation of MacTeX 2016):
```
./build.sh --jit --nostrip
```

Place luatex and luajittex (to be found in trunk/build/texk/web2c) in /usr/local/texlive/2016/bin/x86\_64-darwin (as a precautionary measure keep the old versions as luatex\_old and luajittex\_old):

Create format-file for luatex:
```
cd /usr/local/texlive/2016/texmf-var/web2c/luatex/
sudo luatex -ini -jobname=luatex \* luatex.ini
```

Create format-file for luajittex:
```
cd /usr/local/texlive/2016/texmf-var/web2c/luajittex/
sudo luajittex -ini -jobname=luajittex \* luatex.ini
```

Create format-file for lualatex: 
```
cd /usr/local/texlive/2016/texmf-var/web2c/luatex/
sudo luatex -ini -jobname=lualatex \* lualatex.ini
```

Create format-file for lualatex: 
```
cd /usr/local/texlive/2016/texmf-var/web2c/luajittex/
sudo luajittex -ini -jobname=luajitlatex \* lualatex.ini
```

Create new symlinks for lualatex and luajitlatex (as a precautionary measure keep the keep old versions as lualatex\_old and luajitlatex\_old):
```
cd /usr/local/texlive/2016/bin/x86_64-darwin
sudo ln -s luatex lualatex
sudo ln -s luajittex luajitlatex
```

Run texhash:
```
sudo texhash
```

#### Compile libraries
The route via SwigLib requires the compilation of libraries (i.e. .so files on Mac OS X or .dll files on MS Windows). In what follows, two approaches are described to build .so files. The first is [luaharfbuzz], which is developed by Deepak Jois. The second, more complicated approach is more in line with the SwigLib project and is based upon example code by Luigi Scarso (altough several adjustments were necessary to have that code work with HarfBuzz). This approach requires the files in the swiglib folder.

[luaharfbuzz]:https://github.com/deepakjois/luaharfbuzz

###### luaharfbuzz
Install Lua:
```
brew install lua
```

Install luaharfbuzz:
```
sudo luarocks install luaharfbuzz
```

Create the folder lib/luatex/lua/swiglib/hb\_deepak/luaharfbuzz\_0\_0\_7-0/ in /usr/local/texlive/2016/bin/x86\_64-darwin/ and copy the generated luaharfbuzz.so (in /usr/local/lib/lua/5.2) to that folder.

###### Test luaharfbuzz
Now _luatex-harfbuzz_ should work via luaharfbuzz, which can be tested by means of the example files in the luatex-harfbuzz folder:
```
luatex example-luatex-swig-dj
lualatex example-lualatex-swig-dj
context example-context-swig-dj
```

###### SwigLib
Install Lua (if not already done during installation of _luaharfbuzz_):
```
brew install lua 
```

Install swig:
```
brew install swig
```

Download the tarball release of HarfBuzz from https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.4.1.tar.bz2

Move the src folder to the swiglib folder in which the .so file will be build (this is the folder that, amongst others, contains core.i).

Build swiglib-harfbuzz.so (if during this process lua.h is not found, it might help to (re)install Xcode Command Line Tools by means of "xcode-select --install"):
```
swig -cpperraswarn -c++ -lua core.i
make
```

Rename the generated swiglib-harfbuzz.so to core.so

Create the folder lib/luatex/lua/swiglib/hb/harfbuzz\_1\_4\_1/ in /usr/local/texlive/2016/bin/x86\_64-darwin/ and copy the generated core.so to that folder.

###### Test SwigLib
Now _luatex-harfbuzz_ should work via the SwigLib binding of core.so, which can be tested by means of the example files in the luatex-harfbuzz folder:
```
luatex example-luatex-swig
lualatex example-lualatex-swig
context example-context-swig
```

## Contact
Kai Eigner  
[TAT Zetwerk]  
<eigner@tatzetwerk.nl>

[TAT Zetwerk]:http://www.tatzetwerk.nl

