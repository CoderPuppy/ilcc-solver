local hex = {
	a = 10;
	b = 11;
	c = 12;
	d = 13;
	e = 14;
	f = 15;
}
for i = 0,9 do
	hex[tostring(i)] = i
end
for k, v in pairs(hex) do
	hex[v] = k
end

local types = {
	{
		variants = {
			{
				name = 'empty';
				display = '\128\128\128|000|000\n\128\128\128|000|000';
				connections = {};
			};
		};
	};
	{
		variants = {
			{
				name = 'up';
				display = "\151\143\148|0ff|f00\n\138\140\133|fff|000";
				connections = {up = true};
			};
			{
				name = 'right';
				display = "\151\140\139|0f0|f0f\n\138\140\135|fff|000";
				connections = {right = true};
			};
			{
				name = 'down';
				display = "\151\140\148|0ff|f00\n\138\131\133|f0f|0f0";
				connections = {down = true};
			};
			{
				name = 'left';
				display = "\135\140\148|0ff|f00\n\139\140\133|fff|000";
				connections = {left = true};
			};
		};
	};
	{
		variants = {
			{
				name = 'ur';
				display = "\151\143\139|0f0|f0f\n\138\140\135|fff|000";
				connections = {up = true; right = true};
			};
			{
				name = 'rd';
				display = "\151\140\139|0f0|f0f\n\138\131\135|f0f|0f0";
				connections = {right = true; down = true};
			};
			{
				name = 'dl';
				display = "\135\140\148|0ff|f00\n\139\131\133|f0f|0f0";
				connections = {down = true; left = true};
			};
			{
				name = 'lu';
				display = "\135\143\148|0ff|f00\n\139\140\133|fff|000";
				connections = {left = true; up = true};
			};
		};
	};
	{
		variants = {
			{
				name = 'v';
				display = "\128\128\128|f0f|0f0\n\128\128\128|f0f|0f0";
				connections = {up = true; down = true};
			};
			{
				name = 'h';
				display = "\143\143\143|000|fff\n\131\131\131|fff|000";
				connections = {left = true; right = true};
			};
		};
	};
	{
		variants = {
			{
				name = 'tu';
				display = "\135\143\139|0f0|f0f\n\139\140\135|fff|000";
				connections = {left = true; up = true; right = true};
			};
			{
				name = 'tr';
				display = "\151\143\139|0f0|f0f\n\138\131\135|f0f|0f0";
				connections = {up=true; right=true; down=true};
			};
			{
				name = 'td';
				display = "\135\140\139|0f0|f0f\n\139\131\135|f0f|0f0";
				connections = {right=true; down=true; left=true};
			};
			{
				name = 'tl';
				display = "\135\143\148|0ff|f00\n\139\131\133|f0f|0f0";
				connections = {down=true; left=true; up=true};
			};
		};
	};
	{
		variants = {
			{
				name = 'q';
				display = "\135\143\139|0f0|f0f\n\139\131\135|f0f|0f0";
				connections = {up = true; right = true; down = true; left = true};
			};
		};
	};
}
types.lookup = {}
do
	local i = 0
	for _, typ in ipairs(types) do
		for _, var in ipairs(typ.variants) do
			var.type = typ
			local key =
				(var.connections.up and 'T' or 'F') ..
				(var.connections.right and 'T' or 'F') ..
				(var.connections.down and 'T' or 'F') ..
				(var.connections.left and 'T' or 'F')
			types.lookup[key] = var
			var.conn_key = key

			var.char = ('%x'):format(i)
			types.lookup[var.char] = var

			i = i + 1
		end
	end
end

local function P(x, y)
	return ('%d-%d'):format(x, y)
end

local function offset(dir)
	if dir == 'up' then
		return 0, -1
	elseif dir == 'right' then
		return 1, 0
	elseif dir == 'down' then
		return 0, 1
	elseif dir == 'left' then
		return -1, 0
	else
		error('bad dir')
	end
end

local function opposite(dir)
	if dir == 'up' then
		return 'down'
	elseif dir == 'right' then
		return 'left'
	elseif dir == 'down' then
		return 'up'
	elseif dir == 'left' then
		return 'right'
	else
		error('bad dir')
	end
end

local function parse(data)
	local grid = {}
	local w = 0
	local x, y = 1, 1
	for line in data:gmatch '([^\r\n]+)' do
		x = 1
		for char in line:gmatch '.' do
			grid[x] = grid[x] or {}
			grid[x][y] = types.lookup[char]
			x = x + 1
		end
		w = math.max(w, x - 1)
		y = y + 1
	end
	h = y - 1
	grid.w = w
	grid.h = h
	return grid
end

local function process_color(c, f, b)
	return c:gsub('[f0]', function(s)
		if s == '0' then
			return b
		else
			return f
		end
	end)
end

local function render(disp, f, b)
	local x, y = term.getCursorPos()
	local upper, lower = disp:match '^([^\n]+)\n(.+)$'
	local text, fg, bg = upper:match '^(.-)|(.-)|(.+)$'
	term.blit(text, process_color(fg, f, b), process_color(bg, f, b))
	term.setCursorPos(x, y + 1)
	local text, fg, bg = lower:match '^(.-)|(.-)|(.+)$'
	term.blit(text, process_color(fg, f, b), process_color(bg, f, b))
	term.setCursorPos(x, y)
end

local function render_dirs(c)
	local x, y = term.getCursorPos()
	term.blit('\143\143\143', c.tl .. c.tm .. c.tr, c.ml .. c.mm .. c.mr)
	term.setCursorPos(x, y + 1)
	term.blit('\131\131\131', c.ml .. c.mm .. c.mr, c.bl .. c.bm .. c.br)
	term.setCursorPos(x, y)
end

local grid
do
	local h = fs.open('inflooplevels/supernicejohn/2', 'r')
	grid = parse(h.readAll())
	h.close()
end

local data = setmetatable({}, {
	__index = function(t, k)
		local t_ = {}
		t[k] = t_
		return t_
	end;
})
local to_check = {}
local really_done = {}

local render_data
do
	local function render_con(v, d)
		if d == 'T' then
			return 'f' -- black
		elseif d == 'F' then
			return '0' -- white
		else
			return '8'
		end

		-- if v then
		-- 	if d == 'T' then
		-- 		return '5' -- lime
		-- 	elseif d == 'F' then
		-- 		return 'c' -- brown
		-- 	else
		-- 		return 'd' -- green
		-- 	end
		-- else
		-- 	if d == 'T' then
		-- 		return '1' -- orange
		-- 	elseif d == 'F' then
		-- 		return 'e' -- red
		-- 	else
		-- 		return 'a' -- purple
		-- 	end
		-- end
	end

	function render_data(x, y)
		local var = grid[x][y]
		local d = data[P(x, y)]

		return {
			tl = '0';
			tr = '0';
			bl = '0';
			br = '0';

			tm = render_con(var.connections.up, d.up);
			mr = render_con(var.connections.right, d.right);
			bm = render_con(var.connections.down, d.down);
			ml = render_con(var.connections.left, d.left);

			mm = '7'; -- black
				-- to_check[P(x, y)] and '2' or -- orange
				-- really_done[P(x, y)] and 'd' or -- green
				-- '7'; -- gray
		}
	end
end

local co = coroutine.create(function()
	local dirty = {}
	local function mark_dirty(x, y)
		if x <= 0 or x > grid.w or y <= 0 or y > grid.h then
			return
		end

		dirty[P(x, y)] = {x, y}
	end

	local function mark_check(x, y)
		if x <= 0 or x > grid.w or y <= 0 or y > grid.h then
			return
		end

		local k = P(x, y)
		if not really_done[k] then
			to_check[k] = {x, y}

			mark_dirty(x, y)
		end
	end

	local function compatible(...)
		local cur = nil
		for i = 1, select('#', ...) do
			local v = select(i, ...)
			if cur ~= nil and v ~= nil and cur ~= v then
				return false
			end
			cur = cur or v
		end
		return true
	end

	local apply
	do
		local function do_apply(x, y, dir, v)
			-- print('  apply', x, y, dir, v)

			local d = data[P(x, y)]
			if not compatible(d[dir], v) then
				error(('mismatch between fixed links at (%d %d) %s have %s applying %s'):format(x, y, dir, d[dir], v))
			end
			d[dir] = v

			mark_dirty(x, y)
		end

		function apply(x, y, dir, v)
			if v == nil then return end

			do_apply(x, y, dir, v)

			local ox, oy = offset(dir)
			local odir = opposite(dir)
			local od = data[P(x + ox, y + oy)]

			do_apply(x + ox, y + oy, odir, v)

			mark_check(x + ox, y + oy)
		end
	end

	local function apply_var(x, y, var)
		apply(x, y, 'up'   , var.connections.up    and 'T' or 'F')
		apply(x, y, 'right', var.connections.right and 'T' or 'F')
		apply(x, y, 'down' , var.connections.down  and 'T' or 'F')
		apply(x, y, 'left' , var.connections.left  and 'T' or 'F')
	end

	for x = 1, grid.w do
		mark_check(x, 1)
		-- print('top row', x, 1)
		apply(x, 1, 'up', 'F')

		mark_check(x, grid.h)
		-- print('bottom row', x, grid.h)
		apply(x, grid.h, 'down', 'F')
	end

	for y = 1, grid.h do
		mark_check(1, y)
		-- print('left col', 1, y)
		apply(1, y, 'left', 'F')

		mark_check(grid.w, y)
		-- print('right col', grid.w, y)
		apply(grid.w, y, 'right', 'F')
	end

	while true do
		for pk, p in pairs(dirty) do
			term.setCursorPos(p[1] * 3 - 2, p[2] * 2 - 1)
			render_dirs(render_data(p[1], p[2]))
		end
		dirty = {}

		coroutine.yield()

		local finished = {}
		local any = false
		for pk, p in pairs(to_check) do
			any = true

			local typ = grid[p[1]][p[2]].type
			local d = data[pk]

			local possible = {}

			-- print('check', p[1], p[2])
			for _, var in ipairs(typ.variants) do
				-- print('try', var.name, var.conn_key)
				if
					compatible(d.up,    var.connections.up    and 'T' or 'F') and
					compatible(d.right, var.connections.right and 'T' or 'F') and
					compatible(d.down,  var.connections.down  and 'T' or 'F') and
					compatible(d.left,  var.connections.left  and 'T' or 'F')
				then
					possible[#possible + 1] = var
				end
			end

			if #possible == 1 then
				-- print('fill', possible[1].name)
				apply_var(p[1], p[2], possible[1])
				finished[pk] = p
			else--if #possible > 1 then
				local none = {
					up = 'F';
					right = 'F';
					down = 'F';
					left = 'F';
				}

				local all = {
					up = true;
					right = true;
					down = true;
					left = true;
				}

				for _, possible in ipairs(possible) do
					for dir in pairs(possible.connections) do
						none[dir] = nil
					end

					for dir in pairs(all) do
						if not possible.connections[dir] then
							all[dir] = nil
						end
					end
				end

				-- print('none')
				for dir in pairs(none) do
					apply(p[1], p[2], dir, 'F')
				end

				-- print('all')
				for dir in pairs(all) do
					apply(p[1], p[2], dir, 'T')
				end

				mark_dirty(p[1], p[2])
			end
		end
		for pk, p in pairs(finished) do
			to_check[pk] = nil
			really_done[pk] = true
			mark_dirty(p[1], p[2])
		end

		if not any then
			break
		end
	end
end)

term.setCursorBlink(false)
term.clear()

-- this fixes Termu not rendering stuff properly
local w, h = term.getSize()
for y = 1, h do
	term.setCursorPos(1, y)
	term.blit(('y'):rep(w), ('a'):rep(w), ('7'):rep(w))
end

for x = 1, grid.w do
	for y = 1, grid.h do
		term.setCursorPos(x * 3 - 2, y * 2 - 1)
		render_dirs(render_data(x, y))
	end
end

while coroutine.status(co) ~= 'dead' do
	os.pullEvent('mouse_click')
	local ok, err = coroutine.resume(co)
	if not ok then
		error(err)
	end
end

term.clear()
term.setCursorPos(1, 1)