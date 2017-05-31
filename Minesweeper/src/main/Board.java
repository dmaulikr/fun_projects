package main;

import java.util.Random;


// Litao Chen		2017.05.30
// Terminal version of MineSweeper game 
// difficulty		No. of mines	board size:
// easy:			10				8X8	
// hard:			40				16X16	
// expert:			99				16X30

// ***************************************************************************************************************
// This board contains a simple AI to help user select next move
// Basic idea: 
// - The key is to find out definitive risk like 100 and 0. Then based on these risk numbers to 
//   calculate the risk of unknown spots.
// - use known hint to calculate risk of each unopened spot, simply even distribution of the risk.
//
// - To improve accuracy, before normal evaluation, do the risk evaluation in the order of:
//   -> go over the board to find easy mines: like hint is two and you got 2 unopened spots around it
//
//   -> go over the board to exclude non-mine spot:	like the undistributed risk is 0 but there are unopened spots
//      *: It is important to limit the second step to the spots with known mines
//           Otherwise you may get many false no-risk spot!!!
//
//   -> go over the board to find the spot like you have 1 mine and two spots waiting. Consider these two spots as
// 		one mine, check surrounding spots to utilize this info to find more 100 or 0.
//   -> start the normal evaluation.
//
//  Over all this AI works quite well, despite sometimes you got fake 0 risk spots. Have fun!
//  Improvment can be done:
//  - add more routines to the evaluation process, like two or three consecutive "1"s.
//  - go to more advanced data sutrcture like ArraySet<> to sort and process the easy spots at the beginning
//  - those changes can improve algorithm speed and accuracy.
// **************************************************************************************************************

public class Board {
	// marks for mines and flags
	private static final char MINE = '#';
	private static final char FLAG = '&';
	
	//settings of each difficulty level: rows, columns, number of mines.
	// row 0 for easy; row 1 for hard; row 3 for expert
	private static final int[][] levels ={
			{8, 8, 10},
			{16, 16, 40},
			{16, 30, 90}
	}; 

	// 3D array to represent the boards for each difficulty levels.
	// the third dimension stored four pieces of info in the oder of: [ Mine, Visit, Hint, Flag ]
	// 0: is here a mine?; 1: is this spot visited?; 
	// 2: how many mines around this spot; 3: is this spot flagged by user?
	// target board according to user's selection
	// In the AIboard, we use the first element to store the probability*100 of that the spot has mine.
	// and the last element for the number of unvisited spots: [ Risk, Visit, Hint, blindSpot ]
	private int[][][] selectedBoard;
	private int[][][] boardForAI;  // board for the AI function
	
	// variables for checking and AI
	private int spotsLeft;
	private int[] safeSpot = {999, 999, 100};  // [row, column, probability]
	
	//constructor
	public Board(int level){
		initBoard(level);
	}
	
	
	// initiate the main board and AI board
	// The difference between this board and main board is it only record the hints for visited position
	// The board will be updated along with the main board with the above rule
	// here we simply set up a empty board as the starting point since no visited spot	
	void initBoard(int level) {
		boardForAI = new int[levels[level][0]][levels[level][1]][4];
		initAIBoard(level);
		selectedBoard = new int[levels[level][0]][levels[level][1]][4];
		spotsLeft = selectedBoard.length * selectedBoard[0].length - levels[level][2];
		setMines(level);
		setHints();
		
	}
	
	// initiate AI board: The number of unvisited spots and default risk is set to -1 as a mark
	void initAIBoard(int level) {	
		for(int i = 0; i < boardForAI.length; i++) {
			for(int j = 0; j < boardForAI[0].length; j++) {
				if(i == 0 || i == boardForAI.length - 1) {  //edge row
					if(j == 0 || j == boardForAI[0].length - 1) // edge columns
						boardForAI[i][j][3] = 3;
					else
						boardForAI[i][j][3] = 5;
				}
				else if(j == 0 || j == boardForAI[0].length - 1) // edge columns
					boardForAI[i][j][3] = 5;
				else
					boardForAI[i][j][3] = 8;  // maximum 8
				boardForAI[i][j][0] = -1;  // set default risk to -1 (simply a mark)
			}
			
		}
	}
	
	// set mines
	void setMines(int level) {
		int totalPos = selectedBoard.length * selectedBoard[0].length;
		int totalMines = levels[level][2];
		// shuffle the position of the mines
		final int[] minesPos = 
				new Random().ints(0, totalPos).distinct().limit(totalMines).toArray();
		
		// set the mines in the board	
		int columns = selectedBoard[0].length;
		for(int i = 0; i < minesPos.length; i++) {
			int rowIndex = minesPos[i] / columns;
			int colIndex = minesPos[i] % columns;
			
			selectedBoard[rowIndex][colIndex][0] = 1;
		}
	}
	
	// set hints for each spot
	void setHints() {
		for(int i = 0; i < selectedBoard.length; i++) {  // go through each row
			for(int j = 0; j < selectedBoard[0].length; j++) { //go through each spot in a row
				if(selectedBoard[i][j][0] == 1)  // here is a mine
					continue;				// no need to calculate hints
				else
					setHint(i, j);
			}
		}
	}
	
	// calculate the number of mines around a spot
	void setHint(int rowIndex, int colIndex) {
		int hint = 0;
		
		for(int i = rowIndex-1; i <= rowIndex+1; i++) {
			if(i < 0 || i >= selectedBoard.length)  //out of boundary
				continue;
			else
				for(int j = colIndex-1; j <= colIndex+1; j++) {
					if(j < 0 || j >= selectedBoard[0].length)
						continue;
					else
						hint += selectedBoard[i][j][0];
				}
		}
		
		selectedBoard[rowIndex][colIndex][2] = hint;
	}
	
	
	// print the board in terminal
	// mode: 0 for normal, 1 for solution after game over or win, 2 for printing AIBoard
	void printBoard(int mode) {
		int[][][] boardToPrint = (mode == 2)? boardForAI : selectedBoard;

		if(mode == 2)
			System.out.println("Risk evaluation from AI:");	
		
		printTopIndex(boardToPrint[0].length);
		printHorzLine(boardToPrint[0].length);
		for(int i = 0; i < boardToPrint.length; i++){  // each row
			System.out.print(i + " | ");
			for(int j = 0; j < boardToPrint[0].length; j++) {  // each column
				printContent(boardToPrint, i, j, mode);
			}
			System.out.println("");
			printHorzLine(boardToPrint[0].length); // bottom line separator
		}
		if(mode == 2) 
			nextStep();
	}

	// print the required content based on the status of the spot
	// if not visited:
	// 		if not flagged: show as blank
	// 		if flagged: 	show as flag
	// if visited: show hints
	// mode: 0 for normal mode; 1 to show all the mines after game over, 2 to print AIboard(risk)
	
	void printContent(int[][][] boardToPrint, int rowIndex, int colIndex, int mode) {
		int isMine =   boardToPrint[rowIndex][colIndex][0];
		int visited =  boardToPrint[rowIndex][colIndex][1];
		int hint = boardToPrint[rowIndex][colIndex][2];
		int isFlagged = boardToPrint[rowIndex][colIndex][3];	
		
		if(mode == 0 || mode == 2) {  //normal mode
			if(visited == 0) {  //not visited
				if(mode == 2)  // AI, need to print risk evaluated by AI
					System.out.print(isMine + " ");	 // print risk evaluation
				else if(isFlagged == 1)  //flagged
					System.out.print(FLAG + "  ");
				else
					System.out.print("   ");
			}
			else if(mode == 2)
				System.out.print("_" + hint + "_");
			else
				System.out.print(hint + "  ");
		}
		else { //game is over, print solution
			if(isMine == 1)
				System.out.print(MINE + "  ");
			else
				System.out.print(hint + "  ");
		} 
		System.out.print("|  ");
	}
	
	// print top index
	void printTopIndex(int columns){
		System.out.println("Spots left: " + spotsLeft);
		System.out.print("   ");
		for(int i = 0; i < columns; i++) {
			System.out.print(i + "     ");
		}
		System.out.println();
	}
	
	
	
	// print horizontal line separator, helper method for print board
	void printHorzLine(int columns) {
		System.out.print("  ");
		for(int i = 0; i < columns; i++) {
			System.out.print("______");
		}
		System.out.println("");
	}
	
	// update the board with user's input
	// isFlag: 0 for open; None zero for flag
	// return value:
	// -1:	invalid index
	// 0:	OK
	// 1: 	win
	// 2:	game over
	int updateBoard(int rowIndex, int colIndex, int isFlag) {
		if(rowIndex >= selectedBoard.length || colIndex >= selectedBoard[0].length)
			return -1;
		
		if(isFlag == 0) {  //user open the spot
			if( selectedBoard[rowIndex][colIndex][0] == 1 ) { // hit a mine, game over
				printBoard(1);
				return 2;
			}
			openSpot(rowIndex, colIndex);
			
			if(spotsLeft == 0) {
				printBoard(1);
				return 1;
			}
		}
		else // user want to flag / unflag this spot as a mine
			selectedBoard[rowIndex][colIndex][3] = 
						(selectedBoard[rowIndex][colIndex][3] == 1)? 0 : 1;  // update flag
		
		resetRisk();  // prepared for next round of AI risk evaluation.
		printBoard(0);
		AI();
		
//		for test
//		printBoard(2);
//		nextStep();
		return 0;
	}
	
	// Unveil the hints around current spots if it is safe zone (hint = 0)
	// recursive call
	void safeZone(int rowIndex, int colIndex) {
		//base case
		if(selectedBoard[rowIndex][colIndex][2] != 0)	return;  //not safe zone
  
		for(int i = rowIndex-1; i <= rowIndex+1; i++) {
			if(i < 0 || i >= selectedBoard.length )  //out of boundary
				continue;
			else
				for(int j = colIndex-1; j <= colIndex+1; j++) {
					if(j < 0 || j >= selectedBoard[0].length  //out of boundary
							 || (i == rowIndex && j == colIndex))  // original spot
						continue;
					else if(selectedBoard[i][j][1] == 0) // not visited
							openSpot(i, j);
				}
		}			

	}
	
	// reset risk  reset both the safespot. remove risk index of each spot, but keep 100 and 0.
	void resetRisk() {
		safeSpot[2] = 100; // set safeZone risk to 100 to prepare for getting next safe move
		
		for(int i = 0; i < boardForAI.length; i++) {
			for(int j = 0; j < boardForAI[0].length; j++) {
				// keep the confident result, don't keep 0 to simplify getting safeSpot info
				if( boardForAI[i][j][0] < 100 || boardForAI[i][j][0] != 0)  // keep 100 and 0
					boardForAI[i][j][0] = -1;  //reset risk after each move
			}
		}		
	}

	// do the work when opening a spot
	void openSpot(int rowIndex, int colIndex) {
		if(selectedBoard[rowIndex][colIndex][1] == 1)  // already visited
			return;
		boardForAI[rowIndex][colIndex][1] = selectedBoard[rowIndex][colIndex][1] = 1;  //mark as visited	
		boardForAI[rowIndex][colIndex][2] = selectedBoard[rowIndex][colIndex][2]; //copy the hint
		updateBlindSpotsNum(rowIndex, colIndex);
		spotsLeft--;
		safeZone(rowIndex, colIndex);		
	}
	
	
	// AI function to evaluate risk of each spot
	void AI() {
		findEasyMines();  //find the obvious mines
		excludeSpots();   // exclude the obvious non-mine spot
		excludewithOneMine();  // evaluate when we know some two spots have one mine
		
		for(int i = 0; i < boardForAI.length; i++) {  // go over each row
			for(int j = 0; j < boardForAI[0].length; j++) {  // go over each column
				if(boardForAI[i][j][1] == 1)  // visited spot
					evalRisk(i, j);
			}
		}
	}
	
	// check if current spot is special spot including:
	// all unevaluated spots are mine. Mark all as mines
	// 0% remain risk with unevaluated spots. Can exclude directly
	// 1 mine with two spots. will use these info to evaluate other cells.
	// 50% risk spot (unassigned spots can be given risk of 50) with hint 1
	// rets: 0 for not special, 1 for 100% are mines, 2 for 0% risk spots, 3 for 1 mine two spots.
	int isSpecialSpot(int rowIndex, int colIndex) {
		int hint = boardForAI[rowIndex][colIndex][2];
		int blindSpots = boardForAI[rowIndex][colIndex][3];
		
		int[] knownRisk = getKnownRisk(rowIndex, colIndex);
		int unevalSpots = blindSpots - knownRisk[0]; 
		int remainRisk = hint*100 - knownRisk[1];
		
		if (unevalSpots == 0 || blindSpots == 0 ) // all spots have been evaluated or opened
			return 0;	
		// all left unknown spots are mine
		if(remainRisk  == unevalSpots * 100 )
			return 1;
		// no remainRisk, and risk only from known mines
		if(remainRisk == 0 && knownRisk[0] * 100 == knownRisk[1])
			return 2;
		// one mine with two spots
		if(remainRisk == 100 && unevalSpots == 2)
			return 3;
		
		return 0;
	}

	
	// scan the board to find 100% confirmed mines
	void findEasyMines() {
		for(int i = 0; i < boardForAI.length; i++) { // each row
			for(int j = 0; j < boardForAI[0].length; j++) { //each spot
				if(boardForAI[i][j][1] == 1) {  //visited spot
					if(boardForAI[i][j][2] != 0 && isSpecialSpot(i, j) == 1)
						markEasyMines(i, j, 100);
				}
			}
		}
	}


	// Exclude spots (remainRisk=0)
	void excludeSpots() {
		for(int i = 0; i < boardForAI.length; i++) { // each row
			for(int j = 0; j < boardForAI[0].length; j++) { //each spot
				if(boardForAI[i][j][1] == 1) {  //visited spot
				if(isSpecialSpot(i, j) == 2)
						markEasyMines(i, j, 0);
				}
			}
		}		
	}


	// find the two spots that there definitely is one mine in them and update surrounding spots
	void excludewithOneMine() {
		for(int i = 0; i < boardForAI.length; i++) { // each row
			for(int j = 0; j < boardForAI[0].length; j++) { //each spot
				if(boardForAI[i][j][1] == 1) {  //visited spot
				if(isSpecialSpot(i, j) == 3)
						findMoreMines(i, j);
				}
			}
		}		
	}


	// find the relative spots around the 1-mine-two-spots spot and evaluate them
	// with the info that two of the spots are one mine.
	// input: the spots that has one mine left and two unevaluated spots
	void findMoreMines(int rowIndex, int colIndex) {
		// store the two spots as a mine and the spots to evaluate
		// content: spot1-row, spot1-column, spot2-row, spot2-column
		int[] mineLoc = new int[4]; 
		
		findtheTwoSpots(rowIndex, colIndex, mineLoc);
		
		// an array to store the possible index of the interest spot. -1 as blank mark
		int[][] spotList = {{-1, -1, -1},{-1, -1, -1}};
		int deltaRow = Math.abs(mineLoc[0] - mineLoc[2]);
		int deltaCol = Math.abs(mineLoc[1] - mineLoc[3]);
		
		switch(deltaRow) {
		case 0: spotList[0][0] = mineLoc[0] - 1; 
				spotList[0][1] = mineLoc[0];
				spotList[0][2] = mineLoc[0] + 1; break;
		case 1: spotList[0][0] = mineLoc[0]; 
				spotList[0][1] = mineLoc[0] + 1; break;
		case 2: spotList[0][0] = Math.max(mineLoc[0], mineLoc[2]) - 1; break;
		}
		
		switch(deltaCol) {
		case 0: spotList[0][0] = mineLoc[1] - 1; 
				spotList[0][1] = mineLoc[1];
				spotList[0][2] = mineLoc[1] + 1; break;
		case 1: spotList[0][0] = mineLoc[1]; 
				spotList[0][1] = mineLoc[1] + 1; break;
		case 2: spotList[0][0] = Math.max(mineLoc[1], mineLoc[3]) - 1; break;
		}
		
		// process one by one. the method below will do the validation of the index
		evalWithOneMine(spotList, mineLoc);
	}
	
	
	// find the two spots that can be considered as a mine
	// the array mineInfo is passed in to store the result
	void findtheTwoSpots(int rowIndex, int colIndex, int[] mineInfo) {
		int pos = 0;  // put the first location at spot 0 of the result array
		
		for(int i = rowIndex-1; i <= rowIndex + 1; i++) {  //surrounding rows
			if(i < 0 || i >= boardForAI.length)  //out of boundary
				continue;
			for(int j = colIndex-1; j <= colIndex+1; j++) {  //surrounding columns
				if(j < 0 || j >= boardForAI[0].length 		//out of boundary
						 || (i == rowIndex && j == colIndex) ) // Current spot itself
						continue;
				if(boardForAI[i][j][1] == 0 && boardForAI[i][j][0] == -1)	{ // unvisited, risk not assigned
					mineInfo[pos++] = i;
					mineInfo[pos++] = j;
				}
			}
		}	
	}

	
	// evaluate the spots by considering the two spots passed in as one mine
	// the content of the array: spot1-row, spot1-column, spot2-row, spot2-column
	void evalWithOneMine(int[][] spotList, int[] mineLoc) {
		// Temporarily set the risks to 50. will erase later on
		boardForAI[mineLoc[0]][mineLoc[1]][0] = 50;
		boardForAI[mineLoc[2]][mineLoc[3]][0] = 50;
		
		for(int i = 0; i < 3; i++) {  // go over possible row index
			if(spotList[0][i] < 0 || spotList[0][i] >= boardForAI.length)  // out of boundary
				continue;
			for(int j = 0; j < 3; j++) { // go over possible column index
				if(spotList[1][j] < 0 || spotList[1][j] >= boardForAI[0].length)  // out of boundary
					continue;
				if(boardForAI[i][j][1] == 1 && boardForAI[i][j][3] > 2){ //visited spot and has mines around
					findEasyMines();
					excludeSpots();
				}
			}
		}
		
		//reset the risk of these two spots
		boardForAI[mineLoc[0]][mineLoc[1]][0] = -1;
		boardForAI[mineLoc[2]][mineLoc[3]][0] = -1;
	}
	

	// maker easy mines around current spot
	// risk: 50 for 50% risk, 100 for 100 risk
	void markEasyMines(int rowIndex, int colIndex, int risk) {
		for(int i = rowIndex-1; i <= rowIndex + 1; i++) {  //surrounding rows
			if(i < 0 || i >= boardForAI.length)  //out of boundary
				continue;
			for(int j = colIndex-1; j <= colIndex+1; j++) {  //surrounding columns
				if(j < 0 || j >= boardForAI[0].length 		//out of boundary
						 || (i == rowIndex && j == colIndex) ) // Current spot itself
						continue;
				if(boardForAI[i][j][1] == 0)  { // unvisited spot
					if(risk == 100 && boardForAI[i][j][0] != 100)  // 100 has the priority
						boardForAI[i][j][0] = risk;
					else if( boardForAI[i][j][0] == -1) // has not been assigned a risk
						boardForAI[i][j][0] = risk;
					storeSaftestSpot(i, j);
				}
			}
		}		
	}


	// helper function to evaluate the risk of unvisited spots around current position.
	// check for special case to lock the confirmed mines
	void evalRisk(int rowIndex, int colIndex) {
		int hint = boardForAI[rowIndex][colIndex][2];
		int blindSpots = boardForAI[rowIndex][colIndex][3];
		
		int[] knownRisk = getKnownRisk(rowIndex, colIndex);
		if (blindSpots == 0 || blindSpots == knownRisk[0]) // all are opened or assigned
			return;
	
		// a patch to avoid wrong zero risk for 1 hint spot (not perfect solution, just reduce error rate)
		if((hint*100 - knownRisk[1]) == 0 && hint == 1)  
			return;
		int remainAvgRisk = (hint*100 - knownRisk[1])/(blindSpots - knownRisk[0]);
		if(remainAvgRisk < 0)
			remainAvgRisk = 0;
		
		for(int i = rowIndex-1; i <= rowIndex + 1; i++) {  //surrounding rows
			if(i < 0 || i >= boardForAI.length)  //out of boundary
				continue;
			for(int j = colIndex-1; j <= colIndex+1; j++) {  //surrounding columns
				if(j < 0 || j >= boardForAI[0].length)  //out of boundary
					continue;
				if(boardForAI[i][j][1] == 0 && boardForAI[i][j][0] == -1) {  //unvisited and unassigned spot
						boardForAI[i][j][0] = remainAvgRisk;   // assign left risk
						storeSaftestSpot(i, j);
				}
			}
		}
	}
	
	
	// get number of spots with assigned risks and total risk around certain spot
	int[] getKnownRisk(int rowIndex, int colIndex) {
		int[] knownRisk = {0, 0};  // {n, totalRisk}
		
		for(int i = rowIndex-1; i <= rowIndex + 1; i++) {  //surrounding rows
			if(i < 0 || i >= boardForAI.length)  //out of boundary
				continue;
			for(int j = colIndex-1; j <= colIndex+1; j++) {  //surrounding columns
				if(j < 0 || j >= boardForAI[0].length 		//out of boundary
						 || (i == rowIndex && j == colIndex) ) // Current spot itself
						continue;
				if(boardForAI[i][j][0] != -1)	{ // risk has been assigned
					knownRisk[0] ++;
					knownRisk[1] += boardForAI[i][j][0];
				}
			}
		}		
		return knownRisk;
	}


	// update number of unvisited spots around current spot when current spot is opened
	void updateBlindSpotsNum(int rowIndex, int colIndex) {
		for(int i = rowIndex-1; i <= rowIndex + 1; i++) {  //surrounding rows
			if(i < 0 || i >= boardForAI.length)  //out of boundary
				continue;
			for(int j = colIndex-1; j <= colIndex+1; j++) {  //surrounding columns
				if(j < 0 || j >= boardForAI[0].length 		//out of boundary
						 || (i == rowIndex && j == colIndex) ) // Current spot itself
						continue;
				boardForAI[i][j][3]--;
			}
		}
	}


	// update one of the the lowest risk spot
	void storeSaftestSpot(int rowIndex, int colIndex) {
		int currentRisk = boardForAI[rowIndex][colIndex][0];
		if(currentRisk == 0 && safeSpot[2] != 0) { // the really safe spot
				safeSpot[0] = rowIndex;
				safeSpot[1] = colIndex;
				safeSpot[2] = currentRisk;
		}
		else if( currentRisk < safeSpot[2] &&  currentRisk != -1 && safeSpot[2] != 0) {
			safeSpot[0] = rowIndex;
			safeSpot[1] = colIndex;
			safeSpot[2] = currentRisk;
		}
	}


	// suggest next step
	void nextStep() {
		if( safeSpot[2] != 0 ) {  // not 100% safe
			if(safeSpot[2] > 20)  // based on experience
				System.out.println("Not sure which spot is safe. Good luck!");
			else
				System.out.printf("The spot:%d-%d, might be safe, "
						+ "with the risk index of: %d. Good Luck!\n", 
			safeSpot[0], safeSpot[1], safeSpot[2]);
		}
		else {
			System.out.printf("One safest move is:%d-%d, with the risk of: %d\n", 
					safeSpot[0], safeSpot[1], safeSpot[2]);
			
// the section below is for test.
//			int i = safeSpot[0];
//			int j = safeSpot[1];
//			resetRisk();
//			updateBoard(i, j, 0);			
		}
	}
	
}
