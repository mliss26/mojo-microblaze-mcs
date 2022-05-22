################################################################################
# General SCons Helper Utilities
#
# Copyright (c) 2022 Matt Liss
# BSD-3-Clause
################################################################################
from SCons.Script import *

def phony_target(env, **kw):
    aliases = []

    for target, action in kw.items():
        aliases.append(env.Alias(target, [], action))

    env.AlwaysBuild(aliases)
    return aliases

def exists(env):
    exist = True
    #print('{}.exists(): {}'.format(os.path.basename(__file__).rstrip('.py'), exist))
    return exist

def generate(env):
    '''Add Builders and construction variables to the environment.'''

    #print('{}.generate()'.format(os.path.basename(__file__).rstrip('.py')))

    # support verbose option and pretty print output when not supplied
    AddOption('--verbose', action='store_true', default=False, help="verbose output")

    if not GetOption('verbose'):
        env.Replace(CCCOMSTR      = 'Compiling  $SOURCE')
        env.Replace(CXXCOMSTR     = 'Compiling  $SOURCE')
        env.Replace(ASCOMSTR      = 'Assembling $SOURCE')
        env.Replace(ARCOMSTR      = 'Archiving  $TARGET')
        env.Replace(RANLIBCOMSTR  = 'Indexing   $TARGET')
        env.Replace(LINKCOMSTR    = 'Linking    $TARGET')
        env.Replace(GENHDRCOMSTR  = 'Generating $TARGET')
        env.Replace(PKGSRCCOMSTR  = 'Packaging  $TARGET')
        env.Replace(OBJCOPYCOMSTR = 'Objcopy    $TARGET')
        env.Replace(SIZECOMSTR    = 'Object Sizes:')

    # linker verbose option
    AddOption('--lverbose', action='store_true', default=False, help="verbose linker output")

    if GetOption('lverbose'):
        env.Append(LINKFLAGS = '-Wl,--verbose')

    # add command line build environment overrides
    arg_overrides = ['CC', 'GCC', 'CPP', 'CXX', 'AS', 'AR', 'LD', 'RANLIB', 'NM',
                     'OBJDUMP', 'OBJCOPY', 'READELF', 'STRIP',
                     'CFLAGS', 'CPPFLAGS', 'CXXFLAGS', 'LDFLAGS',
                     'PATH']

    for arg in arg_overrides:
        if arg in ARGUMENTS:
            env[arg] = ARGUMENTS[arg]
            if GetOption('verbose'):
                print('using %s=%s' % (arg, ARGUMENTS[arg]))

    # add method for creating phony targets
    env.AddMethod(phony_target, 'PhonyTarget')
