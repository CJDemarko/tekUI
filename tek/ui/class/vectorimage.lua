
--
--	tek.ui.class.vectorimage
--	Written by Timm S. Mueller <tmueller at schulze-mueller.de>
--	See copyright notice in COPYRIGHT
--
--	OVERVIEW::
--	Implements vector graphics rendering
--

local Class = require "tek.class"
module("tek.ui.class.vectorimage", tek.class)
_VERSION = "VectorImage 2.0"
local VectorImage = _M

function VectorImage.new(class, self)
	-- Background painted completely?
	self.Transparent = self.Transparent or false
	return Class.new(class, self)
end

function VectorImage:draw(d, r1, r2, r3, r4)
	d:drawImage(self, r1, r2, r3, r4, d.Pens)
end

function VectorImage:askWidthHeight(w, h)
	return w, h
end
