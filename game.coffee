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
# --------------------------------- Asset Manager ---------------------------------------------
#
class AssetManager
	successCount: 0
	errorCount: 0
	cache: {}
	downloadQueue: []
	soundsQueue: []
	
	queueDownload: (path) ->
		this.downloadQueue.push(path)
	
	queueSound: (id, path) ->
		this.soundsQueue.push(id: id, path: path)
		
	downloadAll: (callback) =>
		if this.downloadQueue.length is 0 and this.soundsQueue.length is 0
			callback()
		
		#this.downloadSounds(callback)
		
		for item in this.downloadQueue
			path = item
			image = new Image()
			that = this
			image.addEventListener "load", ->
				console.log this.src + " is loaded"
				that.successCount += 1
				if that.isDone()
					callback()
			, false
			image.addEventListener "error", ->
				that.errorCount += 1
				if that.isDone()
					callback()
			, false
			image.src = path
			this.cache[path] = image
	
	downloadSounds: (callback) ->
		true
		
	downloadSound: ->
		true
		
	getSound: (path) ->
		this.cache[path]
		
	getAsset: (path) ->
		this.cache[path]
		
	isDone: ->
		((this.downloadQueue.length + this.soundsQueue.length) == this.successCount + this.errorCount)
		
				
	getImage: (filename) ->
		image = new Image()
		image.src = "images/" + filename
		image

#
# --------------------------------- Animation -------------------------------------
#
class Animation
	constructor: (@spriteSheet, @frameWidth, @frameDuration, @loop) ->
		@frameHeight = this.spriteSheet.height
		@totalTime = (this.spriteSheet.width / this.frameWidth) * this.frameDuration
		@elapsedTime = 0
		
		totalTime: 0
		elapsedTime: 0
	
	drawFrame: (tick, ctx, x, y, scaleBy) ->
		try
			scaleBy = scaleBy || 1
			@elapsedTime += tick
			if this.loop
				if this.isDone()
					this.elapsedTime = 0
			else if this.isDone()
				return true
			index = this.currentFrame()
			locX = x - (this.frameWidth / 2) # * scaleBy
			locY = y - (this.frameHeight / 2) # * scaleBy
			#console.log "x: #{x}, y:#{y}. locX: #{locX} locY: #{locY}, scaleBy: #{scaleBy}"
			ctx.drawImage(@spriteSheet, index * this.frameWidth, 0, this.frameWidth, this.frameHeight, locX, locY, this.frameWidth, this.frameHeight)
		catch e
			alert "In Animation.drawFrame: " + e
		
	currentFrame: ->
		return Math.floor(this.elapsedTime / this.frameDuration)
		
	isDone: ->
		return (this.elapsedTime >= this.totalTime)
		
		
#
# --------------------------------- Entity ---------------------------------------------
#
class Entity
	constructor: (@game, @ctx) ->
	
	x: 0
	y: 0
	z: 0
	active: true
	removeFromWorld: false
	
	draw: ->
	update: ->
	outsideScreen: ->
		try
			returnVal = this.x < 0 or this.x > @ctx.canvas.width or this.y < 0 or this.y > @ctx.canvas.height
			return returnVal
		catch e
			alert e
	
	rotateAndCache: (image) ->
		offScreenCanvas = document.createElement('canvas')
		offScreenCtx = offScreenCanvas.getContext('2d')
		
		size = Math.max(image.width, image.height)
		offScreenCanvas.width = size
		offScreenCanvas.height = size
		
		offScreenCtx.translate(size/2, size/2)
		offScreenCtx.rotate(Math.random() * 100 + Math.PI/2)
		offScreenCtx.drawImage(image, -(image.width/2), -(image.height/2))
		
		return offScreenCanvas
		
	
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
	lastMouseX: 0
	lastMouseY: 0
	
	update: ->
		unless game.mouse is null
			@lastMouseX = game.mouse.x
			@lastMouseY = game.mouse.y
			#console.log @lastMouseX + "  " + @lastMouseY
		
		if @callback
			@callback()
		super
	
	draw: ->
		#$("#surface").css("cursor", "crosshair")
		if @lastMouseX >= @x and @lastMouseX <= (@x + @width) and @lastMouseY >= @y and @lastMouseY <= (@y + @height)
			$("#surface").css("cursor", "pointer")
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
		super
			
	draw: ->
		@ctx.fillStyle = @main_color
		@ctx.fillRect(@x, @y, @width, @height)
		@ctx.lineWidth = 2
		@ctx.strokeStyle = "#FFF"
		@ctx.strokeRect(@x, @y, @width, @height)
		@ctx.fillStyle = @secondary_color
		@ctx.font = "bold 26px Verdana"
		textSize = @ctx.measureText('Restart Game')
		@ctx.fillText(@text, (@ctx.canvas.width / 2) - (textSize.width / 2) , @y + 30)
		super
		
#
# --------------------------------- Stats ---------------------------------------------
#	
class GameStats
	constructor: (@game) ->
	
	shots_fired: 0
	enemies_seen: 0
	
#
# --------------------------------- Bullet ---------------------------------------------
#
class Bullet extends VisualEntity
	constructor: (@game, @ctx, @x, @y, @angle, @color = "#ffaa00") ->
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
			if @angle?
				if @angle <= 90 and @angle > 0
					this.x = @x + (@speed / Math.tan(90 - @angle))
				if @angle <= 90 and @angle < 0
					this.x = @x - (@speed / Math.tan(90 - Math.abs(@angle)))
				#console.log @x
			#@y = @speed * Math.sin(@angle)
			
		
	draw: ->
		try
			@ctx.save()
			if @angle?
				@ctx.translate(this.x, this.y)
				@ctx.rotate(@angle * (Math.PI / 180)) 
				@ctx.translate(-this.x, -this.y)
			@ctx.fillStyle = @color
			@ctx.fillRect(@x, @y - this.height, @width, @height)
			@ctx.restore()
		catch e
			alert "Bullet.draw(): " + e
		super
#
# --------------------------------- Bullet Explosion---------------------------------
#
class BulletExplosion extends VisualEntity
	constructor: (@game, @ctx, @x, @y) ->
		@sprite = ASSET_MANAGER.getAsset('images/explosion.png')
		@animation = new Animation(this.sprite, 25, 0.025)
		super
		
	sprite: null
	animation: null
	
	scaleFactor: ->
		return 1 + this.animation.currentFrame()
		
	update: ->
		if this.animation.isDone()
			this.removeFromWorld = true
			return
		super
		
	draw: ->
		try
			#console.log "Draw frame [#{@x}, #{@y}]"
			this.animation.drawFrame(this.game.clockTick, @ctx, @x, @y, this.scaleFactor())
			#@ctx.drawImage(this.animation.spriteSheet, @x, @y)
			super
		catch e
			alert e

#
# --------------------------------- BackgroundEntity -----------------------------
#			
class BackgroundEntity extends VisualEntity
	constructor: (@game, @ctx, @image) ->
		try
			super @game, @ctx
		catch e
			alert "IN BackgroundEntity: " + e
			
	draw: ->
		try
			#console.log @image.src
			@ctx.drawImage(@image, @x, @y)
		catch e
			alert e
		super
		
	update: ->
		super

#
# --------------------------------- Enemy -------------------------------------------
#
class Enemy extends VisualEntity
	constructor: (game, ctx, speed_multiplier = 1) ->
		@speed = @speed * speed_multiplier
		@width = @sprite.width
		@height = @sprite.height
		@x = Math.random() * (ctx.canvas.width - @width)
		super
	
	health: 10
	speed: 2
	sprite: null
	
	update: ->
		if this.outsideScreen()
			this.active = false
			this.removeFromWorld = true
			this.game.lives -= 1
			this.game.current_enemy_displayed -= 1
			# alert "decreasing enemy displayed by 1 in Enemy Update A, is now #{@game.current_enemy_displayed}"
		else
			@y += @speed
		for entity in game.entities
			if entity instanceof Bullet and this.collisionDetected(entity)
				#make sure that the entities aren't slated to be removed from the world yet before we perform the necessary actions
				if @removeFromWorld is false and entity.removeFromWorld is false
					this.removeFromWorld = true
					entity.removeFromWorld = true
					this.game.score += 10
					this.game.current_enemy_displayed -= 1
					# alert "decreasing enemy displayed by 1 in Enemy Update B, is now #{@game.current_enemy_displayed}"
					try
						#console.log "Adding a new BulletExplosion entity"
						this.game.addEntity(new BulletExplosion(this.game, this.ctx, entity.x, entity.y))
					catch e
						alert e
			
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
		# console.log "Item is at: [#{this.x}, #{this.y}] [#{this.x + this.width}.#{this.y + this.height}] 
		# || Bullet is at: [#{bullet.x}, #{bullet.y}] [#{bullet.x + bullet.width}.#{bullet.y + bullet.height} ]"
		return true
			
	draw: ->
		try
			@ctx.save()
			#ctx.translate(this.x, this.y)
			#ctx.rotate(@angle) 
			#ctx.translate(-this.x, -this.y)
			#ctx.fillStyle = "#00FF00"
			# we use negative height because we want it to draw upwards
			#ctx.fillRect(@x, @y, @width, -@height)
			@ctx.drawImage(@sprite, @x, @y)
			@ctx.restore()
		catch e
			alert "Enemy.draw(): " + e


#
# --------------------------------- AsteroidSmall ---------------------------------------
#
class AsteroidSmall extends Enemy
	constructor: (@game, @ctx, @speed_multiplier) ->
		rand = Math.random() * 2
		@speed = 1.5 + rand
		@sprite = this.rotateAndCache(ASSET_MANAGER.getAsset("images/asteroid.png"))
		super
	
	update: ->
		super

	draw: ->
		super
			
#
# --------------------------------- AsteroidLarge ---------------------------------------
#
class AsteroidLarge extends Enemy
	constructor: (@game, @ctx, @speed_multiplier) ->
		rand = Math.random() * 2
		@speed = .8 + rand
		@sprite = this.rotateAndCache(ASSET_MANAGER.getAsset("images/asteroid2.png"))
		super
	
	update: ->
		super

	draw: ->
		super
#
# --------------------------------- EnemyShip -------------------------------------------
#
class EnemyShipOne extends Enemy
	constructor: (@game, @ctx) ->
	
		super
		
	update: ->
		super
		
	draw: ->
		super
#
# --------------------------------- Ship -------------------------------------------
#
class Ship extends VisualEntity
	constructor: (@game, @ctx) ->
		@weapons = []
		@sprite = ASSET_MANAGER.getAsset("images/ship1.png")
		@width = @sprite.width
		@height = @sprite.height
		super

	weapons: []
	sprite: null
	movement_speed: 1
	hp: 100
	
	setLocation: (x, y, z) ->
		@x = x
		@y = y
		@z = z
		
	shoot: (x, y, angle) ->
		for weapon in @weapons
			weapon.shoot(x, y, angle)
	
	addWeapon: (weapon) ->
		@weapons.push(weapon)
	
	
	update: ->
		
		super
		
	draw: ->
		ctx.drawImage(@sprite, @x - @width/2, @y - @height/2)
		super
#
# --------------------------------- Weapon -------------------------------------------
#
class Weapon
	constructor: (@game, @ctx) ->
	
	xOffset: 0
	yOffset: 0
	
	shoot: (x, y, angle) ->
		#@game.entities.push(new Bullet(@game, @ctx, x + @xOffset, y + @yOffset, 0))
		@game.stats.shots_fired += 1

#
# --------------------------------- Laser-------------------------------------------
#		
class Laser extends Weapon
	constructor: (@game, @ctx) ->
		@xOffset = 0
		@yOffset = 0
		super
	
	shoot: (x, y, angle) ->
		@game.entities.push(new Bullet(@game, @ctx, x + @xOffset, y + @yOffset, 0, "#F3FA69"))
		super

#
# --------------------------------- Double Laser-------------------------------------------
#
class DoubleLaser extends Weapon
	constructor: (@game, @ctx) ->
		@xOffset = 7
		@yOffset = 12
		super
		
	shoot: (x, y, angle) ->
		@game.entities.push(new Bullet(@game, @ctx, x + @xOffset, y - @yOffset, 10, "#96F3FA"))
		@game.entities.push(new Bullet(@game, @ctx, x - @xOffset, y - @yOffset, -10, "#96F3FA"))
		super
		#@game.stats.shots_fired += 1
		#super(x, y, null)
		#super(x - 2 * @xOffset, y - 2 * @yOffset, null)

#
# --------------------------------- Side Laser -------------------------------------------
#
class SideLaser extends Weapon
	constructor: (@game, @ctx) ->
		@xOffset = 14
		@yOffset = 16
		super
		
	shoot: (x, y, angle) ->
		@game.entities.push(new Bullet(@game, @ctx, x + @xOffset, y - @yOffset, 0))
		@game.entities.push(new Bullet(@game, @ctx, x - @xOffset, y - @yOffset, 0))
		super

#
# --------------------------------- Player -------------------------------------------
#
class Player extends VisualEntity
	constructor: (@game, @ctx) ->
		@x = 400
		@y = 600
		#@sprite = ASSET_MANAGER.getAsset("images/ship1.png")
		#@width = @sprite.width
		#@height = @sprite.height
		@lastMouseX = ctx.canvas.width / 2
		@lastMouseY = ctx.canvas.height / 2
		#@weapons = []
		#@weapons.push(new Laser(@game, @ctx))
		@ship = new Ship(@game, @ctx)
		@ship.addWeapon(new Laser(@game, @ctx))
		@ship.setLocation(@x, @y, null)
		@game.addEntity(@ship)
		super
	
	movement_speed: 7
	sprite: null
	lastMouseX: 0
	lastMouseY: 0
	laser: null
	weapons: []
	ship: null
	
	#shoot: (x, y, angle) ->
	#	try
	#		#for weapon in @weapons
	#		#	weapon.shoot(x, y, null)
	#		@ship.shoot(x, y, null)
	#	catch e
	#		alert e

	draw: ->
		unless game.keypress is null
			ctx.fillStyle = "#0000FF"
			ctx.fillRect(@x, @y, @width, @height)
			#console.log "#{@x} #{@y}"
		#ctx.drawImage(@sprite, @lastMouseX - @width/2, @lastMouseY - @height/2)
	
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
			#@shoot(game.click.x, game.click.y)
			@ship.shoot(game.click.x, game.click.y)
		
		unless game.mouse is null
			@lastMouseX = game.mouse.x
			@lastMouseY = game.mouse.y

		@ship.setLocation(@lastMouseX, @lastMouseY, null)

#
# --------------------------------- Level --------------------------------
#
class Level
	constructor: (@game, @ctx, @image) ->
		#@background = new BackgroundEntity(@game, @ctx, @image)
		
	title: "Level X"
	speed: 60
	enemy_count: 3
	level_complete: false
	background: null
	enemy_speed_multiplier: 1
		
	init: ->
		# @background = new BackgroundEntity(@game, @ctx, @image)
		#@game.current_enemy_displayed = 0
	
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
	constructor: (@game, @ctx, @image) ->
		@background = new BackgroundEntity(@game, @ctx, ASSET_MANAGER.getAsset("images/space1.jpg"))
		@enemy_count = 5
		super
	
	title: "Level 1"
	speed: 10

		
	update: ->
		super
	
	draw: ->
		super
		
class LevelTwo extends Level
	constructor: (@game, @ctx, @image) ->
		@background = new BackgroundEntity(@game, @ctx, ASSET_MANAGER.getAsset("images/space2.jpg"))
		@enemy_count = 10
		
	init: ->
		try
			@game.player.ship.weapons = []
			@game.player.ship.weapons.push(new DoubleLaser(@game, @ctx))
			super
		catch e
			alert "LevelTwo constructor: " + e
	
	title: "Level 2"
	speed: 60
		
	update: ->
		super
	
	draw: ->
		super

class LevelThree extends Level
	constructor: (@game, @ctx, @image) ->
		@background = new BackgroundEntiy(@game, @ctx, ASSET_MANAGER.getAsset("images/space1.jpg"))
		@enemy_count = 25
		@enemy_speed_multiplier = 1.5
		super
	
	title: "Level 3"
	speed: 60
	
	init: ->
		@game.player.ship.weapons.push(new SideLaser(@game, @ctx))
		
	update: ->
		super
	
	draw: ->
		super

class LevelFour extends Level
	constructor: (@game, @ctx, @image) ->
		@background = new BackgroundEntity(@game, @ctx, ASSET_MANAGER.getAsset("images/space2.jpg"))
		@enemy_count = 225
		@enemy_speed_multiplier = 2
		super
	
	title: "Level 4 Get Ready!"
	speed: 10
	
	init: ->
		#@game.player.ship.weapons.push(new SideLaser(@game, @ctx))
		
	update: ->
		super
	
	draw: ->
		super
#
# --------------------------------- Enemy Manager --------------------------------
#
class EnemyManager
	constructor: (@game, @ctx) ->
	
	lastEnemyAddedAt: null
	
	addEnemy: (speed_multiplier)->
		#console.log @current_enemy_count + "    " + @level_manager.current_level.enemy_count
		if @lastEnemyAddedAt = null or (@game.timer.gameTime - @lastEnemyAddedAt) > 1
			if Math.random() < 1/@game.level_manager.current_level.speed
				check = (Math.floor(Math.random()*10)) % 2
				enemy = null
				if check is 0
					enemy = new AsteroidSmall(@game, @ctx, speed_multiplier)
				else
					enemy = new AsteroidLarge(@game, @ctx, speed_multiplier)
				@game.addEntity(enemy) #new Enemy(@game, @ctx, speed_multiplier))
				@lastEnemyAddedAt = @game.timer.gameTime
				@game.stats.enemies_seen += 1
				@game.current_enemy_count += 1
				@game.current_enemy_displayed += 1
#
# --------------------------------- LevelManager --------------------------------
#
class LevelManager
	constructor: (@game, @ctx, @enemy_manager) ->
		try
			this.levels = []
			console.log "init levels - Levels length: " + this.levels.length
			this.levels.push(new LevelOne(@game, @ctx, ASSET_MANAGER.getAsset("images/space1.jpg")))
			console.log "RRR1 Levels length: " + this.levels.length
			this.levels.push(new LevelTwo(@game, @ctx, ASSET_MANAGER.getAsset("images/space2.jpg")))
			this.levels.push(new LevelThree(@game, @ctx, ASSET_MANAGER.getAsset("images/space1.jpg")))
			this.levels.push(new LevelFour(@game, @ctx, ASSET_MANAGER.getAsset("images/space2.jpg")))
			console.log "RRR Levels length: " + this.levels.length
			this.current_level = this.levels.shift()
			@level_changing = false
		catch e
			"Error in LevelManager constructor: " + e
	
	levels: []
	current_level: null
	level_changing: false
	level_change_end_time: null
	
			
	update: ->
		try
			# if the level is changing, we're going to display the level info
			if @level_changing
				unless @game.timer.gameTime <= @level_change_end_time
					@level_changing = false
			else
				if @game.current_enemy_count < @current_level.enemy_count
					@enemy_manager.addEnemy(@current_level.enemy_speed_multiplier)
					return true
				
				if this.shouldChangeLevel()
					# console.log "Enemy count is greater than the levels..."
					if @levels.length > 0
						console.log "About to shift..."
						@current_level = @levels.shift()
						@current_level.init()
						@game.current_enemy_count = 0
						@game.background = @current_level.background
						console.log "CHANGING BACKGROUND: " + @current_level.background.image.src
						@level_changing = true
					else
						console.log "Game should be over"
						@game.game_over = true
					#@level_changing = true
					@level_change_end_time = @game.timer.gameTime + 3
					console.log "GameTime: #{@game.timer.gameTime} and EndTime: #{@level_change_end_time}"
				else
					@level_changing = false
		catch e
			alert "Error in LevelManager: " + e
	
	shouldChangeLevel: ->
		#console.log "game.current_enemy_count: #{@game.current_enemy_count} || current_level.enemy_count: #{@current_level.enemy_count}"
		if @game.current_enemy_count >= @current_level.enemy_count
			if @game.current_enemy_displayed > 0
				return false
			else
				# alert "No more enemies displayed..."
				return true
		else
			return false
		
			
	draw: ->
		unless @current_level is null or @game.game_over
			if @level_changing
				@ctx.font = "bold 26px Verdana"
				@ctx.fillStyle = "#FFF"
				textSize = @ctx.measureText(@current_level.title)
				@ctx.fillText(@current_level.title, (@ctx.canvas.width / 2) - (textSize.width / 2), @ctx.canvas.height / 2)
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
	stats: new GameStats()
	debug_stats: new Stats()
	timer: new Timer()
	clockTick = null
	
	init: (ctx) ->
		try
			console.log "Initialized"
			this.ctx = ctx
			this.clockTick = this.timer.tick()
			document.body.appendChild(@debug_stats.domElement)
		
			# start listening to input
			this.startInput()
		catch e
			alert "in GameEngine.init(): " + e
		
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
		@ctx.save()
		this.ctx.clearRect(0, 0, @ctx.canvas.width, @ctx.canvas.height)
		for entity in this.entities
			if entity.active
				entity.draw()
		if (callback)
			callback(true)
		@ctx.restore()

	start: ->
		try
			console.log("starting game")
			that = this
			(gameLoop = ->
				that.loop()
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
		this.debug_stats.update()
		#this.stats.update()	

#
# --------------------------------- MyShooter --------------------------------
#
class MyShooter extends GameEngine
	lives: 10
	score: 0
	game_over: false
	level_manager: null
	current_enemy_count: 0
	current_enemy_displayed: 0
	is_paused: false
	background: null
	enemy_manager: null
	
	pregameSetup: ->
		this.is_paused = false
		this.game_over = false
		this.entities = []
		this.lives = 10
		this.score = 0
		this.current_enemy_count = 0
		this.current_enemy_displayed = 0
		this.stats = new GameStats()
		# Load images
		@background = new BackgroundEntity(this, this.ctx, ASSET_MANAGER.getAsset("images/space1.jpg"))
		#backgroundOne.draw()
		this.entities.push(@background)
		
		# Entities
		this.player = new Player(this, this.ctx)
		this.entities.push(this.player)
		
		# Enemy Manager
		this.enemy_manager = new EnemyManager(this, this.ctx)
		
		# Level Manager
		this.level_manager = null
		this.level_manager = new LevelManager(this, this.ctx, @enemy_manager)
			
		$("#surface").css("cursor", "none")
	
	start: ->
		this.pregameSetup()
		super
		
	update: ->
		if this.lives <= 0 or @game_over
			$("#surface").css("cursor", "crosshair")
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
		
		@level_manager.update()

		for entity in @entities
			if entity instanceof BackgroundEntity
				entity = @background
				console.log entity.image.src
		super
	
				
	draw: ->
		try
			#@background.draw()
			if @is_paused
				this.drawPauseScreen()
				return true
			
			#@background = @level_manager.current_level.background
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
# It requires these variables to be set...
ASSET_MANAGER = null
game = null
ctx = null
try
	$ ->
		canvas = $("#surface")
		ctx = canvas.get(0).getContext("2d")
	
		game = new MyShooter #GameEngine
		ASSET_MANAGER = new AssetManager()
		
		ASSET_MANAGER.queueDownload("images/asteroid.png")
		ASSET_MANAGER.queueDownload("images/asteroid2.png")
		ASSET_MANAGER.queueDownload("images/explosion.png")
		ASSET_MANAGER.queueDownload("images/ship1.png")
		ASSET_MANAGER.queueDownload("images/space1.jpg")
		ASSET_MANAGER.queueDownload("images/space2.jpg")
		
		ASSET_MANAGER.downloadAll =>
			game.init(ctx)
			game.start()
			true
catch e
	alert e
console.log "at the end"

