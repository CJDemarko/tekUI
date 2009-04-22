-------------------------------------------------------------------------------
--
--	tek.ui.class.area
--	Written by Timm S. Mueller <tmueller at schulze-mueller.de>
--	See copyright notice in COPYRIGHT
--
--	OVERVIEW::
--		[[#ClassOverview]] :
--		[[#tek.class : Class]] /
--		[[#tek.class.object : Object]] /
--		[[#tek.ui.class.element : Element]] / Area
--
--		This class implements an outer margin, layouting and drawing.
--
--	ATTRIBUTES::
--		- {{AutoPosition [IG]}} (boolean)
--			When the element receives the focus, this flag instructs it to
--			position itself automatically into the visible area of any Canvas
--			that may contain it. An affected Canvas must have the
--			{{AutoPosition}} attribute enabled to take effect, too, but unlike
--			the Area class, the Canvas class disables it by default.
--		- {{BGPen [IG]}} (number)
--			A pen number for painting the background of the element
--		- {{DamageRegion [G]}} ([[#tek.lib.region : Region]])
--			see {{TrackDamage}}
--		- {{Disabled [ISG]}} (boolean)
--			If '''true''', the element is in disabled state. This attribute is
--			handled by the [[#tek.ui.class.gadget : Gadget]] class.
--		- {{EraseBG [IG]}} (boolean)
--			If '''false''', the element's background is painted by the Area
--			class using the Area:erase() method. Child classes can set this
--			attribute to '''true''', indicating that they wish to paint the
--			background themselves.
--		- {{Focus [ISG]}} (boolean)
--			If '''true''', the element has the input focus. This attribute
--			is handled by the [[#tek.ui.class.gadget : Gadget]] class.
--		- {{HAlign [IG]}} ("left", "center", "right")
--			Horizontal alignment of the element in its group [default:
--			"left"]
--		- {{Height [IG]}} (number, '''false''', or "auto", "fill", "free")
--			Height of the element, in pixels, or
--				- '''false''' - unspecified; during initialization, the class'
--				default will be used
--				- "auto" - Reserves the minimal height needed for the element.
--				- "free" - Allows the element's height to grow to any size.
--				- "fill" - Completely fills up the height that other elements
--				in the same group have left, but does not claim more.
--			Note: Normally, "fill" is useful only once per group.
--		- {{Hilite [SG]}} (boolean)
--			If '''true''', the element is in highlighted state. This
--			attribute is handled by the [[#tek.ui.class.gadget : Gadget]]
--			class.
--		- {{Margin [IG]}} (table)
--			An array of four offsets for the element's outer margin in the
--			order left, right, top, bottom [pixels]. If unspecified during
--			initialization, the class' default margins are used.
--		- {{MaxHeight [IG]}} (number)
--			Maximum height of the element, in pixels [default: {{ui.HUGE}}]
--		- {{MaxWidth [IG]}} (number)
--			Maximum width of the element, in pixels [default: {{ui.HUGE}}]
--		- {{MinHeight [IG]}} (number)
--			Minimum height of the element, in pixels [default: 0]
--		- {{MinWidth [IG]}} (number)
--			Minimum width of the element, in pixels [default: 0]
--		- {{Padding [IG]}} (table)
--			An array of four offsets for the element's inner padding in the
--			order left, right, top, bottom [pixels]. If unspecified during
--			initialization, the class' default paddings are used.
--		- {{Selected [ISG]}} (boolean)
--			If '''true''', the element is in selected state. This attribute
--			is handled by the [[#tek.ui.class.gadget : Gadget]] class.
--		- {{TrackDamage [IG]}} (boolean)
--			If '''true''', the element gathers intra-area damages in a
--			Region named {{DamageRegion}}, which can be used by class
--			implementors for minimally invasive repainting [Default:
--			'''false''', the element is redrawn in its entirety.)
--		- {{VAlign [IG]}} ("top", "center", "bottom")
--			Vertical alignment of the element in its group [default: "top"]
--		- {{Weight [IG]}} (number)
--			Determines the weight that is attributed to the element, relative
--			to its siblings in its group. Note: By recommendation, the weights
--			in a group should sum up to 0x10000.
--		- {{Width [IG]}} (number, '''false''', or "auto", "fill", "free")
--			Width of the element, in pixels, or
--				- '''false''' - unspecified; during initialization, the class'
--				default will be used
--				- "auto" - Reserves the minimal width needed for the element.
--				- "free" - Allows the element's width to grow to any size.
--				- "fill" - Completely fills up the width that other elements
--				in the same group have left, but does not claim more.
--			Note: Normally, "fill" is useful only once per group.
--
--	STYLE PROPERTIES::
--		- {{background-color}}
--		- {{height}}
--		- {{horizontal-grid-align}}
--		- {{margin}}
--		- {{margin-bottom}}
--		- {{margin-left}}
--		- {{margin-right}}
--		- {{margin-top}}
--		- {{max-height}}
--		- {{max-width}}
--		- {{min-height}}
--		- {{min-width}}
--		- {{padding}}
--		- {{padding-bottom}}
--		- {{padding-left}}
--		- {{padding-right}}
--		- {{padding-top}}
--		- {{vertical-grid-align}}
--		- {{width}}
--
--	IMPLEMENTS::
--		- Area:askMinMax() - Queries element's minimum and maximum dimensions
--		- Area:checkFocus() - Checks if the element can receive the focus
--		- Area:draw() - Paints the element
--		- Area:erase() - Erase the element's background
--		- Area:focusRectangle() - Make the element fully visible in a Canvas
--		- Area:getElement() - Returns an element's neighbours
--		- Area:getElementByXY() - Checks if the element covers a coordinate
--		- Area:getRectangle() - Returns the element's layouted coordinates
--		- Area:hide() - Disconnects the element from a Display and Drawable
--		- Area:layout() - Layouts the element into a rectangle
--		- Area:markDamage() - Notifies the element of a damage
--		- Area:passMsg() - Passes an input message to the element
--		- Area:punch() - Subtracts the outline of the element from a
--		[[#tek.lib.region : Region]]
--		- Area:refresh() - [internal] Repaints the element if necessary
--		- Area:relayout() - [internal] Relayouts the element if necessary
--		- Area:rethinkLayout() - Causes a relayout of the element and its group
--		- Area:setState() - Sets the background attribute of an element
--		- Area:show() - Connects the element to a Display and Drawable
--
--	OVERRIDES::
--		- Element:cleanup()
--		- Object.init()
--		- Class.new()
--		- Element:setup()
--
-------------------------------------------------------------------------------

local db = require "tek.lib.debug"
local Region = require "tek.lib.region"
local ui = require "tek.ui"
local Element = ui.Element

local assert = assert
local floor = math.floor
local insert = table.insert
local ipairs = ipairs
local max = math.max
local min = math.min
local overlap = Region.overlapCoords
local remove = table.remove
local tonumber = tonumber
local unpack = unpack

module("tek.ui.class.area", tek.ui.class.element)
_VERSION = "Area 17.0"
local Area = _M

-------------------------------------------------------------------------------
--	new:
-------------------------------------------------------------------------------

function Area.new(class, self)
	self = self or { }
	-- Combined margin and border offsets of the element:
	self.MarginAndBorder = { }
	-- Calculated minimum/maximum sizes of the element:
	self.MinMax = { }
	-- The layouted rectangle of the element on the display:
	self.Rect = { }
	return Element.new(class, self)
end

-------------------------------------------------------------------------------
--	init:
-------------------------------------------------------------------------------

function Area.init(self)
	self.AutoPosition = self.AutoPosition == nil and true or self.AutoPosition
	self.Background = false
	self.BGPen = self.BGPen or false
	self.DamageRegion = false
	self.Disabled = self.Disabled or false
	self.Display = false
	self.Drawable = false
	self.EraseBG = self.EraseBG or false
	self.Focus = self.Focus or false
	self.HAlign = self.HAlign or false
	self.Height = self.Height or false
	self.Hilite = false
	self.Margin = self.Margin or { }
	self.MaxHeight = self.MaxHeight or false
	self.MaxWidth = self.MaxWidth or false
	self.MinHeight = self.MinHeight or false
	self.MinWidth = self.MinWidth or false
	self.Padding = self.Padding or { }
	self.Redraw = false
	self.Selected = self.Selected or false
	self.TrackDamage = self.TrackDamage or false
	self.VAlign = self.VAlign or false
	self.Weight = self.Weight or false
	self.Width = self.Width or false
	return Element.init(self)
end

-------------------------------------------------------------------------------
--	getProperties: overrides
-------------------------------------------------------------------------------

function Area:getProperties(p, pclass)
	self.BGPen = self.BGPen or self:getProperty(p, pclass, "background-color")
	self.HAlign = self.HAlign or
		self:getProperty(p, pclass, "horizontal-grid-align")
	self.VAlign = self.VAlign or
		self:getProperty(p, pclass, "vertical-grid-align")
	self.Width = self.Width or self:getProperty(p, pclass, "width")
	self.Height = self.Height or self:getProperty(p, pclass, "height")

	local m = self.Margin
	m[1] = m[1] or tonumber(self:getProperty(p, pclass, "margin-left"))
	m[2] = m[2] or tonumber(self:getProperty(p, pclass, "margin-top"))
	m[3] = m[3] or tonumber(self:getProperty(p, pclass, "margin-right"))
	m[4] = m[4] or tonumber(self:getProperty(p, pclass, "margin-bottom"))

	self.MaxHeight = self.MaxHeight or
		self:getProperty(p, pclass, "max-height")
	self.MaxWidth = self.MaxWidth or self:getProperty(p, pclass, "max-width")
	self.MinHeight = self.MinHeight or
		self:getProperty(p, pclass, "min-height")
	self.MinWidth = self.MinWidth or self:getProperty(p, pclass, "min-width")

	local q = self.Padding
	q[1] = q[1] or tonumber(self:getProperty(p, pclass, "padding-left"))
	q[2] = q[2] or tonumber(self:getProperty(p, pclass, "padding-top"))
	q[3] = q[3] or tonumber(self:getProperty(p, pclass, "padding-right"))
	q[4] = q[4] or tonumber(self:getProperty(p, pclass, "padding-bottom"))

	Element.getProperties(self, p, pclass)
end

-------------------------------------------------------------------------------
--	setup: overrides
-------------------------------------------------------------------------------

function Area:setup(app, win)
	Element.setup(self, app, win)

	-- consolidation of properties:

	self.Width = tonumber(self.Width) or self.Width
	self.Height = tonumber(self.Height) or self.Height

	local m = self.Margin
	m[1], m[2], m[3], m[4] = tonumber(m[1]) or 0, tonumber(m[2]) or 0,
		tonumber(m[3]) or 0, tonumber(m[4]) or 0
	local p = self.Padding
	p[1], p[2], p[3], p[4] = tonumber(p[1]) or 0, tonumber(p[2]) or 0,
		tonumber(p[3]) or 0, tonumber(p[4]) or 0

	if not self.MaxHeight or self.MaxHeight == "free" then
		self.MaxHeight = ui.HUGE
	end
	if not self.MaxWidth or self.MaxWidth == "free" then
		self.MaxWidth = ui.HUGE
	end

	self.MinHeight = self.MinHeight or 0
	self.MinWidth = self.MinWidth or 0
end

-------------------------------------------------------------------------------
--	success = Area:show(display, drawable): Passes an element the
--	[[#tek.ui.class.display : Display]] and
--	[[#tek.ui.class.drawable : Drawable]] it will be rendered to. Returns
--	a boolean indicating success. If you override this method, pass the call
--	to your super class and check and propagate its return value. See also:
--	Area:hide().
-------------------------------------------------------------------------------

function Area:show(display, drawable)
	self.Display = display
	self.Drawable = drawable
	self:calcOffsets()
	self:setState()
	return true
end

-------------------------------------------------------------------------------
--	Area:hide(): Removes the display and drawable from an element.
--	Override this method to free all display-related resources previously
--	allocated in Area:show().
-------------------------------------------------------------------------------

function Area:hide()
	self.DamageRegion = false
	self.Display = false
	self.Drawable = false
	self.MinMax = { }
	self.Rect = { }
	self.MarginAndBorder = { }
end

-------------------------------------------------------------------------------
--	Area:calcOffsets() [internal] - This function calculates the
--	{{MarginAndBorder}} property.
-------------------------------------------------------------------------------

function Area:calcOffsets()
	local s, d = self.Margin, self.MarginAndBorder
	d[1], d[2], d[3], d[4] = s[1], s[2], s[3], s[4]
end

-------------------------------------------------------------------------------
--	Area:rethinkLayout([damage]): This method causes a relayout of the
--	element and possibly the [[#tek.ui.class.group : Group]] in which it
--	resides. The optional numeric argument {{damage}} indicates the kind
--	of damage to apply to the element:
--		- 0 - do not mark the element as damaged
--		- 1 - slate the group (not its contents) for repaint [default]
--		- 2 - mark the whole group and its contents as damaged
-------------------------------------------------------------------------------

function Area:rethinkLayout(damage)
	-- must be on a display and layouted previously:
	if self.Display and self.Rect[1] then
		self:calcOffsets()
		local parent = self:getElement("parent")
		self.Window:addLayoutGroup(parent, damage or 1)
		-- this causes the rethink to bubble up until it reaches the window:
		parent:rethinkLayout(0)
	else
		db.info("%s : Cannot rethink layout - not connected to a display",
			self:getClassName())
	end
end

-------------------------------------------------------------------------------
--	minw, minh, maxw, maxh = Area:askMinMax(minw, minh, maxw, maxh): This
--	method is called during the layouting process for adding the required
--	spatial extents (width and height) of this class to the min/max values
--	passed from a child class, before passing them on to its super class.
--	{{minw}}, {{minh}} are cumulative of the minimal size of the element,
--	while {{maxw}}, {{maxw}} collect the size the element is allowed to
--	expand to. Use {{ui.HUGE}} to indicate a practically unlimited size.
-------------------------------------------------------------------------------

function Area:askMinMax(m1, m2, m3, m4)
	local p, m, mm = self.Padding, self.MarginAndBorder, self.MinMax
	m1 = max(self.MinWidth, m1 + p[1] + p[3])
	m2 = max(self.MinHeight, m2 + p[2] + p[4])
	m3 = max(min(self.MaxWidth, m3 + p[1] + p[3]), m1)
	m4 = max(min(self.MaxHeight, m4 + p[2] + p[4]), m2)
	m1 = m1 + m[1] + m[3]
	m2 = m2 + m[2] + m[4]
	m3 = m3 + m[1] + m[3]
	m4 = m4 + m[2] + m[4]
	mm[1], mm[2], mm[3], mm[4] = m1, m2, m3, m4
	return m1, m2, m3, m4
end

-------------------------------------------------------------------------------
--	changed = Area:layout(x0, y0, x1, y1[, markdamage]): Layouts the element
--	into the specified rectangle. If the element's (or any of its childrens')
--	coordinates change, returns '''true''' and marks the element as damaged,
--	unless the optional argument {{markdamage}} is set to '''false'''.
-------------------------------------------------------------------------------

function Area:layout(x0, y0, x1, y1, markdamage)

	local r = self.Rect
	local m = self.MarginAndBorder

	x0 = x0 + m[1]
	y0 = y0 + m[2]
	x1 = x1 - m[3]
	y1 = y1 - m[4]

	local r1, r2, r3, r4 = unpack(r)
	if r1 == x0 and r2 == y0 and r3 == x1 and r4 == y1 then
		-- nothing changed, no damage:
		self.DamageRegion = false
		return
	end

	r[1], r[2], r[3], r[4] = x0, y0, x1, y1
	markdamage = markdamage ~= false

	if not r1 then
		-- this is the first layout:
		self.Redraw = self.Redraw or markdamage
		return true
	end

	-- delta shift, delta size:
	local dx = x0 - r1
	local dy = y0 - r2
	local dw = x1 - x0 - r3 + r1
	local dh = y1 - y0 - r4 + r2
	
	-- get element transposition:
	local sx, sy = self.Drawable:getShift()
	local win = self.Window
	
	local samesize = dw == 0 and dh == 0
	local validmove = (dx == 0) ~= (dy == 0) and sx == 0 and sy == 0
	-- and ((dx == 0 or sx == 0) and (dy == 0 or sy == 0))
	
	-- refresh element by copying if:
	-- * element is not transposed
	-- * shifting occurs only on one axis
	-- * size is unchanged OR TrackDamage enabled
	-- * object is not already slated for copying
	
	if validmove and (samesize or self.TrackDamage)
		and not win.CopyObjects[self] then
		
		win.CopyObjects[self] = true

		-- get source rect, incl. border:
		local s1 = x0 - dx - m[1]
		local s2 = y0 - dy - m[2]
		local s3 = x1 - dx + m[3]
		local s4 = y1 - dy + m[4]

		-- get sortable key for delta:
		local key = ("%d:%d"):format(dx, dy)
		
		local ca = win.CopyArea[key]
		if ca then
			ca[3]:orRect(s1, s2, s3, s4)
		else
			win.CopyArea[key] = { dx, dy, Region.new(s1, s2, s3, s4) }
		end
	
		if samesize then
			-- something changed, no Redraw. second value: border_ok hack
			return true, true
		end
	
		r1 = r1 + dx
		r2 = r2 + dy
		r3 = r3 + dx
		r4 = r4 + dy
	end
	
	if x0 == r1 and y0 == r2 then
		-- did not move, size changed:
		if markdamage and self.TrackDamage then
			-- if damage is to be marked and damage can be tracked:
			self.DamageRegion = Region.new(x0, y0, x1, y1)
			self.DamageRegion:subRect(r1, r2, r3, r4)
		end
	end
	
	self.Redraw = self.Redraw or markdamage -- mark damaged if desired
	return true
end

-------------------------------------------------------------------------------
--	found[, changed] = Area:relayout(element, x0, y0, x1, y1) [internal]:
--	Traverses the element tree searching for the specified element, and if
--	this class (or the class of one of its children) is responsible for it,
--	layouts it to the specified rectangle. Returns '''true''' if the element
--	was found and its layout updated. A secondary return value of '''true'''
--	indicates whether relayouting actually caused a change, i.e. a damage to
--	the object.
-------------------------------------------------------------------------------

function Area:relayout(e, r1, r2, r3, r4)
	if self == e then
		return true, self:layout(r1, r2, r3, r4)
	end
end

-------------------------------------------------------------------------------
--	Area:punch(region) [internal]: Subtracts the element from (punching a
--	hole into) the specified Region. This function is called by the layouter.
-------------------------------------------------------------------------------

function Area:punch(region)
	region:subRect(unpack(self.Rect))
end

-------------------------------------------------------------------------------
--	Area:markDamage(x0, y0, x1, y1): If the element overlaps with the given
--	rectangle, this function marks it as damaged.
-------------------------------------------------------------------------------

function Area:markDamage(r1, r2, r3, r4)
	if self.TrackDamage or not self.Redraw then
		local s1, s2, s3, s4 = self:getRectangle()
		if s1 then
			r1, r2, r3, r4 = overlap(r1, r2, r3, r4, s1, s2, s3, s4)
			if r1 then
				self.Redraw = true
				if self.DamageRegion then
					self.DamageRegion:orRect(r1, r2, r3, r4)
				elseif self.TrackDamage then
					self.DamageRegion = Region.new(r1, r2, r3, r4)
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
--	Area:draw(): Draws the element into the rectangle assigned to it by
--	the layouter; the coordinates can be found in the element's {{Rect}}
--	table. Note: Applications are not allowed to call this function directly.
-------------------------------------------------------------------------------

function Area:draw()
	if not self.EraseBG then
		self:erase()
	end
end

-------------------------------------------------------------------------------
--	Area:erase(): Clears the element's background.
-------------------------------------------------------------------------------

function Area:erase()
	local d = self.Drawable
	local bgpen = d.Pens[self.Background]
	local dr = self.DamageRegion
	if dr then
		-- repaint intra-area damagerects:
		for _, r1, r2, r3, r4 in dr:getRects() do
			d:fillRect(r1, r2, r3, r4, bgpen)
		end
		self.DamageRegion = false
	else
		local r = self.Rect
		d:fillRect(r[1], r[2], r[3], r[4], bgpen)
	end
end

-------------------------------------------------------------------------------
--	Area:refresh() [internal]: Redraws the element (and all possible children)
--	if they are marked as damaged.
-------------------------------------------------------------------------------

function Area:refresh()
	if self.Redraw then
		self:draw()
		self.Redraw = false
	end
end

-------------------------------------------------------------------------------
--	self = Area:getElementByXY(x, y): Returns {{self}} if the element covers
--	the specified coordinate.
-------------------------------------------------------------------------------

function Area:getElementByXY(x, y)
	local r1, r2, r3, r4 = self:getRectangle()
	return r1 and x >= r1 and x <= r3 and y >= r2 and y <= r4 and self
end

-------------------------------------------------------------------------------
--	msg = Area:passMsg(msg): This function filters the specified input
--	message. After processing, it is free to return the message unmodified
--	(thus passing it on to the next message handler), to return a copy that
--	has certain fields in the message modified, or to 'swallow' the message
--	by returning '''false'''. If you override this function, you are not
--	allowed to modify any data inside the original message; to alter a
--	message, you must operate on and return a copy.
-------------------------------------------------------------------------------

function Area:passMsg(msg)
	return msg
end

-------------------------------------------------------------------------------
--	Area:setState(bg): Sets the {{Background}} attribute according to
--	the state of the element, and if it changed, slates the element
--	for repainting.
-------------------------------------------------------------------------------

function Area:setState(bg, fg)
	bg = bg or self.BGPen or ui.PEN_BACKGROUND
	if bg == ui.PEN_PARENTGROUP then
		bg = self:getElement("group").Background
	end
	if bg ~= self.Background then
		self.Background = bg
		self.Redraw = true
	end
end

-------------------------------------------------------------------------------
--	can_receive = Area:checkFocus(): Returns '''true''' if this element can
--	receive the input focus. (As an Area is non-interactive, the return value
--	of this class' implementation is always '''false'''.)
-------------------------------------------------------------------------------

function Area:checkFocus()
	return false
end

-------------------------------------------------------------------------------
--	element = Area:getElement(mode): Returns an element's neighbours. This
--	function can be overridden to control a class-specific tab cycle behavior.
--	Possible values for {{mode}} are:
--		- "parent" - returns the elements' parent element.
--		- "children" - returns a table containing the element's children, or
--		'''nil''' if the element has no children.
--		- "siblings" - returns a table containing the element's siblings
--		(including the element itself), or a table containing only the
--		element, if it is not member of a group.
--		- "next" - returns the next element in the group, or '''nil''' if
--		the element has no successors.
--		- "prev" - returns the previous element in the group, or '''nil''' if
--		the element has no predecessors.
--		- "nextorparent" - returns the next element in a group, or, if the
--		element has no successor, the next element in the parent group (and
--		so forth, until it reaches the topmost group).
--		- "prevorparent" - returns the previous element in a group, or, if the
--		element has no predecessor, the next element in the parent group (and
--		so forth, until it reaches the topmost group).
--		- "firstchild" - returns the element's first child, or '''nil''' if
--		the element has no children.
--		- "lastchild" - returns the element's last child, or '''nil''' if
--		the element has no children.
--
--	Note: Tables returned by this function must be treated read-only.
-------------------------------------------------------------------------------

function Area:getElement(mode)
	if mode == "parent" then
		assert(self.Parent)
		return self.Parent
	elseif mode == "children" then
		return -- an area has no children
	elseif mode == "siblings" then
		local p = self:getElement("parent")
		return p and p:getElement("children")
	elseif mode == "group" then
		assert(self.Parent)
		return self.Parent
	end
	local g = self:getElement("siblings")
	if g then
		local n = #g
		for i, e in ipairs(g) do
			if e == self then
				if mode == "next" then
					return g[i % n + 1]
				elseif mode == "prev" then
					return g[(i - 2) % n + 1]
				elseif mode == "nextorparent" then
					if i == n then
						return self:getElement("parent"):
							getElement("nextorparent")
					end
					return g[i % n + 1]
				elseif mode == "prevorparent" then
					if i == 1 then
						return self:getElement("parent"):
							getElement("prevorparent")
					end
					return g[(i - 2) % n + 1]
				end
				break
			end
		end
	end
end

-------------------------------------------------------------------------------
--	x0, y0, x1, y1 = Area:getRectangle(): This function returns the
--	rectangle which the element has been layouted to, or '''false'''
--	if the element has not been layouted yet.
-------------------------------------------------------------------------------

function Area:getRectangle()
	if self.Display then
		return unpack(self.Rect)
	end
	db.info("Layout not available")
	return false
end

-------------------------------------------------------------------------------
--	Area:focusRectangle([x0, y0, x1, y1]): Tries to shift any Canvas
--	containing the element into a position that makes the element fully
--	visible. Optionally, a rectangle can be specified that is to be made
--	visible.
-------------------------------------------------------------------------------

function Area:focusRectangle(r1, r2, r3, r4)
	if not r1 then
		r1, r2, r3, r4 = self:getRectangle()
		if not r1 then
			return
		end
		local m = self.MarginAndBorder
		r1 = r1 - m[1]
		r2 = r2 - m[2]
		r3 = r3 + m[3]
		r4 = r4 + m[4]
	end
	local parent = self:getElement("parent")
	if parent then
		parent:focusRectangle(r1, r2, r3, r4)
	end
end
