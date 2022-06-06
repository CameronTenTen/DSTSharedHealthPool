name = "Shared Health Pool"
description = "The health of all players is combined into one pool"
author = "camerontenten"
version = "0.1"
forumthread = ""
api_version = 10
all_clients_require_mod = true
client_only_mod = false
dst_compatible = true
icon_atlas = "modicon.xml"
icon = "modicon.tex"
server_filter_tags = {"Shared", "Health", "Pool"}

-- MarginValues = {}
-- for i=1, 101 do
-- 	MarginValues[i] = {description = "" .. ((i - 1)) * 10, data = ((i - 1) * 10)}
-- end


-- -- took this from globalposition
-- local KEY_A = 65
-- local keyslist = {}
-- local string = "" -- can't believe I have to do this... -____-
-- for i = 1, 26 do
-- 	local ch = string.char(KEY_A + i - 1)
-- 	keyslist[i] = {description = ch, data = ch}
-- end
-- {
--     name = "KEYBOARDTOGGLEKEY",
--     label = "Toggle key",
--     hover = "The key hotkey to toggle the pause state.",
--     options = keyslist,
--     default = "P", --P
-- },


-- {
--     {description = "30s", data = 30},
--     {description = "2 min", data = 120},
--     {description = "4 min", data = 240},
--     {description = "1 day", data = 480},
--     {description = "2 day", data = 960},
-- },

configuration_options =
{
	{
		name = "FREEZE_LENGTH",
		label = "Freeze Length",
		hover = "How long should the freeze last",
		options =
		{
			{description = "0", data = 0},
			{description = "5", data = 5},
			{description = "10", data = 10},
			{description = "20", data = 20}

		},
		default = 20
	},
}
-- configuration_options =
-- {
-- 	{
-- 		name = "Health",
-- 		label = "Share Health",
-- 		hover = "If health is shared.",
-- 		options =
-- 		{
-- 			{description = "True", data = 1},
-- 			{description = "False", data = 0}
--
-- 		},
-- 		default = 1
-- 	},
-- 	{
-- 		name = "Hunger",
-- 		label = "Share Hunger",
-- 		hover = "If hunger is shared.",
-- 		options =
-- 		{
-- 			{description = "True", data = 1},
-- 			{description = "False", data = 0}
--
-- 		},
-- 		default = 1
-- 	},
-- 	{
-- 		name = "Sanity",
-- 		label = "Share Sanity",
-- 		hover = "If sanity is shared.",
-- 		options =
-- 		{
-- 			{description = "True", data = 1},
-- 			{description = "False", data = 0}
--
-- 		},
-- 		default = 1
-- 	},
-- 	{
-- 		name = "Moisture",
-- 		label = "Share Moisture",
-- 		hover = "If moisture is shared.",
-- 		options =
-- 		{
-- 			{description = "True", data = 1},
-- 			{description = "False", data = 0}
--
-- 		},
-- 		default = 0
-- 	}
--
-- }
