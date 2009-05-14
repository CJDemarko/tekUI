
--
--	tek.ui.class.meter
--	Written by Timm S. Mueller <tmueller at schulze-mueller.de>
--	See copyright notice in COPYRIGHT
--

local db = require "tek.lib.debug"
local ui = require "tek.ui"
local Text = ui.Text
local Region = require "tek.lib.region"

local floor = math.floor
local insert = table.insert
local ipairs = ipairs
local max = math.max
local min = math.min
local pi = math.pi
local remove = table.remove
local sin = math.sin
local sort = table.sort
local tonumber = tonumber
local unpack = unpack

module("tek.ui.class.meter", tek.ui.class.text)
_VERSION = "Meter 2.1"

-------------------------------------------------------------------------------
--	Class implementation:
-------------------------------------------------------------------------------

local Meter = _M

function Meter.init(self)
	self.NumSamples = self.NumSamples or 256
	self.GraphBGPen = self.GraphBGPen or ui.PEN_DARK
	self.GraphFGPen = self.GraphFGPen or ui.PEN_SHINE
	self.GraphFGPen2 = self.GraphFGPen2 or self.GraphFGPen
	self.GraphFGPen3 = self.GraphFGPen3 or self.GraphFGPen
	self.GraphFGPen4 = self.GraphFGPen4 or self.GraphFGPen
	
	self.GraphPens = { self.GraphFGPen, self.GraphFGPen2, self.GraphFGPen3,
		self.GraphFGPen4 }
	
	self.CaptionsX = self.CaptionsX or 
	{
		{ pri = 100, text = "-1.0" },
		{ pri = 25, text = "-0.5" },
		{ pri = 50, text = "0.0" },
		{ pri = 25, text = "0.5" },
		{ pri = 100, text = "1.0" },
	}
	self.CaptionsY = self.CaptionsY or 
	{
		{ pri = 100, text = "-1.0" },
		{ pri = 25, text = "-0.5" },
		{ pri = 50, text = "0.0" },
		{ pri = 25, text = "0.5" },
		{ pri = 100, text = "1.0" },
	}
	self.Curves = self.Curves or { { } }
	self.EraseBG = true
	self.Font = "ui-small"
	self.GraphRect = false
	self.Height = self.Height or "free"
	self.Padding = ui.NULLOFFS
	self.RedrawGraph = false
	self.TextHAlign = "left"
	self.TextRecordsX = false
	self.TextRecordsY = false
	self.TextRegion = false
	self.TextVAlign = "bottom"
	self.Width = self.Width or "free"
	return Text.init(self)
end

function Meter:layout(x0, y0, x1, y1, markdamage)
	local res = Text.layout(self, x0, y0, x1, y1, markdamage)
	if res then
	
		local d = self.Display
		local font = d:openFont(self.Font)
		local r = self.Rect
		
		local captionheight, captionwidth, _ = 0, 0
		if #self.CaptionsX > 0 then
			_, captionheight = d:getTextSize(font, "")
		end
		
		-- flush text records:
		self.TextRecords = { }
		
		-- generate text records on Y axis:
		local height = r[4] - r[2] - captionheight
		local cy = 0
		local dy = height * 0x10000 / (#self.CaptionsY - 1)
		local tr = { }
		local pris = { }
		for i, c in ipairs(self.CaptionsY) do
			insert(pris, c)
			local tw, th = d:getTextSize(font, c.text)
			local y0 = floor(cy / 0x10000)
			y0 = y0 - floor(th / 2)
			y0 = max(0, min(y0, height - 1 - th)) + captionheight
			c.y0 = y0
			c.y1 = y0 + th - 1
			c.tw = tw
			cy = cy + dy
		end
		sort(pris, function(a, b) return a.pri > b.pri end)
		local final = { }
		for i, c in ipairs(pris) do
			local found
			for j = 1, i - 1 do
				if c.y1 >= pris[j].y0 and c.y0 <= pris[j].y1 then
					found = true
					break
				end
			end
			if not found then
				insert(final, c)
				captionwidth = max(captionwidth, c.tw)
			end
		end
		for _, c in ipairs(final) do
			local t = self:newTextRecord(c.text, font, "left", "bottom", 
				captionwidth - c.tw, 0, 0, c.y0)
			insert(tr, t)
			insert(self.TextRecords, t)
		end
		self.TextRecordsY = tr
		
		
		-- generate text records on X axis:
		local width = r[3] - r[1] - captionwidth
		local cx = 0
		local dx = width * 0x10000 / (#self.CaptionsX - 1)
		tr = { }
		local pris = { }
		for i, c in ipairs(self.CaptionsX) do
			insert(pris, c)
			local tw, th = d:getTextSize(font, c.text)
			local x0 = floor(cx / 0x10000)
			x0 = x0 - floor(tw / 2)
			x0 = max(0, min(x0, width - 1 - tw)) + captionwidth
			c.x0 = x0
			c.x1 = x0 + tw - 1
			cx = cx + dx
		end
		sort(pris, function(a, b) return a.pri > b.pri end)
		for i, c in ipairs(pris) do
			local found
			for j = 1, i - 1 do
				if c.x1 >= pris[j].x0 and c.x0 <= pris[j].x1 then
					found = true
					break
				end
			end
			if not found then
				local t = self:newTextRecord(c.text, font, "left", "bottom",
					c.x0, 0, 0, 0)
				insert(tr, t)
				insert(self.TextRecords, t)
			end
		end
		self.TextRecordsX = tr
		
		
		-- layout all text records:
		self:layoutText()
		
		-- create regions for areas used by captions and graph:
		self.TextRegion = Region.new()
		self.GraphRect = { r[1], r[2], r[3], r[4] }
		local tr = self.TextRecordsX
		local tw, th, x0, y0 = ui.Text:getTextSize(tr)
		if x0 then
			local x1 = x0 + tw - 1
			local y1 = y0 + th - 1
			self.TextRegion:orRect(x0, y0, x1, y1)
			self.GraphRect[4] = y0 - 1
		end
		local tr = self.TextRecordsY
		local tw, th, x0, y0 = ui.Text:getTextSize(tr)
		if x0 then
			local x1 = x0 + tw - 1
			local y1 = y0 + th - 1
			self.TextRegion:orRect(x0, y0, x1, y1)
			self.GraphRect[1] = x1 + 1
		end
		self.TextRegion:andRect(r[1], r[2], r[3], r[4])
		
		self.RedrawGraph = true
		return true
	end
end

function Meter:drawGraph()
	local d = self.Drawable
	local r = self.Rect
	for cnr, c in ipairs(self.Curves) do
		local pen = d.Pens[self.GraphPens[cnr]]
		local x0, y0, x1, y1 = unpack(self.GraphRect)
		local gw = x1 - x0
		local gh = y1 - y0
		local n = self.NumSamples - 1
		local dx = gw * 0x10000 / n
		local y = r[2] + gh
		local v0
		for i = 0, n do
			local v = c[i + 1]
			if not v then
				break
			end
			v = max(min(0xffff, v), 0)
			if i == 0 then
				v0 = v * gh / 0x10000
				x0 = x0 * 0x10000
			else
				local v1 = v * gh / 0x10000
				local x1 = x0 + dx
				local x = x0 / 0x10000
				if x >= r[3] then
					break
				end
				d:drawLine(x, y - v0, min(x1 / 0x10000, r[3]), y - v1, pen)
				x0 = x1
				v0 = v1
			end
		end
	end
end

function Meter:eraseGraphBackground()
	local x0, y0, x1, y1 = unpack(self.GraphRect)
	local d = self.Drawable
	d:fillRect(x0, y0, x1, y1, d.Pens[self.GraphBGPen])
end

function Meter:draw()
	local d = self.Drawable
	self.TextRegion:forEach(d.fillRect, d, self:getBG())
	Text.draw(self)
	local r = self.Rect
	self:eraseGraphBackground()
	self:drawGraph()
end

function Meter:refresh()
	Text.refresh(self)
	if self.RedrawGraph then
		self:eraseGraphBackground()
		self:drawGraph()
		self.RedrawGraph = false
	end
end
