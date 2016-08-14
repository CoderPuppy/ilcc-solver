local do_ui = true
local debug
do
	if false then
		function debug(msg, ...)
			print(msg:format(...))
		end
	else
		function debug()
		end
	end
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

			types.lookup[var.name] = var

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
		if line:match '^theme' then
		else
			x = 1
			for char in line:gmatch '.' do
				grid[x] = grid[x] or {}
				grid[x][y] = types.lookup[char]
				x = x + 1
			end
			w = math.max(w, x - 1)
			y = y + 1
		end
	end
	h = y - 1
	grid.w = w
	grid.h = h
	return grid
end

local function serialize(grid)
	local out = ''
	for y = 1, grid.h do
		for x = 1, grid.w do
			out = out .. grid[x][y].char
		end
		out = out .. '\n'
	end
	out = out .. 'themef0'
	return out
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

local cmd = ...

local grid

local data = setmetatable({}, {
	__index = function(t, k)
		local t_ = {}
		t[k] = t_
		return t_
	end;
})
local to_check = {}
local really_done = {}

local dirty = {}
local function mark_dirty(x, y)
	if x <= 0 or x > grid.w or y <= 0 or y > grid.h then
		return
	end

	dirty[P(x, y)] = {x, y}
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

local mark_check

local apply
do
	local function do_apply(x, y, dir, v)
		local d = data[P(x, y)]
		if not compatible(d[dir], v) then
			error(('mismatch between fixed links at (%d %d) %s have %s applying %s'):format(x, y, dir, d[dir], v))
		end

		local prev = d[dir]

		d[dir] = v

		if prev ~= v then
			-- debug('dirt (%d %d): apply', x, y)
			mark_dirty(x, y)
		end
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

if cmd:match '^g' then
	local _, file, w, h = ...
	w, h = tonumber(w), tonumber(h)

	grid = {w = w; h = h;}
	for x = 1, w do
		local col = {}
		grid[x] = col
		for y = 1, h do
			col[y] = types[1].variants[1]
		end
	end

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

				-- mm = '7'; -- gray
				mm =
					to_check[P(x, y)] and '2' or -- magenta
					really_done[P(x, y)] and (
						(d.up == 'T' or d.right == 'T' or d.down == 'T' or d.left == 'T')
						and 'f'
						or '0'
					) or
					'7'; -- gray
					-- to_check[P(x, y)] and '2' or -- orange
					-- really_done[P(x, y)] and 'd' or -- green
					-- '7'; -- gray
			}
		end
	end

	local co = coroutine.create(function()
		function mark_check(x, y)
			if x <= 0 or x > grid.w or y <= 0 or y > grid.h then
				return
			end

			local k = P(x, y)
			if not really_done[k] and not to_check[k] then
				to_check[k] = {x, y}

				-- debug('dirt (%d %d): mark check', x, y)
				mark_dirty(x, y)
			end
		end

		local function find_possible(x, y)
			local d = data[P(x, y)]

			local possible = {}

			for _, typ in ipairs(types) do
				for _, var in ipairs(typ.variants) do
					if
						compatible(d.up,    var.connections.up    and 'T' or 'F') and
						compatible(d.right, var.connections.right and 'T' or 'F') and
						compatible(d.down,  var.connections.down  and 'T' or 'F') and
						compatible(d.left,  var.connections.left  and 'T' or 'F')
					then
						possible[#possible + 1] = var
					end
				end
			end

			return possible
		end

		for x = 1, grid.w do
			apply(x, 1, 'up', 'F')
			apply(x, grid.h, 'down', 'F')
		end

		for y = 1, grid.h do
			apply(1, y, 'left', 'F')
			apply(grid.w, y, 'right', 'F')
		end
		
		mark_check(math.ceil(grid.w / 2), math.ceil(grid.h / 2))

		while true do
			for pk, p in pairs(dirty) do
				if do_ui then
					term.setCursorPos(p[1] * 3 - 2, p[2] * 2 - 1)
					render_dirs(render_data(p[1], p[2]))
				end
			end
			dirty = {}

			coroutine.yield()

			local any = false
			local check_t = to_check
			to_check = {}
			for pk, p in pairs(check_t) do
				really_done[pk] = p
			end
			for pk, p in pairs(check_t) do
				debug('(%d %d)', p[1], p[2])
				any = true

				local d = data[pk]

				local possible = find_possible(p[1], p[2])

				if #possible == 0 then
					error('bad')
				end

				local var = possible[math.random(#possible)]
				grid[p[1]][p[2]] = var

				apply_var(p[1], p[2], var)
			end

			if not any then
				for x = 1, grid.w do
					local col = grid[x]
					for y = 1, grid.h do
						local vars = col[y].type.variants
						col[y] = vars[math.random(#vars)]
					end
				end

				break
			end
		end
	end)

	if do_ui then
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
	end

	while coroutine.status(co) ~= 'dead' do
		os.pullEvent('mouse_click')
		local ok, err = coroutine.resume(co)
		if not ok then
			error(err)
		end
	end

	if do_ui then
		term.clear()
		term.setCursorPos(1, 1)
	end

	local h = fs.open(shell.resolve(file), 'w')
	h.write(serialize(grid))
	h.close()
elseif cmd:match '^s' then
	do
		local h = fs.open(select(2, ...), 'r')
		grid = parse(h.readAll())
		h.close()
	end

	local new_check = {}
	local path = {}

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

				-- mm = '7'; -- gray
				mm =
					to_check[P(x, y)] and '2' or -- magenta
					new_check[P(x, y)] and 'a' or -- purple
					really_done[P(x, y)] and (
						(d.up == 'T' or d.right == 'T' or d.down == 'T' or d.left == 'T')
						and 'f'
						or '0'
					) or
					'7'; -- gray
					-- to_check[P(x, y)] and '2' or -- orange
					-- really_done[P(x, y)] and 'd' or -- green
					-- '7'; -- gray
			}
		end
	end

	local function clone(t, c)
		c = c or {}
		if c[t] then
			return c[t]
		elseif type(t) == 'table' then
			local n = {}
			c[t] = n
			for k, v in pairs(t) do
				n[k] = clone(v, c)
			end
			setmetatable(n, getmetatable(t))
			return n
		else
			return t
		end
	end

	local function bad(msg)
		if #path > 0 then
			error('TODO: rollback')
		else
			error(msg)
		end
	end

	local co = coroutine.create(function()
		function mark_check(x, y)
			if x <= 0 or x > grid.w or y <= 0 or y > grid.h then
				return
			end

			local k = P(x, y)
			if not really_done[k] and not to_check[k] and not new_check[k] then
				new_check[k] = {x, y}

				-- debug('dirt (%d %d): mark check', x, y)
				mark_dirty(x, y)
			end
		end
		local function find_possible(x, y)
			local typ = grid[x][y].type
			local d = data[P(x, y)]

			local possible = {}

			for _, var in ipairs(typ.variants) do
				if
					compatible(d.up,    var.connections.up    and 'T' or 'F') and
					compatible(d.right, var.connections.right and 'T' or 'F') and
					compatible(d.down,  var.connections.down  and 'T' or 'F') and
					compatible(d.left,  var.connections.left  and 'T' or 'F')
				then
					possible[#possible + 1] = var
				end
			end

			return possible
		end

		for x = 1, grid.w do
			mark_check(x, 1)
			apply(x, 1, 'up', 'F')

			mark_check(x, grid.h)
			apply(x, grid.h, 'down', 'F')
		end

		for y = 1, grid.h do
			mark_check(1, y)
			apply(1, y, 'left', 'F')

			mark_check(grid.w, y)
			apply(grid.w, y, 'right', 'F')
		end

		while true do
			local any = false
			for pk, p in pairs(dirty) do
				any = true
				if do_ui then
					term.setCursorPos(p[1] * 3 - 2, p[2] * 2 - 1)
					render_dirs(render_data(p[1], p[2]))
				end
			end
			dirty = {}

			if not any then
				-- nothing changed but it's not done
				local all = {}
				for pk in pairs(to_check) do
					all[#all + 1] = pk
				end
				table.sort(all)

				local x, y = all[1]:match '^(%d*)-(%d*)$'
				x, y = tonumber(x), tonumber(y)

				local possible = find_possible(x, y)

				debug('(%d %d) has %d possiblities', x, y, #possible)

				local copy = clone {
					data = data;
					to_check = to_check;
					really_done = really_done;
				}

				path[#path + 1] = {
					state = copy;
					x = x; y = y;
					i = 1;
					possible = possible;
				}

				apply_var(x, y, possible[1])

				-- break
			end

			coroutine.yield()

			local finished = {}
			local any = false
			for pk, p in pairs(to_check) do
				any = true

				local typ = grid[p[1]][p[2]].type
				local d = data[pk]

				local possible = find_possible(p[1], p[2])


				if #possible == 1 then
					apply_var(p[1], p[2], possible[1])
					finished[pk] = p
				elseif #possible > 1 then
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

					for dir in pairs(none) do
						apply(p[1], p[2], dir, 'F')
					end

					for dir in pairs(all) do
						apply(p[1], p[2], dir, 'T')
					end
				else
					bad(('no possible variants at (%d %d)'):format(p[1], p[2]))
				end
			end
			for pk, p in pairs(finished) do
				to_check[pk] = nil
				really_done[pk] = true
				mark_dirty(p[1], p[2])
			end
			for pk, p in pairs(new_check) do
				any = true
				to_check[pk] = p
				mark_dirty(p[1], p[2])
			end
			new_check = {}

			if not any then
				break
			end
		end
	end)

	if do_ui then
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
	end

	while coroutine.status(co) ~= 'dead' do
		os.pullEvent('mouse_click')
		local ok, err = coroutine.resume(co)
		if not ok then
			bad(err)
		end
	end

	if do_ui then
		term.clear()
		term.setCursorPos(1, 1)
	end
end
