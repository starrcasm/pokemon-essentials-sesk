#===============================================================================
# # Klein Water Pond Bubbles for Pokémon Essentials
# # Give credits if you're using this!
# # http://kleinstudio.deviantart.com
#
# bo4p5687 (update)
#===============================================================================

# Fix event comment
def pbEventCommentInput(*args)
  parameters = []
  list = *args[0].list   # Event or event page
  elements = *args[1]    # Number of elements
  trigger = *args[2]     # Trigger
  return nil if list == nil
  return nil unless list.is_a?(Array)
  for item in list
    next unless item.code == 108 || item.code == 408
    if item.parameters[0] == trigger[0]
      start = list.index(item) + 1
      finish = start + elements[0]
      for id in start...finish
        next if !list[id]
        parameters.push(list[id].parameters[0])
      end
      return parameters
    end
  end
  return nil
end

module WaterPondBublesVariables
	# Regardless of the above setting,the species in this array will always animate
	# Following can't have this animated
	FOLLOWING_CANT_HAVE = [12,15,17
		# Example:
		# 12,15,17
	]

	WATER_POND_BUBBLE = GameData::TerrainTag.get(:StillWater)

	def self.get_new_id
		newId = 1
		while !$game_map.events[newId].nil? do
			break if $game_map.events[newId].erased
			newId += 1
		end
		return newId
	end

	def self.show(event, position)
		if event != $game_player
			return if event.character_name == "" || event.character_name == "nil" || event.name.include?("/nowb/")
			return if pbEventCommentInput(event, 0, "NoWb")
			if $Trainer.party.length > 0
				return if (!($game_map.events[event] && $game_map.events[event].name == "Dependent") &&
									(FOLLOWING_DONT_WALK.include?($Trainer.party[0].species) || $PokemonGlobal.bicycle))
			end
		end
		character_sprites = $scene.spriteset.character_sprites
		viewport = $scene.spriteset.viewport1
		wbsprites = $scene.spriteset.wbsprites
		nid = self.get_new_id
		rpgEvent    = RPG::Event.new(position[0], position[1])
		rpgEvent.id = nid
		fev = Game_Event.new($game_map.map_id, rpgEvent, $game_map)
		eventsprite = Sprite_Character.new(viewport, fev)
		character_sprites.push(eventsprite)
		wbsprites.push(PondWaterBubbleSprite.new(eventsprite, fev, viewport, $game_map, position[2], nid, character_sprites, (event==$game_player)))
	end

end

class Game_Event < Game_Character
  attr_reader :erased
end

class Sprite_Character
  alias old_initialize_wb initialize
  def initialize(viewport, character = nil)
    old_initialize_wb(viewport, character)
    @disposed=false
  end

  alias old_update_wb update
  def update
    return if @disposed
    old_update_wb
  end

  alias old_dispose_wb dispose
  def dispose
    old_dispose_wb
    @disposed=true
  end
end

class Spriteset_Map
  attr_accessor :character_sprites
  attr_accessor :wbsprites

  alias old_initialize_wb initialize
  def initialize(map=nil)
    old_initialize_wb(map)
    @wbsprites = []
  end

  def putWaterBubble(event, pos) = WaterPondBublesVariables.show(event, pos)

  alias old_dispose_wb dispose
  def dispose
    old_dispose_wb
		@wbsprites.each { |sprite| sprite.dispose } if !@wbsprites.nil?
    @wbsprites.clear
  end

  alias old_update_wb update
  def update
    old_update_wb
		return if @wbsprites.nil?
		@wbsprites.each { |sprite| sprite.update }
  end
end

class Scene_Map
  def spriteset? = !@spritesets.nil?
end

class Game_Character
	def water_pond_buble? = $game_map.terrain_tag(@x, @y) == WaterPondBublesVariables::WATER_POND_BUBBLE && $scene.is_a?(Scene_Map) && $scene.spriteset?

	alias leave_tile_wb triggerLeaveTile
	def triggerLeaveTile
		leave_tile_wb
		$scene.spriteset.putWaterBubble(self, [@x,@y,direction]) if water_pond_buble?
	end
end

class PondWaterBubbleSprite
  def initialize(sprite, event, viewport, map, direction, nid, chardata, player)
    @rsprite = sprite
		# Sprite
    @sprite  = Sprite.new(viewport)
    @sprite.bitmap = RPG::Cache.load_bitmap("Graphics/Pictures/Water Pond Bubles/", "Water Pond Bubble")
		# Position
    @actualframe = -2
    @count = 0
    @frames = @sprite.bitmap.width/@sprite.bitmap.height
    @width = @sprite.bitmap.height
    @sprite.src_rect.width=@width
    pbDayNightTint(@sprite)
		# Value
    @event = event
    @disposed = false
    @map = map
    @eventid  = nid
    @viewport = viewport
    @chardata = chardata
    @sprite.visible = false
    update
  end

  def updateAnimation
    @count+=1
		return if @count != 6
		if @actualframe < @frames
			@actualframe += 1
			@sprite.src_rect.x = @actualframe * @width
			@sprite.visible = true if @actualframe >= 0
		end
		@count=0
  end

  def dispose
		return if @disposed
		@disposed = true
		@event.erase
		(0...@chardata.length).each { |i| @chardata.delete_at(i) if @chardata[i] == @rsprite }
		@rsprite.dispose
		@sprite.dispose
		@sprite = nil
  end

  def update
    return if @disposed
    updateAnimation
    x = @rsprite.x - @rsprite.ox
    y = @rsprite.y - @rsprite.oy
    width  = @rsprite.src_rect.width
    height = @rsprite.src_rect.height
    @sprite.x  = x + width / 2
    @sprite.y  = y + height
    @sprite.ox = @width / 2
    @sprite.oy = @sprite.bitmap.height
    @sprite.z  = @rsprite.z - 1
    dispose if @actualframe >= @frames
  end
end
