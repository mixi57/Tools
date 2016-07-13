#!/usr/bin/env python
# coding=utf-8

import os
import sys
import lupa

# 获取基本路径前缀
dir = os.path.abspath(os.path.dirname(__file__))

# xmlParams
LUA_REQUIRE_DIR = os.path.join(dir, "../xml2Table")
lua = lupa.LuaRuntime()
lua.execute("package.path = package.path .. \";\" ..\"%s/?.lua\"" % LUA_REQUIRE_DIR)
XMLParsers = lua.require('XMLParsers')

# 配置表xml-->lua，生成在临时目录
def convertConfig(configSrc, configTempOutPut):
	for f in os.listdir(configSrc):
		fs = f.split(".")
		if len(fs) > 1 and fs[1] == "xml":
			# print f
			XMLParsers.loadFile(
				os.path.join(configSrc, f), 
				configTempOutPut
			)

configSrc = os.path.join(dir, "../../public/配置表")
configTempOutPut = os.path.join(dir, "../../client/src/game/Resource/config/config")
convertConfig(configSrc, configTempOutPut)
