premake.modules.pt = {}
local pt = premake.modules.pt

local devnull

if os.get() == 'windows' then
  devnull = 'nul'
else
  devnull = '/dev/null'
end

pt.supported_actions = {
  gmake = {
    build_command = 'make'
  }
}

function pt.commands()
  local action = _ACTION
  if not pt.supported_actions[action] then
    action = 'gmake'
  end
  local premakecmd = string.format('%s %s', _PREMAKE_COMMAND, action)
  local buildcmd = pt.supported_actions[action].build_command

  return string.format('%s > %s 2>&1', premakecmd, devnull),
    string.format('%s > %s 2>&1', buildcmd, devnull)
end

pt.extensions = {
  ['C'] = 'c',
  ['C++'] = 'cpp',
  ['C#'] = 'cs'
}

pt.templates = {
  premake_config = [[
workspace 'pt'
  configurations {'pt'}
  language '%s'

project 'pt'
  kind 'ConsoleApp'
  files 'pt.%s'
]],

  check_include = [[
#include <%s>

int main(void)
{
  return 0;
}
]],

  check_function_exists = [[
char %s();
int main(int argc, char*argv[]){
  %s();
  if(argc> 1000) {
    return *argv[0];
  }
  return 0;
}
]],

  check_type_size = [[
int main(void) {
  printf("%%zu", sizeof(%s));
}
]]
}

function pt.tmpdir()
  -- TODO find a more robust way to create a temporary directory
  local name = os.tmpname()
  os.remove(name)
  os.mkdir(name)
  return name
end

local function writedir(dir, file, contents)
  local f = io.open(path.join(dir, file), 'w')
  f:write(contents)
  f:flush()
  f:close()
end

local function writepremake(dir, lang)
  local cfg = string.format(pt.templates.premake_config, lang,
    pt.extensions[lang])
  writedir(dir, 'premake5.lua', cfg)
end

local function writecode(dir, lang, code)
  local source_file_name = string.format('pt.%s', pt.extensions[lang])
  writedir(dir, source_file_name, code)
end

local function compile(dir, lang, code)
  lang = lang or 'C'
  writepremake(dir, lang)
  writecode(dir, lang, code)
  local premakecmd, buildcmd = pt.commands()
  local cmd = string.format('cd %s && %s && %s', dir, premakecmd, buildcmd)
  return os.execute(cmd)
end

function pt.check_compiles(code, lang)
  local dir = pt.tmpdir()
  local status = compile(dir, lang, code)
  os.rmdir(dir)
  return status == 0
end

function pt.check_stdout(code, lang)
  local dir = pt.tmpdir()
  local status = compile(dir, lang, code)
  local rv
  if status == 0 then
    local binpath = path.join(path.join(path.join(dir, 'bin'), 'pt'), 'pt')
    rv = io.popen(binpath):read('*a')
  end
  os.rmdir(dir)
  return rv
end

function pt.check_include(inc, lang)
  local code = string.format(pt.templates.check_include, inc)
  return pt.check_compiles(code, lang)
end

function pt.check_function_exists(fn, lang)
  local code = string.format(pt.templates.check_function_exists, fn, fn)
  return pt.check_compiles(code, lang)
end

function pt.check_type_size(t, lang)
  local code = string.format(pt.templates.check_type_size, t)
  local out = pt.check_stdout(code, lang)
  if out then
    return tonumber(out)
  end
  return 0
end

return pt
