function onScriptLoad(){	
	print("Headshot minigame loaded");
}

function onPlayerSpawn(player, spawn){
	player.SetWeapon(4);
}

function onPlayerKill( killer, player, reason, bodypart ){
	if (bodypart == BODYPART_HEAD)
	{		
		CallFunc("Scripts/lu-minigames/main_s.nut", "setPlayerScore", killer, 1);
	}
}