################################################################################
# SCons Tool for Mojo V3 FPGA Board
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

    # mojo loader support
    mojocom = 'mojo.py -d $MOJO_PORT -i $BITSTREAM -p'
    if GetOption('verbose'):
        mojocom += ' -v'
    env.Append(MOJOCOM = mojocom)

    env.Depends(env.PhonyTarget(
            ramload = '$MOJOCOM -r',
            flash = '$MOJOCOM'),
            '$BITSTREAM')
