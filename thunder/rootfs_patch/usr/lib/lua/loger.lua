module(..., package.seeall)

local function show_debug_info(info)
	print('source:', info.source)
	print('what:', info.what)
	print('func:', info.func)
	print('nups:', info.nups)
	print('short_src:', info.short_src)
	print('name:', info.name)
	print('currentline:', info.currentline)
	print('namewhat:', info.namewhat)
	print('linedefined:', info.linedefined)
	print('lastlinedefined:', info.lastlinedefined)
end

local loger_level = {DEBUG = 1, TRACE = 2, INFO = 3, WARN = 4, ERROR = 5}

function new(level, out, file)
	local obj = {level = level or 'DEBUG', file = file, f = nil, out = out or 1}

	function obj:set_out(out) self.out = out end
	function obj:set_level(level) self.level = level end
	function obj:get_level() return self.level end

	function obj:log(level, str)
		if self.out == 0 and not self.f then print('no msg'); return end
		local d_info = debug.getinfo(3, 'nl')
		d_info.name = d_info.name or 'main'
		local d_str = string.format('[%s()-%s: %s] %s\n', d_info.name, d_info.currentline, level, str)
		if self.out > 0 then
			--show_debug_info(d_info)
			io.stdout:write(d_str)
		end

		if self.f then self.f:write(d_str); self.f:flush() end
	end

	function obj:debug(fmt, ...)
		if loger_level[self.level] <= loger_level['DEBUG'] then
			return self:log('DEBUG', string.format(fmt, ...))
		end
	end

	function obj:trace(fmt, ...)
		if loger_level[self.level] <= loger_level['TRACE'] then
			return obj:log('TRACE', string.format(fmt, ...))
		end
	end

	function obj:info(fmt, ...)
		if loger_level[self.level] <= loger_level['INFO'] then
			return obj:log('INFO', string.format(fmt, ...))
		end
	end

	function obj:warn(fmt, ...)
		if loger_level[self.level] <= loger_level['WARN'] then
			return obj:log('WARN', string.format(fmt, ...))
		end
	end

	function obj:error(fmt, ...)
		if loger_level[self.level] <= loger_level['ERROR'] then
			return obj:log('ERROR', string.format(fmt, ...))
		end
	end

	if file then
		obj.f = assert(io.open(file, "w")) 
	end
	return obj
end

return _M
