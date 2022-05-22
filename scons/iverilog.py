################################################################################
# SCons Tool for Icarus Verilog
#
# Copyright (c) 2022 Matt Liss
# BSD-3-Clause
################################################################################
import os
from SCons.Script import *

def exists(env):
    exist = True
    #print('{}.exists(): {}'.format(os.path.basename(__file__).rstrip('.py'), exist))
    return exist

def generate(env):
    '''Add Builders and construction variables to the environment.'''
    #print('{}.generate()'.format(os.path.basename(__file__).rstrip('.py')))

    if 'default' not in env['TOOLS']:
        env.Tool('default')

    if 'utils' not in env['TOOLS']:
        env.Tool('utils')

    # add builders for iverilog simulations
    if GetOption('verbose'):
        testbench_action = ['./${SOURCE} | tee ${SOURCE}.out', 'mv $TARGET.file $TARGET']
    else:
        testbench_action = ['./${SOURCE} > ${SOURCE}.out', '@mv $TARGET.file $TARGET']

    env.Append(BUILDERS = {
        'IVerilogSimulation': Builder(
            action='iverilog -o $TARGET $VINCLUDES $SOURCES',
            suffix='.vvp'),
        'IVerilogWaves': Builder(
            action=testbench_action,
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
