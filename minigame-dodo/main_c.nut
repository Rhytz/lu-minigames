local dodoTimer = null;
local currentScore = 0;
local highestScore = 0;
local localPlayer = FindLocalPlayer();

function onClientEnteredVehicle(veh, seat){
	if(veh.Model == 126 && !dodoTimer){
		dodoTimer = NewTimer("checkDodoScore", 1000, 0, veh);
	}
}

function onClientExitedVehicle(veh){
	if(dodoTimer){
		dodoTimer.Stop();
		dodoTimer.Delete();
		dodoTimer = null;
	}
}

function checkDodoScore(veh){
	if(veh.Airborne){
		currentScore++;
		Message("You are flying!");
		
	}else{
		if(currentScore > highestScore){
			highestScore = currentScore;
			CallServerFunc("lu-minigames/main_s.nut", "setPlayerScore", localPlayer, highestScore);
		}
		currentScore = 0;
	}
}