## Perform platform tests with premake

This module implements utility functions to perform platform tests right in your
premake5.lua.

To use it, simply install this module somewhere premake can find it. One way is
to add it as a submodule of your premake project:

```
git submodule add https://github.com/tarruda/premake-platform-test platform-test
```

Then require it on the top of your premake5.lua

```lua
local pt = require "platform-test"
```

The `pt` object contains a number of functions to perform certain platform
checks that can affect your compilation:

```lua
local integer_sizes = {
  SHORT = pt.check_type_size('short'),
  INT = pt.check_type_size('int'),
  LONG = pt.check_type_size('long')
}

local includes = {
  UNISTD = pt.check_include('unistd.h'),
  STDINT = pt.check_include('stdint.h'),
  STDBOOL = pt.check_include('stdbool.h')
}

local functions = {
  MEMRCHR = pt.check_function_exists('memrchr')
}

local defs = {}
for k, v in pairs(integer_sizes) do
  table.insert(defs, string.format('SIZEOF_%s=%d', k, v))
end
for k, v in pairs(includes) do
  table.insert(defs, string.format('HAVE_%s_H', k))
end
for k, v in pairs(functions) do
  table.insert(defs, string.format('HAVE_%s', k))
end

workspace "MyWorkspace"
  configurations { "Debug", "Release" }
  location "build"
  defines(defs)

project "MyProject"
  location "build/MyProject"
```

Then in your code you can do things like:

```c
#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif
```

The number of builtin checks is very limited when compared to the ones available
in cmake/autoconf, but the underlying compilation/execution infrastructure is
exposed so you can perform arbitrary checks:

```lua
print(pt.check_compiles('int main(){}')) -- true
print(pt.check_compiles('int main(){')) -- false
print(pt.check_stdout('int main(){printf("hi");}')) -- hi
```

Most functions can receive a "lang" second argument to build using the
right compiler.

Besides invoking the `check_compiles`/`check_stdout` to perform arbitrary
checks, it is also possible to override the internal functions and templates
used by this module. See the source code for more information.

If you want to add more builtin checks, feel free to send a PR. 
