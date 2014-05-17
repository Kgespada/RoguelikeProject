;These will need to be moved later
(load "level-generator.lisp")
(defparameter *cursor-x* nil)
(defparameter *cursor-y* nil)
(defparameter *y* 0)
(defparameter *x* 0)
(defparameter *creature-stack* (list))
(defparameter *down-stairs* (list 0 0))
(defparameter *up-stairs* (list 0 0))

(defparameter *dungeon* (list))

;This is our global map. (It's a vector of vectors!)
(defparameter *map* (make-array 50 :fill-pointer 0))

;This is our global monster list.
(defparameter *monsters* (list))

(defparameter *log* (list "hello" "welcome to" "LISPCRAWL"))

;This won't exist once we're done testing stuff
(defparameter *map-string*
"   ####                 ###               
   #..############      #.#               
   #.##..........#      #.#               
   #.##.####.###.########.################
   #.##.#  #.###.........................#
   #.##.#  #.....########.################
   #..>.####.#####      #.#               
   #######g..#          #.#               
         #.###          #.#               
   ###   #.#            #.#               
   #.##  #.#            #.#               
   #..####@##############.#               
   #.##...........<.......#               
   #.##.####.###.########.#               
   #.##.#  #.###.#      #.#               
   #.##.#  #.....#      #.#               
   #....####.#####      #.#               
   #######...#          #.#               
         #.###          #.#               
         ###            ###               
x")

;"...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;...............................
;x")


;string-to-vector-map takes a string and populates our vector of vectors with it
;Parameters: 	string (a string representing our map, as above)
;Returns: 		nothing (but updates our global map with correct info)
(defun string-to-vector-map (input-string)
	(defparameter *map* (make-array 50 :fill-pointer 0))

	;y and x are going to be used for working our way through the input string and
	;keeping track of the appropriate position in the map we're populating
	(setf *x* 0)
	(setf *y* 0)

	;currently the end of our map is denoted by an x, which should change later
	;while the current character we're on isn't an x:
	(loop while(CHAR/= (elt input-string *x*) #\x)
		;create a new row vector 
		do(defparameter *row* (make-array 50 :fill-pointer 0))
		
		;traverse the current row, pushing characters from the string 
		;into our vector, until we hit a newline
		(loop while(CHAR/= (elt input-string *x*) #\Newline)
			do
			(case (elt input-string *x*)

				((#\g #\@)
					(setf *creature-stack* (append *creature-stack* (list (list *y* (grid-x *x*) (elt input-string *x*)))))
					(setf (elt input-string *x*) #\.)
				)
				((#\>) (setf *down-stairs* (list *y* (grid-x *x*)))
					(print "down")
					(print (list *y* (grid-x *x*))) 
					)
				((#\<) (setf *up-stairs* (list *y* (grid-x *x*))) 
					(print "up")
										(print (list *y* (grid-x *x*))) 

					)
			)

			;push the current character into our row vector
			(vector-push (make-instance 'tile :symbol (elt input-string *x*) :y-pos *y* :x-pos (grid-x *x*)) *row*)
			;increment x
			(setf *x* (+ *x* 1)) 
			;if the current character is an x, break out of this loop
			(if(Char= (elt input-string *x*) #\x) (return)))
		
		;increment x, we're crossing over the newline
		(setf *x* (+ *x* 1))
		;when we hit a newline, push the row vector we've been building into our map 
		(vector-push *row* *map*)
		;increment y
		;(is there seriously not a better way to do this?)
		(setf *y* (+ *y* 1)))
	*map*
	)

(defun grid-x (x)
	(if(> *y* 0)(- x (* (+ (length (elt *map* 0)) 1) *y*)) x)
	)

(defun unpack-creature-stack ()
	(loop while (> (length *creature-stack*) 0)
	do
	(case(elt (elt *creature-stack* 0) 2)
		((#\g) (init-goblin (elt (elt *creature-stack* 0) 0) (elt (elt *creature-stack* 0) 1) ))
		((#\@) (init-player (elt (elt *creature-stack* 0) 0) (elt (elt *creature-stack* 0) 1) ))
		)
	(setf *creature-stack* (remove (elt *creature-stack* 0) *creature-stack*))
	)
)

(defun display-screen(y-start x-start)
	(setf *cursor-y* y-start)
	(setf *cursor-x* x-start)
	(setf *y* (- (slot-value *player* 'y-pos) 8))
	(setf *x* (- (slot-value *player* 'x-pos) 8))

	(loop while(< *cursor-y* (+ 17 y-start)) 
		do(loop while(< *cursor-x* (+ 17 x-start)) 
			do (when(and (>= *y* 0) (>= *x* 0) (< *y* (length *map*)) (< *x* (length (elt *map* *y*))) (slot-value (elt (elt *map* *y*) *x*) 'explored) )
				(if (not(slot-value (elt (elt *map* *y*) *x*) 'visible)) (attrset :cpurple))
				(mvaddch *cursor-y* (* *cursor-x* 2) (slot-value (elt (elt *map* *y*) *x*) 'symbol))
				(attrset :cgray))
			(setf *cursor-x* (+ *cursor-x* 1))
			(setf *x* (+ *x* 1)))

		(setf *cursor-y* (+ *cursor-y* 1))
		(setf *y* (+ *y* 1))

		(setf *cursor-x* x-start)
		(setf *x* (- (slot-value *player* 'x-pos) 8)))
	
	(loop for monster in *monsters*
		do(if(and 
			(>= (slot-value monster 'y-pos) (- (slot-value *player* 'y-pos) 8))
			(<= (slot-value monster 'y-pos) (+ (slot-value *player* 'y-pos) 8))
			(>= (slot-value monster 'x-pos) (- (slot-value *player* 'x-pos) 8))
			(<= (slot-value monster 'x-pos) (+ (slot-value *player* 'x-pos) 8))
			(slot-value (slot-value monster 'tile) 'visible))
			(print-creature
				monster 
				(+(- (slot-value monster 'y-pos) (slot-value *player* 'y-pos)) (+ 8 y-start)) 
				(*(+(- (slot-value monster 'x-pos) (slot-value *player* 'x-pos)) (+ 8 x-start)) 2))))

	(print-creature *player* (+ 8 y-start) (+ 16 (* 2 x-start))))





(defun draw-frame (y-start x-start height width)
	(vline (+ y-start 1) x-start #\| (- height 1))
	(vline (+ y-start 1) (+ width x-start) #\| (- height 1))
	(hline (+ height y-start) x-start #\- width)
	(hline y-start x-start #\- width ))

;this is the function that starts the game, and calls the loop 
;that constitutes the majority of the action
(defun basic-main ()
	;plunk the player down somewhere

	(loop for i from 0 to 4
		do(init-level))

	(setf *map* (slot-value (elt *dungeon* 0) 'level-map))
	
	;(init-player 10 10)
	(get-line-of-sight *player*)
	;(init-goblin 13 10)
	;load the map into the string parser
	;start curses
	(connect-console)
	;print out the screen
	(display)
	;begin main loop
	(main-loop)
	;end curses
	(endwin))

;display handles everything that happens on the screen
(defun display()
	;clear the string
	(erase)
	;draw a box around the map screen
	(draw-frame 0 0 18 36)
	;fill the map box with what the player can see
	(display-screen 1 1)
	;draw a box around the log zone
	(draw-frame 19 0 4 36)
	(mvaddstr 20 1 (elt (reverse *log*) 2))
	(mvaddstr 21 1 (elt (reverse *log*) 1))
	(mvaddstr 22 1 (elt (reverse *log*) 0))
	;draw a box around the stat window
	(draw-frame 0 38 18 23)
	
	;prinr various details about the player
	;name
	(mvaddstr 1 39 "Name:")
	(mvaddstr 1 44 (slot-value *player* 'name))
	;hp
	(mvaddstr 2 39 "hp:")
	(attrset :cgreen)

	;This prints the player's health bar,
	;The way I'm calculating the length of 
	;the bar here isn't going to cut it when 
	;the player's max-hp can actually increase
	(hline 2 42 #\= (slot-value *player* 'currenthp))
	(attrset :cgray)
	(mvaddstr 2 53 (format nil "~a/~a" (slot-value *player* 'currenthp) (slot-value *player* 'maxhp)))
	;xp
	(mvaddstr 4 39 (format nil "XP:~a" (slot-value *player* 'xp)))
	;level of the dungeon
	(mvaddstr 5 39 (format nil "Current Level:~a" (slot-value *player* 'current-level)))
	;player's inventory
	(mvaddstr 6 39 "Inventory:")
	)

;This is our main in-game loop, it currently handles player commands and displays the map
(defun main-loop ()
	(defparameter *done* nil)
	(loop while (not *done*)
		do
		;initialize a small vector for the directions we're going to move in this turn
		(player-turn)
    	(monsters-turn)
    	;update the display
    	(display)))

(defun player-turn ()
	(defvar directions (list 0 0))
		;get a character from the keyboard
  		(case (curses-code-char (getch))
  			;q means quit the game
  			((#\q) (setf *done* t))
  			;different directions for different keystrokes
  			;straight in any direction
  			((#\s #\2) (setf directions (list 1 0)))
  			((#\w #\8) (setf directions (list -1 0)))
  			((#\d #\6) (setf directions (list 0 1)))
  			((#\a #\4) (setf directions (list 0 -1)))
  			;the diagonals
  			((#\1) (setf directions (list 1 -1)))
 			((#\3) (setf directions (list 1 1)))
  			((#\7) (setf directions (list -1 -1)))
  			((#\9) (setf directions (list -1 1)))
  			((#\5) (setf directions (list 0 0)))
  			((#\>) (go-down-stairs *player*) 
  				(setf directions (list 0 0)))
  			((#\<) (go-up-stairs *player*)
  				(setf directions (list 0 0)))
  			)
  		;check to see if the square we're trying to move to is blocked
    	(if (not (equal (list 0 0) directions)) (move-in-direction *player* directions))
   		(get-line-of-sight *player*)
   		(heal-naturally *player*)
	)

(defun go-down-stairs (character)
	(if (char= (slot-value (slot-value character 'tile) 'symbol) #\>)
		(progn
			(setf (slot-value (slot-value character 'tile) 'character) nil)
			(defparameter *next-level* (elt *dungeon* (+ (slot-value character 'current-level) 1)))
			(setf *map* (slot-value *next-level* 'level-map))
			(setf (slot-value character 'current-level) (+ (slot-value character 'current-level) 1))

			(setf (slot-value character 'y-pos) (elt (slot-value *next-level* 'up-stairs) 0))
			(setf (slot-value character 'x-pos) (elt (slot-value *next-level* 'up-stairs) 1))
			(setf (slot-value character 'tile) (elt (elt *map* (slot-value character 'y-pos)) (slot-value character 'x-pos)))
			(setf (slot-value (slot-value character 'tile) 'character) character)
			)
		(log-message "You can't go down here")
		)
	)

(defun go-up-stairs (character)
	(if (char= (slot-value (slot-value character 'tile) 'symbol) #\<)
		(progn
			(setf (slot-value (slot-value character 'tile) 'character) nil)
			(defparameter *previous-level* (elt *dungeon* (- (slot-value character 'current-level) 1)))
			(setf *map* (slot-value *previous-level* 'level-map))
			(setf (slot-value character 'current-level) (- (slot-value character 'current-level) 1))

			(setf (slot-value character 'y-pos) (elt (slot-value *previous-level* 'down-stairs) 0))
			(setf (slot-value character 'x-pos) (elt (slot-value *previous-level* 'down-stairs) 1))
			(setf (slot-value character 'tile) (elt (elt *map* (slot-value character 'y-pos)) (slot-value character 'x-pos)))
			(setf (slot-value (slot-value character 'tile) 'character) character)
			)
		(log-message "You can't go up here")
		)
	)

(defun monsters-turn ()
	(loop for monster in *monsters* 
		do 
		(get-line-of-sight monster)
		(if (slot-value monster 'can-see-player) (find-path monster (slot-value *player* 'tile)))
		(when (> (length (slot-value monster 'direction-list)) 0)
		(move-in-direction monster (elt (slot-value monster 'direction-list) 0))
		(setf (slot-value monster 'direction-list) (remove (elt (slot-value monster 'direction-list) 0) (slot-value monster 'direction-list)))
		)
		(heal-naturally monster)
		)
	)

;This is just a helper function since this was 
;too gross to put into the code up there unshortened
;Parameters: 	a tuple of directions to see if we can move there
;Returns: 		true if it's not blocked, false if it is
(defun not-blocked (creature directions)
	;This line of code gets the tile the character is trying to move on to
	(defparameter *target-tile* (elt (elt *map* (+ (slot-value creature 'y-pos) (elt directions 0))) (+ (slot-value creature 'x-pos) (elt directions 1))))
	
	;This line of code checks to see if the square pointed to by directions is a wall
	(CHAR/= (slot-value *target-tile* 'symbol) #\#))

(defun move-creature (creature directions)
	(defparameter *target-tile* (elt (elt *map* (+ (slot-value creature 'y-pos) (elt directions 0))) (+ (slot-value creature 'x-pos) (elt directions 1))))
	(setf (slot-value (slot-value creature 'tile) 'character) nil)
	(setf (slot-value creature 'y-pos) (+ (slot-value creature 'y-pos) (elt directions 0)))
    (setf (slot-value creature 'x-pos) (+ (slot-value creature 'x-pos) (elt directions 1)))
	(setf (slot-value creature 'tile) *target-tile*)
	(setf (slot-value *target-tile* 'character) creature)
	)

(defun move-in-direction (creature directions)
	(if(not-blocked creature directions)
    		;if it's not blocked, we move our player to the square
    		(if (not(slot-value *target-tile* 'character)) (move-creature creature directions) (attack creature (slot-value *target-tile* 'character)))))

(defun attack (attacker defender)
	(log-message (format nil "~a attacks ~a." (slot-value attacker 'name) (slot-value defender 'name)))
	(setf (slot-value defender 'currenthp) (- (slot-value defender 'currenthp) (slot-value attacker 'power)))
	(when(<= (slot-value defender 'currenthp) 0)(die defender)
		(setf (slot-value attacker 'xp) (+ (slot-value attacker 'xp) 1)))
	)

(defun die (departed)
	(setf *log* (append *log* (list (format nil "~a has died." (slot-value departed 'name)))))
	(if (eq departed *player*) (setf *done* t))
	(setf *monsters* (remove departed *monsters*))
	(setf (slot-value (slot-value departed 'tile) 'character) nil))

(defun log-message (input)
(setf *log* (append *log* (list input))))
;Class Definitions

;base creature class
(defclass creature () 
	(maxhp
	currenthp
	x-pos
	y-pos
	name
	symbol
	(power
		:initform 1)
	(xp
		:initform 0)
	tile
	(line-of-sight
		:initform (list))
	(direction-list
		:initform (list))
	(can-see-player
		:initform nil)
	(regen-counter
		:initform 0)
	(current-level
		:initform 0)
	)
)	

(defclass tile ()
	((y-pos
		:initarg :y-pos) 
	(x-pos
		:initarg :x-pos)
	(symbol
		:initarg :symbol)
	(character
		:initform nil)
	(path-value
		:initform 0)
	(visible
		:initform nil)
	(explored
		:initform nil)))

(defclass level ()
	(level-map 
		:initarg :level-map
	(number
		:initarg :number)
	down-stairs
	up-stairs
		)
	)

(defun init-level ()
	(defparameter *level* (make-instance 'level 
			:number (length *dungeon*)
			))
	(defparameter *new-level-map* (string-to-vector-map(generate-level 36 36 (= (length *dungeon*) 0))))

	(defparameter *level-string* (make-array 0
 		:element-type 'character
 		:fill-pointer 0
 		:adjustable t))

	(setf (slot-value *level* 'level-map) *new-level-map*)
	(setf (slot-value *level* 'down-stairs) *down-stairs*)
	(setf (slot-value *level* 'up-stairs) *up-stairs*)
	(setf *dungeon* (append *dungeon* (list *level*)))
	(setf *map* (slot-value *level* 'level-map))
	(unpack-creature-stack)
	)

;This is perhaps the least elegant way to do this imaginable
(defun init-player (y x)
	(defparameter *player* (make-instance 'creature))
	(setf (slot-value *player* 'name) "foobar")
	(setf (slot-value *player* 'maxhp) 10)
	(setf (slot-value *player* 'currenthp) 10)
	(setf (slot-value *player* 'y-pos) y)
	(setf (slot-value *player* 'x-pos) x)
	(setf (slot-value *player* 'symbol) #\@)
	(setf (slot-value *player* 'tile) (elt (elt *map* y) x))
	(setf (slot-value (elt (elt *map* y) x)'character) *player*)
	(setf (slot-value *player* 'current-level) 0))


(defun init-goblin (y x)
	(defparameter *goblin* (make-instance 'creature))
	(setf (slot-value *goblin* 'name) "Space goblin")
	(setf (slot-value *goblin* 'maxhp) 5)
	(setf (slot-value *goblin* 'currenthp) 5)
	(setf (slot-value *goblin* 'y-pos) y)
	(setf (slot-value *goblin* 'x-pos) x)
	(setf (slot-value *goblin* 'symbol) #\g)
	(setf (slot-value *goblin* 'tile) (elt (elt *map* y) x))
	(setf (slot-value (elt (elt *map* y) x)'character) *goblin*)

	;feels a little pythonic, but it does what I want it to do
	(setf *monsters* (append *monsters* (list *goblin*)))
	)

(defun print-creature (creature y x)
	(attrset :cred)
	(mvaddch y x (slot-value creature 'symbol)) 
	(attrset :cgray))

(defun heal-naturally (creature)
	(when (< (slot-value creature 'currenthp)(slot-value creature 'maxhp))
		(setf (slot-value creature 'regen-counter) (+ 1 (slot-value creature 'regen-counter)))
		(when (>= (slot-value creature 'regen-counter) 10)
			(setf (slot-value creature 'currenthp) (+ 1 (slot-value creature 'currenthp)))
			(setf (slot-value creature 'regen-counter) 0)
			)
		)
	)

;curses helper functions
(defun hline (y-start x-start symbol length)
	(loop for x from x-start to (+ x-start length) do (mvaddch y-start x symbol))
	)

(defun vline (y-start x-start symbol length)
	(loop for y from y-start to (+ y-start length) do (mvaddch y x-start symbol))
	)

(defun list-adjacent-tiles (center-tile)
	(defparameter adjacent-tiles (list))
	(loop for y from (- (slot-value center-tile 'y-pos) 1) to (+ (slot-value center-tile 'y-pos) 1)
		do(loop for x from (- (slot-value center-tile 'x-pos) 1) to (+ (slot-value center-tile 'x-pos) 1)
			do(if (not(and (= y (slot-value center-tile 'y-pos)) (= x (slot-value center-tile 'x-pos)))) (setf adjacent-tiles
							(append adjacent-tiles (list (elt (elt *map* y) x)))		
						))	
		)
	)
	adjacent-tiles
)

(defun clear-path-values ()
	(loop for row across *map*
		do(loop for tile across row
			do(setf (slot-value tile 'path-value) 0))))

(defun clear-visibility()
	(loop for row across *map*
		do(loop for tile across row
			do(setf (slot-value tile 'visible) nil))))

(defun find-path (creature target)
	(defparameter *current-tile* (slot-value creature 'tile))
	(defparameter *origin-tile* (slot-value creature 'tile))
	(defparameter *unexplored-tiles* (list))
	(clear-path-values)

	(loop while (not(eq *current-tile* target))
			do(loop for tile in (list-adjacent-tiles *current-tile*) 
				do (when (and (char/= (slot-value tile 'symbol) #\#) (= (slot-value tile 'path-value) 0))
						(if (eq *current-tile* *origin-tile*) (setf (slot-value tile 'path-value) 1) (if (not(eq tile *origin-tile*)) (setf (slot-value tile 'path-value) (+ (slot-value *current-tile* 'path-value) 1))))
						(setf *unexplored-tiles* (append *unexplored-tiles* (list tile)))
						(if (eq tile target) (return)))
				)
			(if (and (> (length *unexplored-tiles*) 0) (not (eq *current-tile* target))) (progn 
					(setf *current-tile* (elt *unexplored-tiles* 0)) (setf *unexplored-tiles* (remove *current-tile* *unexplored-tiles*))))
			)
	(loop while (not(eq *current-tile* *origin-tile*))
		do (loop for tile in (list-adjacent-tiles *current-tile*)
			do (when (and (eq (slot-value tile 'path-value) (- (slot-value *current-tile* 'path-value) 1)) (or (eq tile *origin-tile*) (> (slot-value tile 'path-value) 0)))
				(setf (slot-value creature 'direction-list) (append (list (list (- (slot-value *current-tile* 'y-pos) (slot-value tile 'y-pos)) (- (slot-value *current-tile* 'x-pos) (slot-value tile 'x-pos))))(slot-value creature 'direction-list)))
				(setf *current-tile* tile)
				(return)
				)
			)
		)

	)

(defun get-line-of-sight (character)
	;set the character's line of sight to a list containing only the tile they are standing on
	(setf (slot-value character 'line-of-sight) (list (slot-value character 'tile)))
	
	(setf (slot-value character 'can-see-player) nil)
	
	(if (eq character *player*)(clear-visibility))
	
	(defvar distance 8)
	(defvar eps)
	(defvar y)
	(defvar tile)

	(loop for direction from 0 to 7 do
	(loop for q from 0 to distance do
	(loop for p from 0 to q do
	(loop for eps-start from 0 to q do
	(setf y 0)
	(setf eps eps-start)
	(loop for x from 1 to distance do 
		(setf eps (+ eps p))
		(when (>= eps q)
			(setf eps (- eps q))
			(if (find direction (list 2 3 6 7)) (setf y (- y 1)) (setf y (+ y 1)))
			)

		(if (< direction 4)
			(setf tile (elt (elt *map* (+ (slot-value character 'y-pos) y)) (+ (slot-value character 'x-pos) (if (oddp direction) (* x -1) x))))
			(setf tile (elt (elt *map* (+ (slot-value character 'y-pos) (if (oddp direction) (* x -1) x))) (+ (slot-value character 'x-pos) y)))
			)
		(when (not (find tile (slot-value character 'line-of-sight)))
			(push tile (slot-value character 'line-of-sight))
			(nreverse (slot-value character 'line-of-sight))
			(when (eq character *player*) 
				(setf (slot-value tile 'visible) t)
				(setf (slot-value tile 'explored) t)
				)
			(if (eq (slot-value tile 'character) *player*) (setf (slot-value character 'can-see-player) t))
		)
			

		(if (char= (slot-value tile 'symbol) #\#) (return))
		)))))
	)
