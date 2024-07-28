-- translation
local S = minetest.get_translator("mail")

local FORMNAME = "mail:settings"

local date_formats = {"%Y-%m-%d %X", "%d/%m/%y %X", "%A %d %B %Y %X"}

function mail.show_settings(name)
    -- date formats prepare
    local dates_now = {}
    local previous_date_format = mail.get_setting(name, "date_format")
    local date_dropdown_index = 1
    for i, f in pairs(date_formats) do
        table.insert(dates_now, os.date(f, os.time()))
        if f == previous_date_format then date_dropdown_index = i end
    end
    local date_dropdown_str = table.concat(dates_now, ",")

	local formspec = [[
			size[10,6;]
			tabheader[0.3,1;optionstab;]] .. S("Settings") .. "," .. S("About") .. [[;1;false;false]
			button[9.35,0;0.75,0.5;back;X]

			box[0,0.8;3,0.45;]] .. mail.colors.highlighted .. [[]
			label[0.2,0.8;]] .. S("Notifications") .. [[]
            checkbox[0,1.2;chat_notifications;]] .. S("Chat notifications") .. [[;]] ..
            tostring(mail.get_setting(name, "chat_notifications")) .. [[]
            checkbox[0,1.6;onjoin_notifications;]] .. S("On join notifications") .. [[;]] ..
            tostring(mail.get_setting(name, "onjoin_notifications")) .. [[]
            checkbox[0,2.0;hud_notifications;]] .. S("HUD notifications") .. [[;]] ..
            tostring(mail.get_setting(name, "hud_notifications")) .. [[]
            checkbox[0,2.4;sound_notifications;]] .. S("Sound notifications") .. [[;]] ..
            tostring(mail.get_setting(name, "sound_notifications")) .. [[]

			box[5,0.8;3,0.45;]] .. mail.colors.highlighted .. [[]
			label[5.2,0.8;]] .. S("Message list") .. [[]
            checkbox[5,1.2;unreadcolorenable;]] .. S("Show unread in different color") .. [[;]] ..
            tostring(mail.get_setting(name, "unreadcolorenable")) .. [[]
            checkbox[5,1.6;cccolorenable;]] .. S("Show CC/BCC in different color") .. [[;]] ..
            tostring(mail.get_setting(name, "cccolorenable")) .. [[]

			label[5,2.6;]] .. S("Default sorting fields") .. [[]
            dropdown[5.5,3.0;2,0.5;defaultsortfield;]] ..
            S("From/To") .. "," .. S("Subject") .. "," .. S("Date") .. [[;]] ..
            tostring(mail.get_setting(name, "defaultsortfield")) .. [[;true]
            dropdown[7.5,3.0;2,0.5;defaultsortdirection;]] ..
            S("Ascending") .. "," .. S("Descending") .. [[;]] ..
            tostring(mail.get_setting(name, "defaultsortdirection")) .. [[;true]

			box[0,3.2;3,0.45;]] .. mail.colors.highlighted .. [[]
			label[0.2,3.2;]] .. S("Other") .. [[]
            checkbox[0,3.6;trash_move_enable;]] .. S("Move deleted messages to trash") .. [[;]] ..
            tostring(mail.get_setting(name, "trash_move_enable")) .. [[]
            checkbox[0,4.0;auto_marking_read;]] .. S("Automatic marking read") .. [[;]] ..
            tostring(mail.get_setting(name, "auto_marking_read")) .. [[]
			label[0.31,4.7;]] .. S("Date format:") .. [[]
            dropdown[2.7,4.6;4,0.5;date_format;]] .. date_dropdown_str .. [[;]] ..
            tostring(date_dropdown_index) .. [[;true]

            tooltip[chat_notifications;]] .. S("Receive a message in the chat when there is a new message") .. [[]
            tooltip[onjoin_notifications;]] .. S("Receive a message at login when inbox isn't empty") .. [[]
            tooltip[hud_notifications;]] .. S("Show an HUD notification when inbox isn't empty") .. [[]
            tooltip[sound_notifications;]] .. S("Play a sound when there is a new message") .. [[]
            tooltip[auto_marking_read;]] .. S("Mark a message as read when opened") .. [[]

            button[0,5.5;2.5,0.5;save;]] .. S("Save") .. [[]
            button[2.7,5.5;2.5,0.5;reset;]] .. S("Reset") .. [[]
            ]] .. mail.theme

	minetest.show_formspec(name, FORMNAME, formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= FORMNAME then
		return
	end

    local playername = player:get_player_name()

	if fields.back then
		mail.show_mail_menu(playername)
		return

    elseif fields.optionstab == "1" then
        mail.selected_idxs.optionstab[playername] = 1

    elseif fields.optionstab == "2" then
        mail.selected_idxs.optionstab[playername] = 2
        mail.show_about(playername)
        return

    elseif fields.chat_notifications then
        mail.selected_idxs.chat_notifications[playername] = fields.chat_notifications == "true"

    elseif fields.onjoin_notifications then
        mail.selected_idxs.onjoin_notifications[playername] = fields.onjoin_notifications == "true"

    elseif fields.hud_notifications then
        mail.selected_idxs.hud_notifications[playername] = fields.hud_notifications == "true"

    elseif fields.sound_notifications then
        mail.selected_idxs.sound_notifications[playername] = fields.sound_notifications == "true"

    elseif fields.unreadcolorenable then
        mail.selected_idxs.unreadcolorenable[playername] = fields.unreadcolorenable == "true"

    elseif fields.cccolorenable then
        mail.selected_idxs.cccolorenable[playername] = fields.cccolorenable == "true"

    elseif fields.trash_move_enable then
        mail.selected_idxs.trash_move_enable[playername] = fields.trash_move_enable == "true"

    elseif fields.auto_marking_read then
        mail.selected_idxs.auto_marking_read[playername] = fields.auto_marking_read == "true"

    elseif fields.save then
        -- checkboxes
        mail.set_setting(playername, "chat_notifications", mail.selected_idxs.chat_notifications[playername])
        mail.set_setting(playername, "onjoin_notifications", mail.selected_idxs.onjoin_notifications[playername])
        mail.set_setting(playername, "hud_notifications", mail.selected_idxs.hud_notifications[playername])
        mail.set_setting(playername, "sound_notifications", mail.selected_idxs.sound_notifications[playername])
        mail.set_setting(playername, "unreadcolorenable", mail.selected_idxs.unreadcolorenable[playername])
        mail.set_setting(playername, "cccolorenable", mail.selected_idxs.cccolorenable[playername])
        mail.set_setting(playername, "trash_move_enable", mail.selected_idxs.trash_move_enable[playername])
        mail.set_setting(playername, "auto_marking_read", mail.selected_idxs.auto_marking_read[playername])
        -- dropdowns
        local defaultsortfield = fields.defaultsortfield or mail.get_setting(playername, "defaultsortfield")
        local defaultsortdirection = fields.defaultsortdirection or mail.get_setting(playername, "defaultsortdirection")
        local date_format = date_formats[tonumber(fields.date_format)] or mail.get_setting(playername, "date_format")
        mail.set_setting(playername, "defaultsortfield", tonumber(defaultsortfield))
        mail.set_setting(playername, "defaultsortdirection", tonumber(defaultsortdirection))
        mail.set_setting(playername, "date_format", date_format)
        -- update visuals
        mail.hud_update(playername, mail.get_storage_entry(playername).inbox)
        mail.show_settings(playername)

    elseif fields.reset then
        mail.reset_settings(playername)
        mail.show_settings(playername)
	end
	return
end)
