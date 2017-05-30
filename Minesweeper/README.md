 Litao Chen		2017.05.29
 Terminal version of MineSweeper game 
 difficulty		No. of mines	board size:
 easy:			10				8X8	
 hard:			40				16X16	
 expert:		99				16X30

 This board contains a simple AI to help user select next move

 Basic idea: 
 - use known hint to calculate risk of each unopened spot, simply even distribution of the risk.

 - To improve accuracy, before normal evaluation, do the risk evaluation in the order of:
   -> go over the board to find easy mines: like hint is two and you got 2 unopened spots around it

   -> go over the board to exclude non-mine spot:	like the undistributed risk is 0 but there are unopened spots
      *: It is important to limit the second step to the spots with known mines
           Otherwise you may get many false no-risk spot!!!

   -> go over the board to assign 50% risk: like you have 1 mine and two spots waiting, each get 50
      *: the third optimization is very useful in some cases but also introduce over estimated risk 
		for following evaluation. It has to be limited to the spots that has only two unEvaluated spots.

   -> the last optimization I did is to correct >maximum risk. This correction somehow is helpful 
		but I am not sure how important it is.

Over all this AI works quite well for easy and hard board. Have fun!


