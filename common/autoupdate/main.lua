local fs = require "nixio.fs"

local function unquote(value)
	if not value then return nil end
	value = value:gsub("^%s+", ""):gsub("%s+$", "")
	local first = value:sub(1, 1)
	local last = value:sub(-1)
	if (#value >= 2) and ((first == '"' and last == '"') or (first == "'" and last == "'")) then
		value = value:sub(2, -2)
	end
	return value
end

local function read_env_file(path, wanted)
	local data = fs.readfile(path)
	if not data then return nil end
	for line in data:gmatch("[^\r\n]+") do
		local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
		if key == wanted then
			return unquote(value)
		end
	end
	return nil
end

local function read_env(wanted, fallback)
	return read_env_file("/etc/autoupdate/custom", wanted)
		or read_env_file("/etc/autoupdate/default", wanted)
		or fallback
end

m = Map("autoupdate", translate("AutoUpdate"),
	translate("AutoUpdate LUCI supports scheduled upgrade & one-click firmware upgrade")
	.. "<br /><br />GitHub 直连模式，页面配置直接读取本地环境文件。")

s = m:section(TypedSection, "autoupdate")
s.anonymous = true

local default_url = read_env("Github", "")
local default_flag = read_env("TARGET_FLAG", "")
local default_logpath = read_env("Log_Path", "/tmp")

enable = s:option(Flag, "enable", translate("Enable"), translate("Automatically update firmware during the specified time when Enabled"))
enable.default = 0
enable.optional = false

advanced = s:option(Flag, "advanced", translate("Advanced Settings"))
advanced.default = 0
advanced:depends("enable", "1")

advanced_settings = s:option(MultiValue, "advanced_settings", translate("Advanced Settings"), translate("Supported Multi Selection"))
advanced_settings:value("--skip-verify", translate("Skip SHA256 Verify"))
advanced_settings:value("-F", translate("Force Flash Firmware"))
advanced_settings:value("--decompress", translate("Decompress [img.gz] Firmware"))
advanced_settings:value("-n", translate("Upgrade without keeping config"))
advanced_settings:depends("advanced", "1")
advanced.description = translate("Please don't select it unless you know what you're doing!")

week = s:option(ListValue, "week", translate("Update Day"), translate("Recommend to set the AUTOUPDATE time to an uncommon time"))
week:value(7, translate("Everyday"))
week:value(1, translate("Monday"))
week:value(2, translate("Tuesday"))
week:value(3, translate("Wednesday"))
week:value(4, translate("Thursday"))
week:value(5, translate("Friday"))
week:value(6, translate("Saturday"))
week:value(0, translate("Sunday"))
week.default = 0
week:depends("enable", "1")

hour = s:option(Value, "hour", translate("Hour"))
hour.datatype = "range(0,23)"
hour.rmempty = true
hour.default = 0
hour:depends("enable", "1")

minute = s:option(Value, "minute", translate("Minute"))
minute.datatype = "range(0,59)"
minute.rmempty = true
minute.default = 30
minute:depends("enable", "1")

github = s:option(Value, "github", translate("Github Url"), translate("For detecting cloud version and downloading firmware"))
github.default = default_url
github.rmempty = false

flag = s:option(Value, "flag", translate("Firmware Flag"))
flag.default = default_flag
flag.rmempty = false

logpath = s:option(Value, "logpath", translate("Log Path"))
logpath.default = default_logpath
logpath.rmempty = false

return m
