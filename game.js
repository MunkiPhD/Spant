console.log "at the top"

$ = jQuery

#
# --------------------------------- Global Window -----------------------------------
#
window = exports ? this

window.requestAnimFrame = (->
	return window.requestAnimationFrame or 
	window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or
	window.oRequestAnimationFrame or window.msRequestAnimationFrame or ->
		window.setTimeout(callback, 1000 / 60))()

window.clamp = (value, min, max) ->
	if value < min
		return min
	if value > max
		return max
	return value
	

#
# --------------------------------- Timer ---------------------------------------------
#
class Timer
	gameTime: 0
	maxStep: 0.05
	wallLastTimestamp: 0
	
	tick: ->
		wallCurrent = Date.now()
		wallDelta = (wallCurrent - this.wallLastTimestamp) / 1000
		this.wallLastTimestamp = wallCurrent
		
		gameDelta = Math.min(wallDelta, this.maxStep)
		this.gameTime += gameDelta
		return gameDelta

#
# --------------------------------- Entity ---------------------------------------------
#
class Entity
	constructor: (@game, @ctx) ->
	
	x: 0
	y: 0
	active: true
	removeFromWorld: false
	
	draw: ->
	update: ->
	outsideScreen: ->
		try
			returnVal = this.x < 0 or this.x > ctx.canvas.width or this.y < 0 or this.y > ctx.canvas.height
			return returnVal
		catch e
			alert e
		
	
#
# --------------------------------- Visual Entity -------------------------------------
#
class VisualEntity extends Entity
	constructor: (@game, @ctx) ->
		super
		
	
	width: 0
	height: 0
	zindex: 0
	
	
	draw: ->
		super
		
	update: ->
		super

#
# --------------------------------- Button -------------------------------------------
#
class Button extends VisualEntity
	constructor: (@game, @ctx, @callback) ->
		super
	
	text: "Button"
	main_color: "#FFAA00"
	secondary_color: "#DDD"
	
	update: ->
		if @callback
			@callback()
		super
	
	draw: ->
		super
				
	wasClicked: ->
		unless game.click is null
			if game.click.x >= @x and game.click.x <= (@x + @width) and game.click.y >= @y and game.click.y <= (@y + @height)
				#console.log "clicked at [#{game.click.x}, #{game.click.y}] | bounding box is: [#{@x}, #{@y}] and [#{@x+ @width},#{@y + @height}] "
				return true
		return false
		
#
# --------------------------------- Restart Button -------------------------------------------
#
class RestartButton extends Button
	constructor: (@game, @ctx) ->
		@text = "Restart Game"
		@width = 250
		@height = 40
		@x = @ctx.canvas.width / 2 - (@width / 2)
		@y = @ctx.canvas.height / 2 - (@height / 2) + 30
		@main_color = "#FFAA00"
		@secondary_color = "#DDD"
		super
		
	update: ->
		if this.wasClicked()
			# should have this as a callback but I couldn't get it to work. yay JS noob skills
			@game.pregameSetup()
			this.removeFromWorld = true
		else
			@text = "Restart Game"
			
	draw: ->
		ctx.fillStyle = @main_color
		ctx.fillRect(@x, @y, @width, @height)
		ctx.lineWidth = 2
		ctx.strokeStyle = "#FFF"
		ctx.strokeRect(@x, @y, @width, @height)
		ctx.fillStyle = @secondary_color
		ctx.font = "bold 26px Verdana"
		textSize = @ctx.measureText('Restart Game')
		ctx.fillText(@text, (ctx.canvas.width / 2) - (textSize.width / 2) , @y + 30)
		
#
# --------------------------------- Stats ---------------------------------------------
#	
class Stats
	constructor: (@game) ->
	
	shots_fired: 0
	enemies_seen: 0
	
#
# --------------------------------- Bullet ---------------------------------------------
#
class Bullet extends VisualEntity
	constructor: (@ctx, @x, @y, @angle) ->
		this.width = 3
		this.height = 12
		super

	speed: 7
		
	update: ->
		if this.outsideScreen()
			this.active = false
			this.removeFromWorld = true
		else
			#this.x += @speed
			this.y -= @speed
		
	draw: ->
		ctx.save()
		#ctx.translate(this.x, this.y)
		#ctx.rotate(@angle) 
		#ctx.translate(-this.x, -this.y)
		ctx.fillStyle = "#ffaa00"
		ctx.fillRect(@x, @y - this.height, @width, @height)
		ctx.restore()

#
# --------------------------------- BackgroundEntity -----------------------------
#			
class BackgroundEntity extends VisualEntity
	constructor: (@game, @ctx, source) ->
		try
			@image = new Image()
			@image.src = source.toString()
			super @game, @ctx
		catch e
			alert "IN BackgroundEntity: " + e
			
	image: null
	
	draw: ->
		@ctx.drawImage(@image, @x, @y)
		super
		
	update: ->
		super

#
# --------------------------------- Enemy -------------------------------------------
#
class Enemy extends VisualEntity
	constructor: (game, ctx) ->
		@x = Math.random() * ctx.canvas.width
		@width = 20
		@height = 20
		super
	
	health: 10
	speed: 2
	
	update: ->
		if this.outsideScreen()
			this.active = false
			this.removeFromWorld = true
			this.game.lives -= 1
		else
			@y += @speed
		for entity in game.entities
			if entity instanceof Bullet and this.collisionDetected(entity)
				this.removeFromWorld = true
				entity.removeFromWorld = true
				this.game.score += 10
				this.game.current_enemy_displayed -= 1
			
	collisionDetected: (bullet) ->
		# If a's bottom right x coordinate is less than b's top left x coordinate
		#	 There is no collision
		# If a's top left x is greater than b's bottom right x
		#    There is no collision
		# If a's top left y is greater than b's bottom right y
		#    There is no collision
		# If a's bottom right y is less than b's top left y
		#    There is no collision
		if (this.x + this.width) <= (bullet.x)
			#console.log "c1"
			return false
		if (this.x) >= (bullet.x + bullet.width)
			#console.log "c2"
			return false
		if (this.y) >= (bullet.y + bullet.height)
			#console.log "c3"
			return false
		if (this.y + this.height) <= (bullet.y)
			#console.log "c4"
			return false
		#console.log "Item is at: [#{this.x}, #{this.y}] [#{this.x + this.width}.#{this.y + this.height}]  || Bullet is at: [#{bullet.x}, #{bullet.y}] [#{bullet.x + bullet.width}.#{bullet.y + bullet.height} ]"
		return true
			
	draw: ->
		ctx.save()
		#ctx.translate(this.x, this.y)
		#ctx.rotate(@angle) 
		#ctx.translate(-this.x, -this.y)
		ctx.fillStyle = "#00FF00"
		# we use negative height because we want it to draw upwards
		ctx.fillRect(@x, @y, @width, -@height) 
		ctx.restore()
#
# --------------------------------- Player -------------------------------------------
#
class Player extends VisualEntity
	constructor: (gameArg, ctxArg) ->
		@x = 400
		@y = 600
		@width = 32
		@height = 32
		super
	
	movement_speed: 7
	
	shoot: (x, y) ->
		try
			game.entities.push(new Bullet(ctx, x, y, 0))
			game.stats.shots_fired += 1
		catch e
			alert e

	draw: ->
		unless game.keypress is null
			ctx.fillStyle = "#0000FF"
			ctx.fillRect(@x, @y, @width, @height)
			#console.log "#{@x} #{@y}"

	
	update: ->
		#console.log " - Updating Player"
		if game.keypress = keydown.s
			@y += this.movement_speed
		if game.keypress = keydown.w
			@y -= this.movement_speed
		if game.keypress = keydown.a
			@x -= this.movement_speed
		if game.keypress = keydown.d
			@x += this.movement_speed
		@x = window.clamp(@x, 0, @ctx.canvas.width - @width)
		@y = window.clamp(@y, 0, @ctx.canvas.height - @height)
		
		unless game.click is null
			@shoot(game.click.x, game.click.y)

#
# --------------------------------- Level --------------------------------
#
class Level
	constructor: (@game, @ctx) ->
	
	title: "Level X"
	speed: 60
	enemy_count: 3
	level_complete: false
	background: new Image()
	
	update: ->
		if @game.current_enemy_count >= @enemy_count
			this.level_complete = true
			
	draw: ->
		@ctx.fillStyle = "white"
		@ctx.font = "bold 12px Verdana"
		text = "#{@title} | Enemies left: #{@enemy_count - @game.current_enemy_count + @game.current_enemy_displayed} / #{@enemy_count}"
		textWidth = @ctx.measureText(text).width
		@ctx.fillText(text, @ctx.canvas.width - textWidth - 5, 20)

class LevelOne extends Level
	constructor: (@game, @ctx) ->
		@background.src = "images/space1.jpg"
		@enemy_count = 5
		super
	
	title: "Level 1"
	speed: 60
		
	update: ->
		super
	
	draw: ->
		super
		
class LevelTwo extends Level
	constructor: (@game, @ctx) ->
		@background.src = "images/space2.jpg"
		@enemy_count = 10
		super
	
	title: "Level 2"
	speed: 60
		
	update: ->
		super
	
	draw: ->
		super

class LevelThree extends Level
	constructor: (@game, @ctx) ->
		@background.src = "images/space1.jpg"
		@enemy_count = 25
		super
	
	title: "Level 3"
	speed: 60
		
	update: ->
		super
	
	draw: ->
		super
		
#
# --------------------------------- LevelManager --------------------------------
#
class LevelManager
	constructor: (@game, @ctx) ->
		try
			this.levels = []
			console.log "init levels - Levels length: " + this.levels.length
			this.levels.push(new LevelOne(@game, @ctx))
			this.levels.push(new LevelTwo(@game, @ctx))
			this.levels.push(new LevelThree(@game, @ctx))
			this.current_level = this.levels.shift()
			console.log "Levels length: " + this.levels.length
		catch e
			"Error in LevelManager constructor: " + e
	
	levels: []
	current_level: null
	level_changed: false
	
	update: ->
		try
			if this.shouldChangeLevel()
				#console.log "Enemy count is greater than the levels..."
				if @levels.length > 0
					console.log "About to shift..."
					@current_level = @levels.shift()
					@game.current_enemy_count = 0
				else
					console.log "Game should be over"
					@game.game_over = true
				@level_changed = true
			else
				@level_changed = false
		catch e
			alert "Error in LevelManager: " + e
	
	shouldChangeLevel: ->
		#console.log "game.current_enemy_count: #{@game.current_enemy_count} || current_level.enemy_count: #{@current_level.enemy_count}"
		if @game.current_enemy_count >= @current_level.enemy_count
			if @game.current_enemy_displayed > 0
				return false
			else
				return true
		else
			return false
		
			
	draw: ->
		unless @current_level is null
			if @level_changed
				#alert @level_changed
				@ctx.font = "bold 16px Verdana"
				@ctx.fillStyle = "#FFF"
				@ctx.fillText(@current_level.title, 200, 200)
			@current_level.draw()
#
# --------------------------------- Game Engine --------------------------------
#
class GameEngine
	ctx: null
	entities: []
	player: null
	click: null
	mouse: null
	keypress: null
	stats: new Stats()
	timer: new Timer()
	clockTick = null
	
	init: (ctx) ->
		console.log "Initialized"
		this.ctx = ctx
		this.clockTick = this.timer.tick()
			
		# start listening to input
		this.startInput()
		
	addEntity: (entity) ->
		this.entities.push(entity)
		
	update: ->
		#console.log "Updating..."
		for entity in this.entities
			unless entity.removeFromWorld
				entity.update()
		
		# we only want to keep the entities we want in the world
		this.entities = (entity for entity in this.entities when !entity.removeFromWorld)
		
	
	draw: (callback) ->
		#console.log "Drawing..."
		this.ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height)
		this.ctx.save()
		for entity in this.entities
			if entity.active
				entity.draw()
		if (callback)
			callback(true)
		this.ctx.restore()
		
	start: ->
		try
			console.log("starting game");
			that = this;
			(gameLoop = ->
				that.loop();
				requestAnimFrame(gameLoop, that.ctx.canvas))()
		catch e
			alert "Inside GameEngine.start(): #{e}"
		true

	startInput: ->
		try
			that = this
			getXandY = (e) ->
				x = e.clientX - that.ctx.canvas.getBoundingClientRect().left  #- (that.ctx.canvas.width/2)
				y = e.clientY - that.ctx.canvas.getBoundingClientRect().top #- (that.ctx.canvas.height/2)
				return {x: x, y: y}	
			this.ctx.canvas.addEventListener "click", (e) =>
				that.click = getXandY(e)
				e.stopPropagation()
				e.preventDefault()
			, false
			this.ctx.canvas.addEventListener "mousemove", (e) =>
				that.mouse = getXandY(e)
			, false
		catch e
			alert e
		true

	loop: ->
		this.clockTick = this.timer.tick()
		this.update()
		this.draw()
		this.click = null
		this.mouse = null
		this.keypress = null
		#this.stats.update()	

#
# --------------------------------- MyShooter --------------------------------
#
class MyShooter extends GameEngine
	lastEnemyAddedAt: null
	lives: 1
	score: 0
	game_over: false
	level_manager: null
	current_enemy_count: 0
	current_enemy_displayed: 0
	is_paused: false
	
	pregameSetup: ->
		this.is_paused = false
		this.game_over = false
		this.entities = []
		this.lives = 1
		this.score = 0
		this.current_enemy_count = 0
		this.current_enemy_displayed = 0
		this.stats = new Stats()
		# Load images
		backgroundOne = new BackgroundEntity(this, this.ctx, "images/space1.jpg")
		#backgroundOne.draw()
		this.entities.push(backgroundOne)
		
		# Level Manager
		this.level_manager = null
		this.level_manager = new LevelManager(this, this.ctx)
		
		# Entities
		this.player = new Player(this, this.ctx)
		this.entities.push(this.player)	
	
	
	start: ->
		this.pregameSetup()
		super
		
	update: ->
		if this.lives <= 0 or @game_over
			for entity in this.entities
				unless entity instanceof BackgroundEntity
					entity.active = false
					entity.removeFromWorld = true
			this.addEntity(new RestartButton(this, this.ctx))
			super
			return true
			
		if game.keypress = keydown.space
			@is_paused = !@is_paused
			super
			# return true
		
		if @is_paused
			return true
			
		@addEnemy()
		@level_manager.update()
		super
	
	addEnemy: ->
		#console.log @current_enemy_count + "    " + @level_manager.current_level.enemy_count
		if @current_enemy_count >= @level_manager.current_level.enemy_count
			return true
		if this.lastEnemyAddedAt = null or (this.timer.gameTime - this.lastEnemyAddedAt) > 1
			if Math.random() < 1/ 60 # this.current_level.speed
				this.addEntity(new Enemy(this, this.ctx))
				this.lastEnemyAddedAt = this.timer.gameTime
				this.stats.enemies_seen += 1
				this.current_enemy_count += 1
				this.current_enemy_displayed += 1
				
	draw: ->
		try
			if @is_paused
				this.drawPauseScreen()
				return true
				
			super 
			this.drawScore() # this needs to be put in as a callback
			this.drawEnemyStats()
			this.level_manager.draw()
			
			
			if this.lives <= 0
				this.drawGameOver()
			if this.lives > 0 and @game_over
				this.drawPlayerWin()
		catch e
			alert e

	drawScore: ->
		this.ctx.fillStyle ="white"
		this.ctx.font = "bold 16px Verdana"
		this.ctx.fillText("Shots Fired: #{this.stats.shots_fired}",  10, this.ctx.canvas.height - 10)
		this.ctx.fillText("Score: #{this.score}",  10, this.ctx.canvas.height - 30)
		this.ctx.fillText("Lives: #{this.lives}",  10, this.ctx.canvas.height - 50)
	
	drawEnemyStats: ->
		this.ctx.fillStyle ="white"
		this.ctx.font = "bold 16px Verdana"
		this.ctx.fillText("Enemies: #{this.stats.enemies_seen}",  this.ctx.canvas.width - 195, this.ctx.canvas.height - 10)
		this.ctx.fillText("Enemies Displayed: #{this.current_enemy_displayed}",  this.ctx.canvas.width - 195, this.ctx.canvas.height - 30)
	
	drawGameOver: ->
		this.ctx.fillStyle = "white"
		this.ctx.font = "bold 26px Verdana"
		this.ctx.fillText("Game Over",  320, 300)
		
	drawPlayerWin: ->
		this.ctx.fillStyle = "white"
		this.ctx.font = "bold 26px Verdana"
		this.ctx.fillText("You Win!",  320, 300)
	
	drawPauseScreen: ->
		this.ctx.fillStyle = "#FFF"
		this.ctx.font = "bold 26px Verdana"
		this.ctx.fillText("Paused", 320, 300)
#
# --------------------------------- Run Game Code ------------------------------
#
try
	canvas = $("#surface")
	ctx = canvas.get(0).getContext("2d")
	
	game = new MyShooter #GameEngine
	game.init(ctx)
	game.start()
catch e
	alert e
console.log "at the end"

