-- Layout.lua : Code to size and position the aura frames.

if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local _G = getfenv(0)
local PitBull4 = _G.PitBull4
local PitBull4_Aura = PitBull4:GetModule("Aura")

-- Dispatch table to actually have things grow in the right order.
local set_direction_point = {
	left_up = function(ctrl, pnt, frame, anchor, x, y, o_x, o_y)
		ctrl:SetPoint(pnt, frame, anchor, -x + o_x, y + o_y)
	end,
	left_down = function(ctrl, pnt, frame, anchor, x, y, o_x, o_y)
		ctrl:SetPoint(pnt, frame, anchor, -x + o_x, -y + o_y)
	end,
	right_up = function(ctrl, pnt, frame, anchor, x, y, o_x, o_y)
		ctrl:SetPoint(pnt, frame, anchor, x + o_x, y + o_y)
	end,
	right_down = function(ctrl, pnt, frame, anchor, x, y, o_x, o_y)
		ctrl:SetPoint(pnt, frame, anchor, x + o_x, -y + o_y)
	end,
	up_left = function(ctrl, pnt, frame, anchor, x, y, o_x, o_y)
		ctrl:SetPoint(pnt, frame, anchor, -y + o_x, x + o_y)
	end,
	up_right = function(ctrl, pnt, frame, anchor, x, y, o_x, o_y)
		ctrl:SetPoint(pnt, frame, anchor, y + o_x, x + o_y)
	end,
	down_left = function(ctrl, pnt, frame, anchor, x, y, o_x, o_y)
		ctrl:SetPoint(pnt, frame, anchor, -y + o_x, -x + o_y)
	end,
	down_right = function(ctrl, pnt, frame, anchor, x, y, o_x, o_y)
		ctrl:SetPoint(pnt, frame, anchor, y + o_x, -x + o_y)
	end,
}

local get_control_point = {
	TOPLEFT_TOP        = 'BOTTOMLEFT',
	TOPRIGHT_TOP       = 'BOTTOMRIGHT',
	TOPLEFT_LEFT       = 'TOPRIGHT',
	TOPRIGHT_RIGHT     = 'TOPLEFT',
	BOTTOMLEFT_BOTTOM  = 'TOPLEFT',
	BOTTOMRIGHT_BOTTOM = 'TOPRIGHT',
	BOTTOMLEFT_LEFT    = 'BOTTOMRIGHT',
	BOTTOMRIGHT_RIGHT  = 'BOTTOMLEFT',
}

local grow_vert_first = {
	down_right = true,
	down_left  = true,
	up_right   = true,
	up_left    = true,
}

local use_new_row_height = {
	left_down = {
		BOTTOMLEFT = true,
		BOTTOMRIGHT = true,
	},
	right_down = {
		BOTTOMLEFT = true,
		BOTTOMRIGHT = true,
	},
	left_up = {
		TOPLEFT = true,
		TOPRIGHT = true,
	},
	right_up = {
		TOPLEFT = true,
		TOPRIGHT = true,
	},
	up_left = {
		TOPLEFT = true,
		BOTTOMLEFT = true,
	},
	down_left = {
		TOPLEFT = true,
		BOTTOMLEFT = true,
	},
	up_right = {
		TOPRIGHT = true,
		BOTTOMRIGHT = true,
	},
	down_right = {
		TOPRIGHT = true,
		BOTTOMRIGHT = true,
	},
}


function layout_auras(frame, db, is_buff)
	local list, cfg
	if is_buff then
		list = frame.aura_buffs
		cfg = db.layout.buff
	else
		list = frame.aura_debuffs
		cfg = db.layout.debuff
	end
	if not list then return end

	-- Grab our config vars to avoid repeated table lookups
	local offset_x, offset_y = cfg.offset_x, cfg.offset_y
	local other_size = cfg.size
	local my_size = cfg.my_size
	local anchor = cfg.anchor
	local point = get_control_point[anchor..'_'..cfg.side]
	local growth = cfg.growth
	local width, width_type = cfg.width, cfg.width_type
	local row_spacing, col_spacing = cfg.row_spacing, cfg.col_spacing
	local new_row_size = cfg.new_row_size

	-- Our current position to place the control
	local x, y = 0, 0

	-- Current height of the row
	local row = 0

	-- Previous width on this row
	local prev_width

	-- Convert the percent based width to a fixed width
	if width_type == 'percent' then
		local side_width
		if grow_vert_first[growth] then
			side_width = frame:GetHeight()
		else
			side_width = frame:GetWidth()
		end
		width = side_width * cfg.width_percent
		width_type = 'fixed'
	end

	-- Swap row and col spacing if we're growing up or down first.
	if grow_vert_first[growth] then
		row_spacing, col_spacing = col_spacing, row_spacing
	end

	-- Size to fit
	if cfg.size_to_fit then
		local my_rowcount = math.floor(width/(my_size + col_spacing))
		local other_rowcount = math.floor(width/(other_size + col_spacing))
		my_size = my_size * width/((my_size + col_spacing) * my_rowcount)
		other_size = other_size * width/((other_size + col_spacing) * other_rowcount)
	end

	-- Allow reversal of the load order
	local start_list, end_list, step
	if cfg.reverse then
		start_list = #list
		end_list = 1
		step = -1
	else
		start_list = 1
		end_list = #list
		step = 1
	end

	for i = start_list, end_list, step do
		local control = list[i]
		local display = true

		local size = control.is_mine and my_size or other_size

		-- Calculate the width and height of this aura
		local new_width = size + col_spacing
		local new_height = size + row_spacing

		-- Calculate if we need to go to start a new row 
		-- width - x is the room left
		-- new_width is how much room we need
		-- We don't test for less than because they are
		-- floats and there is likely to be a certain amount
		-- of error when we do arithemtic on a float
		if (width - x - new_width) < -.0000001 then
			if x ~= 0 then
				-- Jump to the next column
				x = 0
				if use_new_row_height[growth][point] then
					y = y + new_height 
				else
					y = y + row 
				end
				row = new_height
				prev_width = nil -- no prev_width on this row
			else
				-- We were already on the first
				-- aura of the row.  So don't display
				-- anything for this aura.
				display = false
			end
		elseif new_row_size and prev_width and new_width ~= prev_width then
			-- Size changed so jump to new row
			x = 0
			if use_new_row_height[growth][point] then
				y = y + new_height 
			else
				y = y + row
			end
			row = new_height
			prev_width = nil
		end

		if display then
			control:SetWidth(size)
			control:SetHeight(size)

			control:ClearAllPoints()
			set_direction_point[growth](control, point, frame, anchor, x, y, offset_x, offset_y)

			control:Show()

			-- spacing for the next aura
			x = x + new_width

			-- Save the last width
			prev_width = new_width

			-- Set the row height
			if row < new_height then
				row = new_height
			end
		else
			control:Hide()
		end
	end
end

function PitBull4_Aura:LayoutAuras(frame)
	local db = self:GetLayoutDB(frame)

	layout_auras(frame, db, true)
	layout_auras(frame, db, false)
end
