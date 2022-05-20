#
# MicroBlaze MCS SoC for Mojo V3
#
# Copyright (c) 2022 Matt Liss
# BSD-3-Clause
#
import os

env = Environment(ENV = {'PATH': os.environ['PATH']})
Export('env')

# find ISE and add path to env for testbenches
ise = env.WhereIs('ise')
if ise is None:
    print('ERROR: ISE not found, did you source settings.sh?')
    Exit(1)
else:
    for i in range(3):
        ise = os.path.dirname(ise)
    env.Append(ISE_PATH = ise)

# add builders for iverilog simulations
env.Append(BUILDERS = {
    'IVerilogSimulation': Builder(
        action='iverilog -o $TARGET $VINCLUDES $SOURCES',
        suffix='.vvp'),
    'IVerilogWaves': Builder(
        action=['./${SOURCE} > ${SOURCE}.out', '@mv $TARGET.file $TARGET'],
        suffix='.vcd'),
})

# add method to build and run testbenches
def iverilog_testbench(env, target, source):

    bench = env.IVerilogSimulation(target, source)
    waves = env.IVerilogWaves(target, bench)

    outfile = str(bench[0])+'.out'
    SideEffect(outfile, waves)

    Alias('test', [waves, outfile])
    return waves

env.AddMethod(iverilog_testbench, 'IVerilogTestBench')

# TODO write scanner/emmitter to find verilog files required for instantated modules

# invoke subsidiary scripts to collect all testbenches
subdirs = [
    'src/mbiobus',
    'src/peripherals/gcnt',
    'src/peripherals/pdm',
    'src/peripherals/prng',
    'src/util',
]
for subdir in subdirs:
    env.SConscript(dirs=subdir, variant_dir='testbench/'+subdir, duplicate=0)
