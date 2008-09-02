#!/usr/bin/env lua

local ui = require "tek.ui"

local window = ui.Window:new
{
	Status = "hide",
	Id = "buttons-window",
	Notifications =
	{
		["Status"] =
		{
			["show"] =
			{
				{ ui.NOTIFY_ID, "buttons-window-button", "setValue", "Selected", true }
			},
			["hide"] =
			{
				{ ui.NOTIFY_ID, "buttons-window-button", "setValue", "Selected", false }
			},
		},
	},
	Style = "Width: auto; Height: auto",
	Title = "Buttons",
	SameSize = true,
	Children =
	{
		ui.Group:new
		{
			Orientation = "vertical",
			Legend = "Caption Style",
			Style = "height: fill",
			Children =
			{
				ui.Text:new { Class = "caption", Text = "Small",
					Style = "font: ui-small" },
				ui.Text:new { Class = "caption", Text = "Main",
					Style = "font: ui-main" },
				ui.Text:new { Class = "caption", Text = "Large",
					Style = "font: ui-large" },
				ui.Text:new { Class = "caption", Text = "Huge",
					Style = "font: ui-huge" },
				ui.Text:new { Class = "caption", Text = "Fixed",
					Style = "font: ui-fixed" },
			},
		},
		ui.Group:new
		{
			Orientation = "vertical",
			Legend = "Normal Style",
			Style = "height: fill",
			Children =
			{
				ui.Text:new { Text = "Small",
					Style = "font: ui-small" },
				ui.Text:new { Text = "Main",
					Style = "font: ui-main" },
				ui.Text:new { Text = "Large",
					Style = "font: ui-large" },
				ui.Text:new { Text = "Huge",
					Style = "font: ui-huge" },
				ui.Text:new { Text = "Fixed",
					Style = "font: ui-fixed" },
			},
		},
		ui.Group:new
		{
			Orientation = "vertical",
			Legend = "Button Style",
			Style = "height: fill",
			Children =
			{
				ui.Text:new { Mode = "button", Class = "button", Text = "Small",
					Style = "font: ui-small" },
				ui.Text:new { Mode = "button", Class = "button", Text = "Main",
					Style = "font: ui-main" },
				ui.Text:new { Mode = "button", Class = "button", Text = "Large",
					Style = "font: ui-large" },
				ui.Text:new { Mode = "button", Class = "button", Text = "Huge",
					Style = "font: ui-huge" },
				ui.Text:new { Mode = "button", Class = "button", Text = "Fixed",
					Style = "font: ui-fixed" },
			},
		},
		ui.Group:new
		{
			Orientation = "vertical",
			Legend = "Colors",
			Style = "height: fill",
			Children =
			{
				ui.Text:new { Mode = "button", Class = "button", Text = "Button",
					Style = "background-color: dark; color: shine" },
				ui.Text:new { Mode = "button", Class = "button", Text = "Button",
					Style = "background-color: shadow; color: shine" },
				ui.Text:new { Mode = "button", Class = "button", Text = "Button",
					Style = "background-color: half-shadow; color: shine" },
				ui.Text:new { Mode = "button", Class = "button", Text = "Button",
					Style = "background-color: background; color: detail" },
				ui.Text:new { Mode = "button", Class = "button", Text = "Button",
					Style = "background-color: half-shine; color: dark" },
				ui.Text:new { Mode = "button", Class = "button", Text = "Button",
					Style = "background-color: shine; color: dark" },
			},
		},
		ui.Group:new
		{
			Orientation = "vertical",
			Legend = "Text Alignments",
			Style = "height: fill",
			SameHeight = true,
			Children =
			{
				ui.Text:new { Mode = "button", Class = "button", Text = "Top\nLeft",
					Style = "text-align: left; vertical-align: top; height: free" },
				ui.Text:new { Mode = "button", Class = "button", Text = "Center",
					Style = "text-align: center; vertical-align: center; height: free" },
				ui.Text:new { Mode = "button", Class = "button", Text = "Right\nBottom",
					Style = "text-align: right; vertical-align: bottom; height: free" },
			},
		},
	}
}

if ui.ProgName == "buttons.lua" then
	local app = ui.Application:new()
	ui.Application.connect(window)
	app:addMember(window)
	window:setValue("Status", "show")
	app:run()
else
	return
	{
		Window = window,
		Name = "Buttons",
		Description = [[
			Buttons
		]]
	}
end
