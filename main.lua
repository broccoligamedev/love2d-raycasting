local frame_time = 0
local objects = {}
local window_width = 800
local window_height = 600
local selected_object = nil
local font = nil
local count = 0
local contacts = {}
local rays = {}
local ray_count = 1

function love.load()
	print("starting game.")
	math.randomseed(os.clock())
	font = love.graphics.newFont(32)
	love.window.setMode(window_width, window_height, {vsync = true})
	for i = 1, 25 do
		local rect_width = math.random(20, 40)
		local rect_height = math.random(20, 40)
		table.insert(objects,
			new_poly(
				math.random(0, window_width - rect_width),
				math.random(0, window_height - rect_height),
				rect_width,
				rect_height
			)
		)
	end
	print("loading complete.")
end

function raycast(origin, dest)
	-- (a, b), (c, d) are points defining two line segments
	-- r, s are direction vectors
	-- t, u are scalar values
	-- vec2 cross product is defined as (ax * by) - (ay * bx)
	local closest_obj = nil
	local shortest_dist = nil
	local a = origin
	local b = dest
	local r = vec2_sub(b, a)
	for i = 1, #objects do
		local points = objects[i].points
		for k = 1, #points do
			local c = points[k]
			local d = points[(k % #points) + 1]
			local s = vec2_sub(d, c)
			local cross_rs = vec2_cross(r, s)
			local cross_sr = vec2_cross(s, r)
			local t = nil
			local u = nil
			if (cross_rs ~= 0) and (cross_sr ~= 0) then
				t = vec2_cross(vec2_sub(c, a), s) / cross_rs
				u = vec2_cross(vec2_sub(a, c), r) / cross_sr
				if (t >= 0 and t <= 1) and (u >= 0 and u <= 1) then
					if not shortest_dist or t < shortest_dist then
						shortest_dist = t
						closest_obj = objects[i]
					end
				end
			end
		end
	end
	if closest_obj then
		vec2_scale(r, shortest_dist)
		table.insert(contacts, vec2_add(a, r))
		closest_obj.is_touched = true
	end
	table.insert(rays, vec2_add(origin, r))
end

function new_poly(x, y, w, h)
	local poly = {}
	poly.points = {}
	poly.points[1] = {x = x, y = y}
	poly.points[2] = {x = x + w, y = y}
	poly.points[3] = {x = x + w, y = y + h}
	poly.points[4] = {x = x, y = y + h}
	return poly
end

function love.update()
	local start_time = os.clock()
	for i = 1, #objects do
		local o1 = objects[i]
		o1.is_touched = false
	end
	rays = {}
	contacts = {}
	local rays = {}
	local mouse = vec2_new(love.mouse.getX(), love.mouse.getY())
	local center = vec2_new(window_width / 2, window_height / 2)
	for i = 1, ray_count do
		local ray = vec2_sub(mouse, center)
		vec2_rotate(ray, ((i - 1) * 2 * math.pi / ray_count))
		ray = vec2_add(ray, center)
		rays[i] = ray
	end
	for i = 1, #rays do
		raycast(center, rays[i])
	end
	frame_time = os.clock() - start_time
end

function love.draw()
	love.graphics.setFont(font)
	for i = 1, #objects do
		local o = objects[i]
		local points = {}
		for k = 1, #o.points do
			table.insert(points, o.points[k].x)
			table.insert(points, o.points[k].y)
		end
		if o.is_touched then
			love.graphics.setColor(255, 0, 0)
		else
			love.graphics.setColor(255, 255, 255)
		end
		love.graphics.polygon(
			"fill",
			points
		)
	end

	love.graphics.setColor(255, 255, 0)
	for i = 1, #contacts do
		love.graphics.circle("fill", contacts[i].x, contacts[i].y, 8)
	end
	for i = 1, #rays do
		love.graphics.line(window_width / 2, window_height / 2, rays[i].x, rays[i].y)
	end

	-- draw debug
	love.graphics.setColor(0, 0, 0, 200)
	love.graphics.rectangle("fill", 0, 0, 220, 97)
	love.graphics.setColor(255, 255, 255)

	local debug_text =
		string.format("%d fps\n", love.timer.getFPS()) ..
		string.format("%.2f mb\n", collectgarbage("count") / 1000) ..
		string.format("%.5f s\n", frame_time)
	love.graphics.print(debug_text, 10, 10)
end

function love.wheelmoved(x, y)
	ray_count = ray_count + y
end

function vec2_add(v1, v2)
	return vec2_new(v1.x + v2.x, v1.y + v2.y)
end

function vec2_sub(v1, v2)
	return vec2_new(v1.x - v2.x, v1.y - v2.y)
end

function vec2_cross(v1, v2)
	return (v1.x * v2.y) - (v1.y * v2.x)
end

function vec2_scale(v1, s)
	v1.x, v1.y = v1.x * s, v1.y * s
end

function vec2_get_normals(v1)
	local norm1 = vec2_normalize(vec2_new(v1.y, -v1.x))
	local norm2 = vec2_normalize(vec2_new(-v1.y, v1.x))
	return norm1, norm2
end

function vec2_normalize(v1)
	local mag = vec2_length(v1)
	v1.x, v1.y = v1.x / mag, v1.y / mag
	return v1
end

function vec2_length(v1)
	return math.sqrt((v1.x * v1.x) + (v1.y * v1.y))
end

function vec2_new(x, y)
	return {x = x, y = y}
end

function vec2_rotate(v1, r)
	local precision = 5
	local new_x = (v1.x * math.cos(r)) - (v1.y * math.sin(r))
	new_x = math.floor(new_x * (10 ^ precision)) / (10 ^ precision)
	local new_y = (v1.x * math.sin(r)) + (v1.y * math.cos(r))
	new_y = math.floor(new_y * (10 ^ precision)) / (10 ^ precision)
	v1.x = new_x
	v1.y = new_y
end

function love.quit()
	print("program exited.")
end

