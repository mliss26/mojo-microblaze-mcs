#
# MicroBlaze MCS SoC for Mojo V3
#
# Copyright (c) 2022 Matt Liss
# BSD-3-Clause
#
import os

# setup scons env and export for SConscripts
env = Environment(
        ENV = { 'PATH': os.environ['PATH'],
                'HOME': os.environ['HOME'],
                'DISPLAY': os.environ['DISPLAY'] },
        toolpath = ['scons'],
        tools = ['iverilog', 'mojo', 'xise'])
Export('env')

# invoke subsidiary scripts to collect all testbenches
subdirs = [
    'src/mbiobus',
    'src/memory/sdram',
    'src/peripherals/gcnt',
    'src/peripherals/i2cm',
    'src/peripherals/pdm',
    'src/peripherals/prng',
    'src/util',
# takes ~6hrs to run top simulation - disable by default
# TODO add option
#    'src',
]
for subdir in subdirs:
    env.SConscript(dirs=subdir, variant_dir='testbench/'+subdir, duplicate=0)
env.VariantDir('testbench/src/opencores/i2c/rtl/verilog', 'src/opencores/i2c/rtl/verilog', duplicate=0)

# setup env for flashing mojo
env.Append(MOJO_PORT = '/dev/ttyACM1')

env.Default(env.XiseProject('mojo-microblaze-mcs.xise'))
