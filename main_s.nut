//Variable definitions

const MINIGAME_INTERVAL 	= 20; 	//Start a new minigame every X minutes
const PREPARATION_TIME		= 3; 	//Amount of minutes players get to prepare for the minigame
const MGS_VIRTUALWORLD		= 0; 	//In which virtual world the minigames should be held
const SCORE_SOUND			= 147; 	//The sound that is played when a player scores a point
const FINISHED_SOUND		= 0; 	//Sound that played for the contending players when the minigame is finished

Minigame <- []; //Array that will contain all minigames set in minigames.nut

local currentMinigame = null, minigameTimer = null, eligiblePlayers = {}, minigameState = null, playerScores = null, minigameCountdown = null, startTick = null, top3 = null; 

enum State {
	Countdown,
	Started,
	Ended
}

//--

//Util funcs

function random(start, finish)
{
	local t = ((rand() % (finish - start)) + start);
	return t;
}

function sortScores(first, second) {

	local a = first.score;
	local b = second.score;
	
	if (a < b) return 1;
	if (a > b) return -1;
	return 0;	
}

// This function returns 1st/2nd/3rd/4th from an integer
//http://forum.liberty-unleashed.co.uk/index.php/topic,693.0.html
function GetNth ( num )
{
	local lastdigs = num % 100;
	switch ( lastdigs )
	{
		case 11: return num +"th";					// Catch out 11, 111
		case 12: return num +"th";					// Catch out 12, 112
		case 13: return num +"th";					// Catch out 13, 113
		default:						// Everything else should be normal...
			lastdigs = num % 10;							// Get last digit
			switch ( lastdigs )
			{
				case 1: return num +"st";
				case 2: return num +"nd";
				case 3: return num +"rd";
				default: return num +"th";
			}
	}
}


// --

// Event handlers

function onScriptLoad(){
	dofile("Scripts/lu-minigames/minigames.nut");
	
	//Start initial game
	NewTimer("prepareRandomMinigame", 5000, 1);
	
	//Start new minigame every X minutes
	minigameTimer = NewTimer("prepareRandomMinigame", MINIGAME_INTERVAL*60*1000, 0);
	RegisterRemoteFunc("setPlayerScore");
	return 1;
}

function onScriptUnload(){
	if(minigameTimer){
		minigameTimer.Stop();
		minigameTimer.Delete();
	}
	::print("[lu-minigames] Unloaded");	
	return 1;
}

//Add/remove players to the eligiblePlayers if they come back to or leave to the main world
function onPlayerVirtualWorldChange(player, old, new){
	if(!currentMinigame){ return; }
	
	if(new == MGS_VIRTUALWORLD && !eligiblePlayers.rawget(player.ID)){
		minigameInfoToClient(player);
		minigameStateToClient(player);
		minigameTop3ToClient(player);
		eligiblePlayers.rawset(player.ID,player);
	}
	
	if(new != MGS_VIRTUALWORLD && eligiblePlayers.rawget(player.ID)){
		eligiblePlayers.rawdelete(player.ID);
	}
	return 1;
}

//Add players when they spawn
function onPlayerSpawn(player, spawn){
	if(!currentMinigame){ return; }

	if(!eligiblePlayers.rawin(player.ID) && player.VirtualWorld == MGS_VIRTUALWORLD){
		eligiblePlayers.rawset(player.ID,player);
		minigameInfoToClient(player);
		minigameStateToClient(player);
		minigameTop3ToClient(player);
	}
	return 1;
}

//Remove players when they leave
function onPlayerPart(player, reason){
	if(!currentMinigame){ return; }
	
	if(eligiblePlayers.rawin(player.ID)){
		eligiblePlayers.rawdelete(player.ID);
	}
	
	//We need to reset the score, because the player ID may get assigned to someone else.
	playerScores[player.ID] = null;
	return 1;
}

// --

//Only select players that are spawned and in the main world
function getEligiblePlayers(){
	for (local player, id = 0, count = GetMaxPlayers(); id < count; id++){
		if(player = FindPlayer(id)){
			if(player.Spawned && player.VirtualWorld == MGS_VIRTUALWORLD){
				eligiblePlayers.rawset(id,player);
			}
		}		
	}
}

function prepareRandomMinigame(){
	//Fetch random minigame from the minigames.nut file
	currentMinigame = Minigame[random(0, Minigame.len())];
	::print("[lu-minigames] Preparing " + currentMinigame.name);
	LoadScript("lu-minigames/" + currentMinigame.folder);
	minigameState = State.Countdown;
	//CallFunc("lu-minigames/" + currentMinigame.folder, "onMinigameStateChange", minigameState);
	getEligiblePlayers();
	
	//x Minutes of preparation time
	minigameCountdown = PREPARATION_TIME*60*1000;
	
	playerScores = array(GetMaxPlayers(), null);
	top3 = array(3, {name = null, score = null});
	
	startTick = GetTickCount();
	
	foreach(id, player in eligiblePlayers){
		minigameInfoToClient(player);
		minigameStateToClient(player);
	}	
	NewTimer("startMinigame", minigameCountdown, 1);
}

function startMinigame(){
	minigameState = State.Started;
	//CallFunc("lu-minigames/" + currentMinigame.folder, "onMinigameStateChange", minigameState);
	startTick = GetTickCount();
	
	minigameCountdown = currentMinigame.duration * 1000;
	foreach(id, player in eligiblePlayers){
		minigameStateToClient(player);
	}
	NewTimer("stopMinigame", minigameCountdown, 1);
}

function stopMinigame(){
	minigameState = State.Ended;
	//CallFunc("lu-minigames/" + currentMinigame.folder, "onMinigameStateChange", minigameState);
	foreach(id, player in eligiblePlayers){
		minigameStateToClient(player);
	}
	
	payoutPlayers();
	::print("[lu-minigames] Ending " + currentMinigame.name);
	UnloadScript("lu-minigames/" + currentMinigame.folder);
	currentMinigame = null;
	eligiblePlayers = {};
	minigameState = null;	
}

function payoutPlayers(){
	local topArray = [];
	foreach(scoreInfo in playerScores){
		if(scoreInfo){
			topArray.push({player = scoreInfo.player, score = scoreInfo.score});
		}
	}
	
	topArray.sort(sortScores);
	local _payout = currentMinigame.payout;
	foreach(pos, scoreInfo in topArray){		
		if(scoreInfo.player){  		
			local realpos = GetNth(pos + 1);
			scoreInfo.player.Cash += _payout;
			BigMessage(scoreInfo.player, "You came " + realpos + " in " + currentMinigame.name, 5000, 3);
			//PlayFrontEndSound(player, FINISHED_SOUND); //Have to look up the ID for the mission finished music some time		
			_payout = abs(_payout * 0.8);			
		}
	}
}

function setPlayerScore(player, score){
	if(minigameState != State.Started){ return; }
	
	score = score.tointeger();
	if(!playerScores[player.ID]){ 
		playerScores[player.ID] = {player = player, score = 0}; 
	}
	
	playerScores[player.ID].score += score;
	
	PlayFrontEndSound(player, SCORE_SOUND);
	
    local topArray = [];
    foreach(idx, scoreInfo in playerScores){
        if(scoreInfo){
            topArray.push({player = scoreInfo.player, score = scoreInfo.score});
        }
    }   
    topArray.sort(sortScores);
	
	//We only want to send a new top3 to the client if it was updated
	local topUpdated = null;
	local i = 0;
	foreach(scoreInfo in topArray){
		//So we don't run into errors with less than 3 players in the rankings
		if(i in topArray){			
			if(scoreInfo.player){			
				if(scoreInfo.score > top3[i].score){
					topUpdated = true;					
				}
				top3[i] = {name = scoreInfo.player.Name, score = scoreInfo.score}
			}
		}
		i++;
		if(i >= 3){
			break;
		}			
	}
	
	if(topUpdated){
		foreach(player in eligiblePlayers){
			minigameTop3ToClient(player);
		}
	}
}

function minigameInfoToClient(player){
	CallClientFunc( player, "lu-minigames/main_c.nut", "minigameInfo", currentMinigame.name, currentMinigame.description, currentMinigame.duration, currentMinigame.currency );
}

function minigameStateToClient(player){
	local timeLeft = (minigameCountdown - (GetTickCount() - startTick)) / 1000;
	CallClientFunc( player, "lu-minigames/main_c.nut", "minigameState", minigameState, timeLeft );
}

function minigameTop3ToClient(player){
	if(minigameState == State.Started){
		CallClientFunc( player, "lu-minigames/main_c.nut", "updateCurrentScore", top3[0].name, top3[0].score, top3[1].name, top3[1].score, top3[2].name, top3[2].score);
	}	
}