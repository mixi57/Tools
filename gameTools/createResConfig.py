#!/usr/bin/env python
# coding=utf-8

import os
import sys

# 获取基本路径前缀
dir = os.path.abspath(os.path.dirname(__file__))

# 加入pyDict2LuaTable
sys.path.append(os.path.join(dir, "../pyDict2LuaTable"))
from PyDict2LuaTable import PyDict2LuaTable

resourceDir = os.path.join(dir, "../../client/res")
out = os.path.join(dir, "../../client/src/game/Resource/Resources.lua")


# 将img_icon_head 转为 imgIconHead
def path2key(path):
	parts = path.split('_')
	key = ""
	for part in parts:
		if cmp(key, "") == 0:
			key += part
		else:
			key += part.capitalize()
	return key
	
table = {}
# create
def createResConfig():
	for root, subFolders, files in os.walk(resourceDir):
		for fileName in files:
			if fileName[0] == '.':
				continue
			#key = path2key(os.path.basename(fileName))
			# 相对路径
			value = os.path.relpath(os.path.join(root, fileName), resourceDir)
			partInfo = os.path.splitext(fileName)
			# 后缀 格式
			subfix =partInfo[1][1:]
			key = path2key(partInfo[0])
			if not table.has_key(subfix):
				table[subfix] = {}
			subtable = table[subfix]
			subtable[key] = value

def outFile():
	if len(table) == 0:
		print "no value"
		return
	
	#convert to lua table
	converter=PyDict2LuaTable()
	converter.prefix='''local Res = {\n'''
	converter.subfix='''}\nreturn Res'''
	converter.active(table, 1)
	
	file = open(out, 'wb')
	file.write(converter.out)
	file.close()
	
createResConfig()

outFile()