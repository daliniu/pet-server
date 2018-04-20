module(..., package.seeall)

local SensitiveWord = require("modules.public.SensitiveWord")
local Util = require("core.utils.Util")

_sensitiveTree = _sensitiveTree or {}

function init()
	buildSensitiveTree()
end

function buildSensitiveTree()
	local start = os.clock()
	local tab = SensitiveWord.Config
	local wordLen = #tab
	for wordIndex=1,wordLen do
		local word = tab[wordIndex]
		local charTab = Util.utf2tb(word)
		local charLen = #charTab
		local tempTab = _sensitiveTree
		for charIndex=1,charLen do
			local char = charTab[charIndex]
			if tempTab[char] == nil then
				tempTab[char] = {isSensitive = false}
			end
			if charIndex == charLen then
				tempTab[char].isSensitive = true
				tempTab[char].sensitiveWord = word
			end
			tempTab = tempTab[char]
		end
	end
	print("buildSensitiveTree use time = " .. (os.clock() - start))
end

function hasSensitiveWord(str)
	local charTab = Util.utf2tb(str)
	local isSensitive = false
	local t = _sensitiveTree
	for charIndex,char in ipairs(charTab) do
		if t[char] == nil then
			t = _sensitiveTree
		end
		if t[char] ~= nil then
			isSensitive = t[char].isSensitive
			if isSensitive == true then
				break
			end
			t = t[char]
		end
	end
	return isSensitive
end

function filterSensitiveWord(str)
	local charTab = Util.utf2tb(str)
	local retStr = str
	local t = _sensitiveTree
	local start = _USec()
	print("filterSensitiveWord before " .. str)
	for charIndex,char in ipairs(charTab) do
		if t[char] == nil then
			t = _sensitiveTree
		end
		if t[char] ~= nil then
			if t[char].isSensitive == true then
				retStr = string.gsub(retStr, t[char].sensitiveWord, "**")
			end
			t = t[char]
		end
	end
	print("filterSensitiveWord after " .. retStr)
	print("filterSensitiveWord use time = " .. (_USec() - start))
	return retStr
end
