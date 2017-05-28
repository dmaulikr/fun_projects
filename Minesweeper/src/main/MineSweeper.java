package main;

import java.util.Scanner;

// Terminal version of MineSweeper game 
// difficulty	No. of mines	board size:
// easy:		10				8X8	
// hard:		40				16X16	
// expert:		99				16X30


public class MineSweeper {
	// index array to store user's input: row, col, flag
	private static int[] index = {0, 0, 0};
	private static Scanner sc = new Scanner(System.in);
	
	public static void main(String[] args) {
		help();
		
		int level = getDifficulty(sc) - 1;
		Board newBoard = new Board(level);
		newBoard.printBoard(0);

		String pattern = "^[fF]?[ ]*[0-9]{1,2}[ ]+[0-9]{1,2}[ ]*$";
		
		while(sc.hasNextLine()) {
			String input = sc.nextLine();
			if(input.equals("h") || input.equals("H") ) {
				help();
			}
			else if(input.matches(pattern)) {
				processInput(input, index);
				int result = newBoard.updateBoard(index[0], index[1], index[2] );
				switch(result){
				case -1: 	System.out.println("Invalid position. please retry."); break; 
				case 1:		System.out.println("Congrat! You win!"); restart(newBoard, sc); break;
				case 2:		System.out.println("Sorry, You lost!"); restart(newBoard, sc); break;
				default:	;
				}
			}
			else
				System.out.println("Invalid input, press \"h\" for instruction");
		}
		
		sc.close();
	}
	
	// game instruction
	static void help(){
		System.out.println(
			"The board will show in the terminal\n" + 
			"input row index and column index (with space in between) to open the spot. e.g.: 2 6\n" +
			"add 'f' at the begining if want to flag the spot. e.g.: f 2 6"
				);
	}
	
	// process user's input
	// the index array should have at least length 2
	static void processInput(String s, int[] index) {
		String[] token = s.split("\\s+");
		if(token[0].equals("f") || token[0].equals("F")) {
			index[0] = Integer.parseInt(token[1]);
			index[1] = Integer.parseInt(token[2]);
			index[2] = 1;
		}
		else {
			index[0] = Integer.parseInt(token[0]);
			index[1] = Integer.parseInt(token[1]);	
			index[2] = 0;
		}
	}

	// ask user to select difficulty
	static int getDifficulty(Scanner input) {
		System.out.println("Please choose the difficulty by number 1, 2 or 3:");
		System.out.println("1:\teasy\n2:\thard\n3:\texpert");
		
		int level = 0;
		while(true) {
			if( !input.hasNextInt() ) {
				System.out.println("Please choose difficulty by number 1, 2 or 3");
				input.nextLine();
				continue;
			}
			
			level = input.nextInt();

			if(level != 1 && level != 2 && level != 3) {
				System.out.println("Please choose difficulty by number 1, 2 or 3");
				input.nextLine();
				continue;
			}
			else
				break;
		}
		input.nextLine();
		return level;
	}

	// ask if user want to restart
	static void restart(Board board, Scanner input) {
		System.out.println("Play again? y/n");
		String pattern = "^[yYnN]{1}$";

		int level = 0;
		while(input.hasNextLine()) {
			String answer = input.nextLine();
			if(answer.matches(pattern)) {
				if(answer.equals("y") || answer.equals("Y")) {
					level = getDifficulty(input)-1; 
					board.initBoard(level);
					board.printBoard(0);
					break;
				}
				else
					System.exit(0);
			}
			else
				System.out.println("Please press y/n to select.");
		}
	}	
	
}

