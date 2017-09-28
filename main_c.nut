//Util funcs

function formatTime(seconds){
	local niceTime = date(seconds);
	if(niceTime["sec"] < 10){ niceTime["sec"] = "0" + niceTime["sec"]; }
	return niceTime["min"] + ":" + niceTime["sec"];
}

// --

local minigameName, minigameDescription, minigameDuration, minigameCurrency, seenDescription = null;

enum State {
	Countdown,
	Started,
	Ended
}

function minigameState(state, seconds){
	if(state == State.Countdown){
		minigameCountdown(seconds);
	}else if(state == State.Started){
		minigameStarted();
		updateGUI(seconds);
	}else if(state == State.Ended){
		minigameEnded(); 
	}
}

function minigameInfo(name, description, duration, currency){
	minigameName = name;
	minigameDescription = description;
	minigameDuration = duration;
	minigameCurrency = currency;
}

function minigameCountdown(seconds){
	if(seconds >= 1 && seconds <= 3){
		PlayFrontEndSound(147);
	}
	if(seconds == 0){
		PlayFrontEndSound(148);
		SmallMessage(minigameDescription, 5000, 2);
		seenDescription = true;
	}
		
	local niceTime = formatTime(seconds);
	
	if(seconds >= 1){
		SmallMessage(minigameName + " starts in " + niceTime, 1000, 5);
		NewTimer("minigameCountdown", 1000, 1, seconds-1);
	}
}

function minigameStarted(){
	//If a player joins when the minigame is already running
	if(!seenDescription){
		SmallMessage(minigameDescription, 5000, 2);
	}
	
	scoreWindow.Visible = true;
}

function minigameEnded(){
	posOne.Text = "";
	posTwo.Text = "";
	posThree.Text = "";
	scoreWindow.Visible = false;

}

function updateCurrentScore(name1, score1, name2, score2, name3, score3){
	local top3 = [];
	
	if(name1 && score1){
		top3.push({name = name1, score = score1.tointeger()});
	}
	
	if(name2 && score2){
		top3.push({name = name2, score = score2.tointeger()});
	}
		
	if(name3 && score3){
		top3.push({name = name3, score = score3.tointeger()});
	}	
	
	foreach(id, scoredetails in top3){
		switch(minigameCurrency){
			case("time"):
				top3[id].score = formatTime(scoredetails.score);		
			break;
		}	
	}
	
	if(0 in top3){
		posOne.Text = "1st: " + top3[0].name + " - " + top3[0].score;
	}
	if(1 in top3){
		posTwo.Text = "2nd: " + top3[1].name + " - " + top3[1].score;
	}
	if(2 in top3){
		posThree.Text = "3rd: " + top3[2].name + " - " + top3[2].score;
	}
	/*
	currentLabel.Text = "Current:  " + drawScore;
	if(score > bestScore){
		yourBestLabel.Text = "Your best: " + drawScore;
		bestScore = score;
	}
	*/
}

function updateGUI(seconds){
	local niceTime = formatTime(seconds);
	
	timeLabel.Text = "Time left: " + niceTime; 
	
	if(seconds >= 1){
		NewTimer("updateGUI", 1000, 1, seconds-1);
	}
}

function onScriptLoad(){
	//this is just a mess, need to rethink this later
	local pos = VectorScreen(ScreenWidth-260,ScreenHeight-190);
	local size = ScreenSize(260,190);
	scoreWindow <- GUIWindow(pos,size,"Scorewindow");
	scoreWindow.Titlebar = false;
	scoreWindow.Colour = Colour(0,0,0);
	scoreWindow.Alpha = 200;
	AddGUILayer(scoreWindow);

	posOne <- GUILabel(VectorScreen(10, 10), ScreenSize( 180, 10 ), "1st:");
	posOne.TextColour = Colour(205,172,92);
	posOne.FontSize = 16;

	posTwo <- GUILabel(VectorScreen(10, 40), ScreenSize( 180, 10 ), "2nd:");
	posTwo.TextColour = Colour(150,150,150);
	posTwo.FontSize = 16;
	
	posThree <- GUILabel(VectorScreen(10, 70), ScreenSize( 180, 10 ), "3rd:");
	posThree.TextColour = Colour(187,135,100);
	posThree.FontSize = 16;		
	
	yourBestLabel <- GUILabel(VectorScreen(10, 110), ScreenSize( 180, 10 ), "Your best: ");
	yourBestLabel.TextColour = Colour(255,255,255);
	yourBestLabel.FontSize = 16;			
	
	currentLabel <- GUILabel(VectorScreen(10, 135), ScreenSize( 180, 10 ), "Current: ");
	currentLabel.TextColour = Colour(255,255,255);
	currentLabel.FontSize = 16;			
	
	timeLabel <- GUILabel(VectorScreen(10, 160), ScreenSize( 180, 10 ), "Time left: ");
	timeLabel.TextColour = Colour(255,255,255);
	timeLabel.FontSize = 16;
	//timeLabel.TextAlignment = ALIGN_MIDDLE_CENTER;
	// Create a laer for our new window
	scoreWindow.AddChild(yourBestLabel);
	scoreWindow.AddChild(currentLabel);	
	scoreWindow.AddChild(posOne);	
	scoreWindow.AddChild(posTwo);	
	scoreWindow.AddChild(posThree);	
	
	scoreWindow.AddChild(timeLabel);	
	if(minigameCurrency == "number"){
		yourBestLabel.Visible = false;
		currentLabel.Visible = false;
	}else{
		yourBestLabel.Visible = true;
		currentLabel.Visible = true;	
	}
	scoreWindow.Visible = false;
}