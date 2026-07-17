local M = {}

local function fail(job, message)
	ya.preview_widget(job, ui.Text(message):area(job.area):wrap(ui.Wrap.YES))
end

local function sidecar(job)
	local source = tostring(job.file.path)
	local base = source:match("^(.*)%.drawio$")
	if not base then
		return nil
	end

	local image = Url(base .. ".png")
	local cha = fs.cha(image)
	return cha and cha.len > 0 and image or nil
end

local function cache(job)
	local base = ya.file_cache({ file = job.file, skip = 0 })
	return base and Url(tostring(base) .. ".png") or nil
end

function M:peek(job)
	local ok, err = self:preload(job)
	if not ok then
		return fail(job, err or "draw.io preview failed")
	end

	local image = sidecar(job) or cache(job)
	if not image or not ya.image_show(image, job.area) then
		fail(job, "draw.io preview failed")
	end
end

function M:preload(job)
	if sidecar(job) then
		return true
	end

	local output = cache(job)
	if not output then
		return false, "Cannot access Yazi cache directory"
	end

	local cha = fs.cha(output)
	if cha and cha.len > 0 then
		return true
	end

	local result, err = Command("drawio")
		:arg({
			"--export",
			"--format",
			"png",
			"--disable-update",
			"--output",
			tostring(output),
			tostring(job.file.path),
		})
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	if not result then
		return false, "drawio: " .. tostring(err)
	end

	cha = fs.cha(output)
	if cha and cha.len > 0 then
		return true
	end

	local stderr = tostring(result.stderr or ""):gsub("%s+$", "")
	return false, stderr ~= "" and stderr or "draw.io export failed"
end

return M
