package main;

import java.util.Random;


// Litao Chen		2017.05.29
// Terminal version of MineSweeper game 
// difficulty		No. of mines	board size:
// easy:			10				8X8	
// hard:			40				16X16	
// expert:			99				16X30

// ***************************************************************************************************************
// This board contains a simple AI to help user select next move
// Basic idea: 
// - use known hint to calculate risk of each unopened spot, simply even distribution of the risk.
//
// - To improve accuracy, before normal evaluation, do the risk evaluation in the order of:
//   -> go over the board to find easy mines: like hint is two and you got 2 unopened spots around it
//
//   -> go over the board to exclude non-mine spot:	like the undistributed risk is 0 but there are unopened spots
//      *: It is important to limit the second step to the spots with known mines
//           Otherwise you may get many false no-risk spot!!!
//
//   -> go over the board to assign 50% risk: like you have 1 mine and two spots waiting, each get 50
//      *: the third optimization is very useful in some cases but also introduce over estimated risk 
//		for following evaluation. It has to be limited to the spots that has only two unEvaluated spots.
//
//   -> the last optimization I did is to correct >maximum risk. This correction somehow is helpful 
//		but I am not sure how important it is.
//
//	Over all this AI works quite well for easy and hard board. Have fun!
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
			System.out.println("Risk svaluation from AI:");	
		
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
		AI();
		printBoard(0);

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
	
	// reset risk 
	void resetRisk() {
		for(int i = 0; i < boardForAI.length; i++) {
			for(int j = 0; j < boardForAI[0].length; j++) {
				// keep the confident result, don't keep 0 to simplify getting safeSpot info
				if( boardForAI[i][j][0] < 100)  // remember positions with risk higher than 100
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
		safeSpot[2] = 100; // set safeZone risk to 100 to prepare for getting next safe move
		updateBlindSpotsNum(rowIndex, colIndex);
		spotsLeft--;
		safeZone(rowIndex, colIndex);		
	}
	
	
	// AI function to evaluate risk of each spot
	void AI() {
		findEasyMines();  //find the obvious mines
		excludeSpots();
		set50Risk();
		
		for(int i = 0; i < boardForAI.length; i++) {  // go over each row
			for(int j = 0; j < boardForAI[0].length; j++) {  // go over each column
				if(boardForAI[i][j][1] == 1)  // visited spot
					evalRisk(i, j);
			}
		}
		// check if we can correct risk factor to find safer step.
		correctRisks();
	}
	
	// scan the board to find 100% confirmed mines
	void findEasyMines() {
		for(int i = 0; i < boardForAI.length; i++) { // each row
			for(int j = 0; j < boardForAI[0].length; j++) { //each spot
				if(boardForAI[i][j][1] == 1) {  //visited spot
					int blindSpots = boardForAI[i][j][3];
					int hint = boardForAI[i][j][2];
					
					if(hint != 0 && blindSpots == hint)
						markEasyMines(i, j, 100);
				}
			}
		}
	}

	
	// check if current spot is special spot including:
	// 0% remain risk with unevaluated spots. Can exclude directly
	// 50% risk spot (unassigned spots can be given risk of 50) with hint 1
	// rets: 0 for not special, 1 for 0% remainRisk, 2 for 50% risk spots
	int isSpecialSpot(int rowIndex, int colIndex) {
		int hint = boardForAI[rowIndex][colIndex][2];
		int blindSpots = boardForAI[rowIndex][colIndex][3];
		
		int[] knownRisk = getKnownRisk(rowIndex, colIndex);
		int unevalSpots = blindSpots - knownRisk[0]; 
		if (unevalSpots == 0 || blindSpots == 0 ) // all spots have been evaluated or opened
			return 0;
		
		int remainRisk = hint*100 - knownRisk[1];
		if(remainRisk == 0 && knownRisk[0] * 100 == knownRisk[1]) // risk only from mines
			return 1;
		
		int unEvalSpot = hint - knownRisk[0];
		int avgRisk = remainRisk / unevalSpots;
		int residual = remainRisk % unevalSpots;
		if( avgRisk  == 50 && residual == 0 && unEvalSpot == 2)  // limit to splitting to 2 spots
			return 2;	
		return 0;
	}


	// Exclude spots from mine (remainRisk=0)
	void excludeSpots() {
		for(int i = 0; i < boardForAI.length; i++) { // each row
			for(int j = 0; j < boardForAI[0].length; j++) { //each spot
				if(boardForAI[i][j][1] == 1) {  //visited spot
				if(isSpecialSpot(i, j) == 1)
						markEasyMines(i, j, 0);
				}
			}
		}		
	}
	
	// assign 50% risk to appropriate spots
	void set50Risk() {
		for(int i = 0; i < boardForAI.length; i++) { // each row
			for(int j = 0; j < boardForAI[0].length; j++) { //each spot
				if(boardForAI[i][j][1] == 1) {  //visited spot					
					if( isSpecialSpot(i, j) == 2 )
						markEasyMines(i, j, 50);
				}
			}
		}		
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


	// correct possible over estimated risk in case we know there is a mine and > 100 * hints total risk
	void correctRisks() {
		for(int i = 0; i < boardForAI.length; i++) {
			for(int j = 0; j < boardForAI[0].length; j++) {
				if(boardForAI[i][j][1] != 0)  // visited spot
					correctRisk(i, j);
			}
		}
	}

	
	// correct over estimated risk around a spot by changing the lowest non-zero risk to 0 
	void correctRisk(int rowIndex, int colIndex) {
		int totalRisk = 0;
		int maxRisk = boardForAI[rowIndex][colIndex][2] * 100;
		// array to store position of lowest risk spot
		// by default the index was set to a number of our range
		int[] minRiskSpot = {999 ,999, 100};
		
		for(int i = rowIndex-1; i <= rowIndex + 1; i++) {  //surrounding rows
			if(i < 0 || i >= boardForAI.length)  //out of boundary
				continue;
			for(int j = colIndex-1; j <= colIndex+1; j++) {  //surrounding columns
				if(j < 0 || j >= boardForAI[0].length 		//out of boundary
						 || (i == rowIndex && j == colIndex) ) // Current spot itself
						continue;
				if(boardForAI[i][j][1] == 0)	{ // not visited spot
					totalRisk += boardForAI[i][j][0];					
					if( boardForAI[i][j][0] < minRiskSpot[2] && boardForAI[i][j][0] != -1) {
						minRiskSpot[0] = i;
						minRiskSpot[1] = j;
						minRiskSpot[2] = boardForAI[i][j][0];
					}
				}
			}
		}
		if(totalRisk > maxRisk && minRiskSpot[0] != 999 && minRiskSpot[2] < 30) {  // 30 by experience
			boardForAI[minRiskSpot[0]][minRiskSpot[1]][0] = 0;
			storeSaftestSpot(minRiskSpot[0], minRiskSpot[1]);
		}
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
//			updateBoard(i, j, 0, 1);			
		}
	}
	
}
