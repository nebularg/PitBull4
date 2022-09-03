
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then
	C_Timer.After(5, function()
		print("You are using the Classic version of PitBull4. Reinstall the retail version of PitBull4 and relaunch WoW. If you use the Twitch client, exit out and reopen it to make sure you have the latest version.")
	end)
end
