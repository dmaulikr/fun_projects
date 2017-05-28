package main;

import java.util.Random;
import java.util.Scanner;

//Terminal version of MineSweeper game 
//difficulty	No. of mines	board size:
//easy:			10				8X8	
//hard:			40				16X16	
//expert:		99				16X30

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
	// the third dimension stored four pieces of info in the oder of:
	// 0: is here a mine?; 1: is this spot visited?; 
	// 2: how many mines around this spot; 3: is this spot flagged by user?
	// 0 for not visited, 1 for visited
	// target board according to user's selection
	private int[][][] selectedBoard;
	private int spotsLeft;
	
	
	//constructor
	public Board(int level){
		initBoard(level);
	}
	
	
	// initiate the board
	void initBoard(int level) {	
		selectedBoard = new int[levels[level][0]][levels[level][1]][4];
		spotsLeft = selectedBoard.length * selectedBoard[0].length - levels[level][2];
		setMines(level);
		setHints();
		
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
	// mode: 0 for normal, non-zero for solution after game over or win
	void printBoard(int mode) {
		printTopIndex(selectedBoard[0].length);
		printHorzLine(selectedBoard[0].length);
		for(int i = 0; i < selectedBoard.length; i++){  // each row
			System.out.print(i + " | ");
			for(int j = 0; j < selectedBoard[0].length; j++) {  // each column
				printContent(i, j, mode);
			}
			System.out.println("");
			printHorzLine(selectedBoard[0].length); // bottom line separator
		}
	}

	// print the required content based on the status of the spot
	// if not visited:
	// 		if not flagged: show as blank
	// 		if flagged: 	show as flag
	// if visited: show hints
	// mode: 0 for normal mode; non-zero to show all the mines after game over
	
	void printContent(int rowIndex, int colIndex, int mode) {
		int isMine =   selectedBoard[rowIndex][colIndex][0];
		int visited =  selectedBoard[rowIndex][colIndex][1];
		int hint = selectedBoard[rowIndex][colIndex][2];
		int isFlagged = selectedBoard[rowIndex][colIndex][3];	
		
		if(mode == 0) {  //normal mode
			if(visited == 0) {  //not visited
				if(isFlagged == 1)  //flagged
					System.out.print(FLAG + " ");
				else
					System.out.print("  ");
			}
			else
				System.out.print(hint + " ");		
		}
		else { //game is over, print solution
			if(isMine == 1)
				System.out.print(MINE + " ");
			else
				System.out.print(hint + " ");
		} 
		System.out.print("| ");
	}
	
	// print top index
	void printTopIndex(int columns){
		System.out.println("Spots left: " + spotsLeft);
		System.out.print("   ");
		for(int i = 0; i < columns; i++) {
			System.out.print(i + "   ");
		}
		System.out.println();
	}
	
	
	
	// print horizontal line separator, helper method for print board
	void printHorzLine(int columns) {
		System.out.print("  ");
		for(int i = 0; i < columns; i++) {
			System.out.print("____");
		}
		System.out.println("");
	}
	
	// update the board with user's input
	// mode: 0 for open; None zero for flag
	// return value:
	// -1:	invalid index
	// 0:	OK
	// 1: 	win
	// 2:	game over
	int updateBoard(int rowIndex, int colIndex, int mode) {
		if(rowIndex > selectedBoard.length || colIndex > selectedBoard[0].length)
			return -1;
		
		if(mode == 0) {  //user open the spot
			if( selectedBoard[rowIndex][colIndex][0] == 1 ) { // hit a mine, game over
				printBoard(1);
				return 2;
			}
			selectedBoard[rowIndex][colIndex][1] = 1;  //mark as visited
			spotsLeft--;
			safeZone(rowIndex, colIndex);				// Unreal safe zone
			if(spotsLeft == 0) {
				printBoard(1);
				return 1;
			}
		}
		else  { // user want to flag this spot as a mine
			int curFlag = selectedBoard[rowIndex][colIndex][3];
			selectedBoard[rowIndex][colIndex][3] = 
					(selectedBoard[rowIndex][colIndex][3] == 1)? 0 : 1;  // update flag
		}

		printBoard(0);
		return 0;
	}
	
	// Unveil the hints around current spots if it is safe zone (hint = 0)
	// recursive call
	void safeZone(int rowIndex, int colIndex) {
		if(selectedBoard[rowIndex][colIndex][2] == 0) {  //safe zone
			for(int i = rowIndex-1; i <= rowIndex+1; i++) {
				if(i < 0 || i >= selectedBoard.length )  //out of boundary
					continue;
				else
					for(int j = colIndex-1; j <= colIndex+1; j++) {
						if(j < 0 || j >= selectedBoard[0].length  //out of boundary
								 || (i == rowIndex && j == colIndex))  // original spot
							continue;
						else {
							if(selectedBoard[i][j][1] == 0) { // not visited
								selectedBoard[i][j][1] = 1;
								spotsLeft--;
								safeZone(i, j);								
							}
						}
					}
			}			
		}
		
	}
	
	
}
