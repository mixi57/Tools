#!/usr/bin/env python
# -*- coding: utf-8 -*- 

import types
class PyDict2LuaTable(object):
    def __init__(self):
        self.out=""
        self.tab="    "
        self.linebreak="\n"
        self.prefix="{"
        self.subfix="}"
        
    def recursive(self, table, deep):
        for key in table.keys():
            value=table[key]
            valueType=type(value)
            if valueType==types.DictType:
                pre=self.tab*deep+"[\""+key+"\"] = {"+self.linebreak
                self.out+=pre
                self.recursive(value, deep+1)
                sub=self.tab*deep+"},"+self.linebreak
                self.out+=sub
            elif valueType==types.IntType or valueType==types.FloatType:
                line=self.tab*deep+"[\""+key+"\"] = "+str(value)+","+self.linebreak
                self.out+=line
            elif valueType==types.StringType:
                line=self.tab*deep+"[\""+key+"\"] = \""+value+"\","+self.linebreak
                self.out+=line
                
    def active(self, table, tabdeep=0, write=False):
        self.out+=self.prefix
        self.recursive(table, tabdeep)
        self.out+=self.subfix
        if write:
            file=open(write, "wb")
            file.write(self.out)
            file.close()