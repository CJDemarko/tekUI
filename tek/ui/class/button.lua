-------------------------------------------------------------------------------
--
--	tek.ui.class.button
--	Written by Timm S. Mueller <tmueller at schulze-mueller.de>
--	See copyright notice in COPYRIGHT
--
--	LINEAGE::
--		[[#ClassOverview]] :
--		[[#tek.class : Class]] /
--		[[#tek.class.object : Object]] /
--		[[#tek.ui.class.element : Element]] /
--		[[#tek.ui.class.area : Area]] /
--		[[#tek.ui.class.frame : Frame]] /
--		[[#tek.ui.class.gadget : Gadget]] /
--		[[#tek.ui.class.gadget : Text]] /
--		Button
--
--	OVERVIEW::
--		The Button class implements a Text element with a {{"button"}}
--		{{Mode}} (behavior) and {{"button"}} {{Class}} (appearance). In
--		addition to that, it enables the initialization of a possible
--		keyboard shortcut from a special initiatory character (by default
--		an underscore) preceding a letter in the element's {{Text}} attribute.
--
--	NOTES::
--		This class adds redundancy, because it differs from the
--		[[#tek.ui.class.gadget : Text]] class only in that it specifies a few
--		attributes differently in its {{new()}} method. To avoid this overhead,
--		use the Text class directly, or create a ''Button factory'' like this:
--				function newButton(text)
--				  return ui.Text:new { Mode = "button", Class = "button",
--				    Text = text, KeyCode = true }
--				end
--
-------------------------------------------------------------------------------

local ui = require "tek.ui"
local Text = ui.Text

module("tek.ui.class.button", tek.ui.class.text)
_VERSION = "Button 1.3"

-------------------------------------------------------------------------------
--	Class implementation:
-------------------------------------------------------------------------------

local Button = _M

function Button.init(self)
	self.Mode = self.Mode or "button"
	self.Class = self.Class or "button"
	self.KeyCode = self.KeyCode == nil and true or self.KeyCode
	return Text.init(self)
end
