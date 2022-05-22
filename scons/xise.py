################################################################################
# SCons Tool for Xilinx ISE
#
# Copyright (c) 2022 Matt Liss
# BSD-3-Clause
################################################################################
import os
import xml.etree.ElementTree as ET
from SCons.Script import *


class XiseProject(object):
    '''Parse Xilinx ISE Project files'''

    def __init__(self, project_file):
        self.project_file = project_file
        self.namespace = '{http://www.xilinx.com/XMLSchema}'

        tree = ET.parse(project_file)
        self.root = tree.getroot()

    def ns(self, s):
        return self.namespace + s

    def dump_element(self, element):
        print(element.tag, element.attrib)
        for child in element:
            print(child.tag, child.attrib)

    def get_element_attr(self, element, attr):
        return element.attrib[self.ns(attr)]

    def get_file_associations(self, element):
        assoc = []
        for child in element.findall(self.ns('association')):
            assoc.append(child.attrib[self.ns('name')])
        return assoc

    def get_file_list(self, association='Implementation'):
        file_list = []
        for element in self.root.find(self.ns('files')):
            assoc_list = self.get_file_associations(element)
            if (association in assoc_list):
                file_list.append(self.get_element_attr(element, 'name'))
        return file_list

    def get_top(self):
        for prop in self.root.find(self.ns('properties')):
            if self.get_element_attr(prop, 'name') == 'Implementation Top':
                return self.get_element_attr(prop, 'value').split('|')[1]

    def get_work_dir(self):
        for prop in self.root.find(self.ns('properties')):
            if self.get_element_attr(prop, 'name') == 'Working Directory':
                return self.get_element_attr(prop, 'value')


def xise_project(env, project_file):
    proj = XiseProject(project_file)
    top = proj.get_top()
    work = proj.get_work_dir()

    env.Append(TOP_MODULE = top)
    env.Append(BITSTREAM = '{}/{}.bit'.format(work, top))

    sources = proj.get_file_list()
    sources.append(project_file)

    # add rule to build project via tcl script, if present
    tcl = project_file.split('.')[0] + '.tcl'
    if os.path.exists(tcl):
        bitstream = env.Command('$BITSTREAM', sources,
                'xtclsh {} run_process'.format(tcl))
        env.Clean(bitstream, [ work ])
        return bitstream


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

    # find ISE and add path to env for testbenches
    ise = env.WhereIs('ise')
    if ise is None:
        print('ERROR: ISE not found, did you source settingsxx.sh?')
        Exit(1)
    else:
        for i in range(3):
            ise = os.path.dirname(ise)
        env.Append(ISE_PATH = ise)
        if GetOption('verbose'):
            print('ISE_PATH: {}'.format(env['ISE_PATH']))

    # core generator support
    env.PhonyTarget(coregen = 'coregen -p ipcore_dir/coregen.cgp')

    # add ISE project method
    env.AddMethod(xise_project, 'XiseProject')
