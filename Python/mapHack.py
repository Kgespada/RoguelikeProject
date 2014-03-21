import curses, traceback

# For now we'll store some global variables here
class gb:
	windowHeight = 18
	windowWidth = 36

# # # # # # # # # # # # # CLASS DEFINITIONS # # # # # # # # # # # # # # # #

#Character Class, for now we'll default the character class to the player.
class character:
	#The player has a name.
	name = "Character Name"
	#Hitpoints
	maxHp = 10
	currentHp = maxHp
	#Magicpoints (or what have you)
	maxMp = 10
	currentMp = maxMp
	#A display symbol
	symbol = 'M'
	#A display color
	color = curses.COLOR_RED
	#positional coordinates
	xPos = 0
	yPos = 0

	power = 1

	#Our initialization function
	#paramaters: level we're initializing on, y position on that level,
	#x position on that level, character name
	#returns nothing
	def __init__(self, level, yPos, xPos):
		#update our personal coordinates
		self.yPos = yPos
		self.xPos = xPos
		self.level = level

	def attack(self, target):
		target.currentHp -= self.power
		if target.currentHp == 0:
			target.die(self)

	def die(self, killer):
		self.level.levelMap[self.yPos][self.xPos].character = nullCharacter()
		killer.xp += self.xpValue


	#Our Move function moves our character on the level map.
	#paramaters: direction (tuple indicating movement in the y and x directions),
	#and map of the level we're on
	#returns a brief message if movement isn't possible
	def move(self, direction):
		#if the destination we're attempting to move to is blocked, we can't move there.
		targetYPos = self.yPos + direction[0]
		targetXPos = self.xPos + direction[1]
		levelMap = self.level.levelMap
		target = levelMap[targetYPos][targetXPos]
		if target.character.name != "null":
			self.attack(target.character)
			return "attacked target"

		if target.terrain.passable:
			#if it's not blocked we move to the destination square
			#starting by clearing out the character from the tile we're currently on
			levelMap[self.yPos][self.xPos].character = nullCharacter()
			#update our personal coordinates to the coordinates of our destination.
			self.yPos += direction[0]
			self.xPos += direction[1]
			#update the destination tile to point to our character
			target.character = self
		else:
			#if the destination square *is* blocked, we return a message
			return "if statement failed"

	#this is much more complicated than I thought it would be,
	#currently working on the design for it before implementing it.
	#def sightCheck():#

#Our monster class is a collection of AI commands for npc's
class monster (character):

	#This will be my attempted implementation of the pathfinding
	#algorithm detailed at: 
	#http://www.roguebasin.com/index.php?title=Quick_Pathfinding_in_a_Dungeon
	#Find path should take a target tile,
	#and return a list of directions to get to that tile
	def findPath(self, target):
		origin = self.level.levelMap[self.yPos][self.xPos]




class player (character):
	#Experience Points
	xp = 0
	#The player symbol is '@'
	symbol = '@'

class spaceGoblin (character):
	name = "Space Goblin"
	maxHp = 5
	currentHp = maxHp
	maxMp = 0
	currentMp = 0
	xpValue = 1


#the null character is just a temporary placeholder
#for when a tile has no one in it
class nullCharacter:
	symbol = ''
	color = 0
	name = "null"

#The terrainType class is going to be the parent class
#for the different types of terrain that tiles can have
class terrainType:
	#terrain types have a symbol that identifies them on the map
	symbol = ''
	#terrain types are either passable or not passable by the character
	passable = False
	#terrain types are displayed with a corresponding color
	color = curses.COLOR_WHITE

#Our floor class is going to be the primary type of terrain the player will travel on
class floor (terrainType):
	symbol = '.'
	#the player can walk on floors
	passable = True

#Our wall class is a type of terrain that will be placed next to floor tiles
class wall (terrainType):
	symbol = '#'
	#the player can't walk through walls
	passable = False

#The tile class represents a particular square on the map,
#it can be occupied by characters and contain items,
#it has a terrain type
class tile:
	#tiles start empty of characters
	character = nullCharacter()
	#tiles start empty of items
	items = []
	terrain = terrainType()

	#our initialization function takes a terrain type,
	#when we initialize the tile we give it that type
	def __init__(self, terrain):
		self.terrain = terrain

	#when we want to print our tile, generally we want to know what 
	#its symbol is and what its color is.
	#our printTile function returns those values
	#paramaters: None
	#returns: a tuple with the symbol the tile will display and the color
	#of that symbol
	def printTile(self):
		#we check to see if there's a visible character in the tile
		if self.character.symbol != '':
			#If there is a character in the tile, we return the 
			#symbol and color provided by that character
			return [self.character.symbol, self.character.color]
		else:
			#if there's no character in the tile, we'll return the
			#symbol and color provided by the terrain
			return [self.terrain.symbol, self.terrain.color]


#our level class represents a specific level of the dungeon.
#generally it has a level number, and a map of the tiles on the level.
class level:
	#Our level map starts as an empty list
	levelMap = []
	#Our level number initializes at 0
	levelNumber = 0
	
	#Our intialization function takes a string that represents
	#a map of a level. Rows of the string are seperated by the /
	#character, and individual spaces are seperated by whitespace
	def __init__(self, mapString):
		y = 0
		#split our input string into rows,
		#and then iterate across them
		for row in mapString.split('/'):
			#create an empty list to append spaces to
			tileRow = []
			#iterate across each row
			x = 0
			for space in row.split():
				#identify which terrain type each character
				#signifies, and add a tile of that type.
				if space == "#":
					tileRow.append(tile(wall))
				elif space == ".":
					tileRow.append(tile(floor))
				elif space == "g":
					newTile = tile(floor)
					newTile.character = spaceGoblin(self, y, x)
					tileRow.append(newTile)

				else:
					#if the character is unrecognized,
					#initialize an empty tile 
					#(nothing in it, basic terrain type, which is impassable)
					tileRow.append(tile(terrainType))
				x += 1
			#append the row to our levelMap
			self.levelMap.append(tileRow)
			y += 1

	def listAdjacentTiles(self, y, x):
		levelMap = self.levelMap
		adjacentTiles = []
		adjacentTiles.append(levelMap[y + 1][x])
		adjacentTiles.append(levelMap[y + 1][x + 1])
		adjacentTiles.append(levelMap[y][x + 1])
		adjacentTiles.append(levelMap[y -1][x + 1])
		adjacentTiles.append(levelMap[y - 1][x])
		adjacentTiles.append(levelMap[y - 1][x - 1])
		adjacentTiles.append(levelMap[y][x - 1])
		adjacentTiles.append(levelMap[y + 1][x - 1])
		return adjacentTiles

 # # # # # # # # # # # # # CURSES FUNCTIONS # # # # # # # # # # # # # # # #

#This function is necessary for cleaning up the terminal once our program
#is done running.
def cursesCleanup():
	# restore normal keyboard mode
	curses.nocbreak()
	# restore keystroke echoing
	curses.echo()
	# required cleanup call
	curses.endwin()

#This function draws a box in our curses window
#paramaters: y pos, x pos, height of box, width of box,
#screen we're drawing the box on.
#returns nothing
def drawBox(y, x, height, width, screen):
	screen.hline(y, x + 1, curses.ACS_HLINE, width -1 )
	screen.hline(height + y, x + 1, curses.ACS_HLINE, width - 1)
	screen.vline(y + 1, x, curses.ACS_VLINE, height - 1)
	screen.vline(y + 1, width + x, curses.ACS_VLINE, height - 1)
	
	screen.addch(y, x, curses.ACS_ULCORNER)
	screen.addch(height + y, x, curses.ACS_LLCORNER)
	screen.addch(y, width + x, curses.ACS_URCORNER)
	screen.addch(y + height, x + width, curses.ACS_LRCORNER)

#this function works just like curses' "hline()" function,
#except you can also designate a color for the line
#paramaters: y pos, x pos, character to draw the line with,
#number of times to draw that character, color of that character,
#screen we're drawing the line on.
#returns nothing
def hColoredLine(y, x, char, num, color, screen):
	i = 0
	while i < num:
		screen.addch(y, x + i, char, color)
		i += 1

# # # # # # # # # # # # # # IN GAME DISPLAY FUNCTIONS # # # # # # # # # # # #

#Our statsWindow function displays basic character stats in a box of the size and at
#the location of the player's choice.
#paramaters: y pos, x pos, height of window, width of window, screen to draw on
#returns nothing
def statsWindow(y, x, height, width, screen):
	#first we draw the window itself
	drawBox(y, x, height, width, screen)
	x += 1
	#print the player name at the top of the window
	screen.addstr(y + 1, x, player.name)

	#player hp
	screen.addstr(y + 2, x, "hp:")
	#hp bar
	hColoredLine(y + 2, x + 3, '=', 10, curses.color_pair(curses.COLOR_GREEN), screen)
	#display current hp/max hp
	screen.addstr(y + 2, x + 14, str(player.currentHp) + "/" + str(player.maxHp))
	
	#player mp
	screen.addstr(y + 3, x, "mp:")
	#mp bar
	hColoredLine(y + 3, x + 3, '=', 10, curses.color_pair(curses.COLOR_BLUE), screen)
	#display current mp/max mp
	screen.addstr(y + 3, x + 14, str(player.currentMp) + "/" + str(player.maxMp))
	
	#print player XP
	screen.addstr(y + 4, x, "XP:" + str(player.xp))

#our drawMap function is where our primary in game curses calls take place
#it takes a command character, and modifies the game accordingly (which in the future
#should probably be moved out of the draw loop) it then draws the level map it is given
#based on the position of the player
#paramaters: input character, screen to draw on, levelmap to draw, the player object
def drawMap(c, screen, levelMap, player):
	#clear the screen of any leftover residue
	screen.clear()

	#if our command is a directional key,
	#we move our player
	if c == 65 or chr(c) == 'w':
		player.move([-1, 0])
	if c == 66 or chr(c) == 's':
		player.move([1, 0])
	if c == 67 or chr(c) == 'd':
		player.move([0, 1])
	if c == 68 or chr(c) == 'a':
		player.move([0, -1])


	#Draw a box around the map screen
	drawBox(0, 0, gb.windowHeight, gb.windowWidth, screen)

	#draw a box around our output zone
	drawBox(gb.windowHeight + 1, 0, 4, gb.windowWidth, screen)

	#draw our stats display:
	statsWindow(0, gb.windowWidth + 1, gb.windowHeight, 23, screen)
	
	#this is the block of code where we draw the actual map itself
	y = gb.windowHeight/2

	for row in levelMap:
		x = gb.windowWidth/4
		if y - player.yPos > 0 and y - player.yPos < gb.windowHeight:
			for square in row:
				squareDisplay = square.printTile()
				if x - player.xPos > 0 and (x * 2) - (player.xPos * 2) < gb.windowWidth:
					screen.addstr(y - player.yPos, (x * 2) - (player.xPos * 2), squareDisplay[0], curses.color_pair(squareDisplay[1]))
					screen.addstr(y - player.yPos, x - player.xPos, '')
				x += 1
		y += 1
		screen.refresh()



 # # # # # # # # # # # # # MAIN BODY OF CODE # # # # # # # #
try:
	mapScreen = curses.initscr()
	# turn off keystroke echo
	curses.noecho()
	# hide the cursor
	curses.curs_set(0)

	# keystrokes are honored immediately, rather than waiting for the
	# user to hit Enter
	curses.cbreak()
	# start color display (if it exists; could check with has_colors())
	curses.start_color()
	# set up a foreground/background color pair that we'll use for indicating selection
	curses.init_pair(curses.COLOR_WHITE,curses.COLOR_WHITE, curses.COLOR_BLACK)
	curses.init_pair(curses.COLOR_RED,curses.COLOR_RED,curses.COLOR_BLACK)
	curses.init_pair(curses.COLOR_GREEN, curses.COLOR_GREEN, curses.COLOR_BLACK)
	curses.init_pair(curses.COLOR_BLUE, curses.COLOR_BLUE, curses.COLOR_BLACK)
	# clear screen
	mapScreen.clear()
	mapScreen.refresh()
	
	

	#Populate levelMap string
	s = ("e e e # . # # e e e e e e e e e e e e e e e e e # . # e e e e e e e e e e e e e e e/"
		 "e e e # . . # # # # # # # # # # # # e e e e e e # . # e e e e e e e e e e e e e e e/"
		 "e e e # . # # . . . . . . . . . . # e e e e e e # . # e e e e e e e e e e e e e e e/"
		 "e e e # . # # . # # # # . # # # . # # # # # # # # . # # # # # # # # # # # # # # # #/"
		 "e e e # . # # . # e e # . # # # . . . . . g . . . . . . . . . . . . . . . . . . . ./"
		 "e e e # . # # . # e e # g . . . . # # # # # # # # . # # # # # # # # # # # # # # # #/"
		 "e e e # . . . . # # # # . # # # # # e e e e e e # . # e e e e e e e e e e e e e e e/"
		 "e e e # # # # # # # . . . # e e e e e e e e e e # . # e e e e e e e e e e e e e e e/"
		 "e e e e e e e e e # . # # # e e e e e e e e e e # . # e e e e e e e e e e e e e e e/"
		 "e e e # # # e e e # . # e e e e e e e e e e e e # . # e e e e e e e e e e e e e e e/"
		 "e e e # . # # e e # . # e e e e e e e e e e e e # . # e e e e e e e e e e e e e e e/"
		 "e e e # . . # # # # . # # # # # # # # # # # # # # . # e e e e e e e e e e e e e e e/"
		 "e e e # . # # g . . . . . . . . . . . . . . . . . . # e e e e e e e e e e e e e e e/"
		 "e e e # . # # . # # # # . # # # . # # # # # # # # . # e e e e e e e e e e e e e e e/"
		 "e e e # . # # . # e e # . # # # . # e e e e e e # . # e e e e e e e e e e e e e e e/"
		 "e e e # . # # . # e e # . . . . . # e e e e e e # . # e e e e e e e e e e e e e e e/"
		 "e e e # . . . . # # # # . # # # # # e e e e e e # . # e e e e e e e e e e e e e e e/"
		 "e e e # # # # # # # . . . # e e e e e e e e e e # . # e e e e e e e e e e e e e e e/"
		 "e e e e e e e e e # . # # # e e e e e e e e e e # . # e e e e e e e e e e e e e e e/"
		 "e e e e e e e e e # . # e e e e e e e e e e e e # . # e e e e e e e e e e e e e e e/"
		)
	
	#initialize our level with the input string
	levelOne = level(s)
	#initialize our character at an occupiable point on our new map
	player = player(levelOne, 9, 10)
	levelOne.levelMap[9][10].character = player
	player.name = "foobar"

	#initialize our input character variable
	c = 0
	#while we don't recieve the quit character we keep executing the draw-getcharacter loop
	while chr(c) != 'q':
		#draw our map and handle relevant input
		drawMap(c, mapScreen, levelOne.levelMap, player)
		#wait for a new keystroke
		c = mapScreen.getch()		
		
	#Return the terminal to working order.
	cursesCleanup()

except:
	#If we catch an error it's important to restore the terminal
	#to it's original state or else it will be unusable.
	cursesCleanup()
	#Provide a traceback
	traceback.print_exc()