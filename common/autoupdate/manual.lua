local fs = require "nixio.fs"
local util = require "luci.util"

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
		if key == wanted then return unquote(value) end
	end
	return nil
end

local function read_env(wanted, fallback)
	return read_env_file("/etc/autoupdate/custom", wanted)
		or read_env_file("/etc/autoupdate/default", wanted)
		or fallback
end

local function clean(value, fallback)
	value = value or ""
	value = value:gsub("\27%[[0-9;]*m", "")
	value = value:gsub("[%c]+", " ")
	value = value:gsub("^%s+", ""):gsub("%s+$", "")
	if value == "" then value = fallback or "" end
	return util.pcdata(value)
end

local local_version = clean(read_env("OP_VERSION", "未知"), "未知")
local cloud_version = clean(fs.readfile("/tmp/Cloud_Version"), "尚未检查")

m = Map("autoupdate", translate("Manually Upgrade"),
	translate("Manually upgrade Firmware or Script")
	.. "<br /><br />autoupdate 脚本随固件维护，不再从上游单独覆盖。")
s = m:section(TypedSection, "autoupdate")
s.anonymous = true

check_updates = s:option(Button, "_check_updates", translate("Check Updates"), translate("Please wait for the page to refresh after clicking Check Updates button"))
check_updates.inputtitle = translate("Check Updates")
check_updates.write = function()
	luci.sys.call([[rm -f /tmp/Cloud_Version /tmp/Cloud_Version.tmp; if autoupdate -V Cloud > /tmp/Cloud_Version.tmp 2>/tmp/autoupdate-check.err; then mv -f /tmp/Cloud_Version.tmp /tmp/Cloud_Version; else printf '%s\n' '检查失败，请查看更新日志' > /tmp/Cloud_Version; fi]])
	luci.http.redirect(luci.dispatcher.build_url("admin", "system", "autoupdate", "manual"))
end

upgrade_fw = s:option(Button, "_upgrade_fw", translate("Upgrade Firmware"),
	translate("Upgrade Normally (KEEP CONFIG)") .. "<br><br>当前固件版本: " .. local_version .. "<br>云端固件版本: " .. cloud_version)
upgrade_fw.inputtitle = translate("Do Upgrade")
upgrade_fw.write = function()
	luci.sys.call("autoupdate -u > /dev/null 2>&1 &")
	luci.http.redirect(luci.dispatcher.build_url("admin", "system", "autoupdate", "log"))
end

upgrade_fw_force = s:option(Button, "_upgrade_fw_force", translate("Upgrade Firmware"), translate("Upgrade with Force Flashing (DANGEROUS)"))
upgrade_fw_force.inputtitle = translate("Do Upgrade")
upgrade_fw_force.write = function()
	luci.sys.call("autoupdate -u -F > /dev/null 2>&1 &")
	luci.http.redirect(luci.dispatcher.build_url("admin", "system", "autoupdate", "log"))
end

upgrade_fw_n = s:option(Button, "_upgrade_fw_n", translate("Upgrade Firmware"), translate("Upgrade without keeping System-Config"))
upgrade_fw_n.inputtitle = translate("Do Upgrade")
upgrade_fw_n.write = function()
	luci.sys.call("autoupdate -u -n > /dev/null 2>&1 &")
	luci.http.redirect(luci.dispatcher.build_url("admin", "system", "autoupdate", "log"))
end

return m
