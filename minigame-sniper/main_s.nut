function onScriptLoad(){	
	print("Sniper minigame loaded");
}

function onPlayerSpawn(player, spawn){
	player.SetWeapon(WEP_SNIPER);
}

function onPlayerKill( killer, player, reason, bodypart ){
	if (killer.Weapon == WEP_SNIPER)
	{		
		CallFunc("Scripts/lu-minigames/main_s.nut", "setPlayerScore", killer, 1);
	}
}