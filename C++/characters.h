//the Character class describes any living entity in the dungeon.
//(for now that only means monsters and the player)
struct Character{
	//Max Hp
	int maxHp;
	//Current Hp
	int currentHp;
	//Character's Name
	string name;
	//Character Symbol
	char symbol;
	//Color the Symbol will display
	int color;
	//A quick flag to determine if the character is our PC
	bool isPlayer;
	//The character's position on the x axis
	int xPos;
	//The character's position on the y axis
	int yPos;
	//The amount of damage the character deals in combat
	int power;

	int xp;

	Level* currentLevel;

	int move(int, int);
	void attack(Character*);
	void die(Character*);
	Tile* getTile(void);
};

struct NullCharacter: Character{
	NullCharacter(void);
};

struct Player: Character{

	Player (int, int);

	void takeTurn(char);
};

struct Monster: Character{
	stack <int[2]> path;
};

struct SpaceGoblin: Monster{
	SpaceGoblin(int, int, Level*);
};