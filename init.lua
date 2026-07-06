local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local textures = minetest.get_dir_list(modpath .. "/textures", false)
local npc_textures = {}
for _, filename in ipairs(textures) do
    if filename:match("%.png$") then
        table.insert(npc_textures, filename)
    end
end

if #npc_textures == 0 then
    table.insert(npc_textures, "character.png")
end

minetest.register_entity(modname .. ":npc", {
    initial_properties = {
        hp_max = 20,
        physical = true,
        collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
        visual = "mesh",
        mesh = "character.b3d",
        textures = {npc_textures[1]},
        makes_footstep_sound = true,
        armor_groups = {fleshy = 100},
    },

    on_activate = function(self, staticdata)
        local tex
        if staticdata and staticdata ~= "" then
            tex = staticdata
        else
            tex = npc_textures[math.random(#npc_textures)]
        end
        self._texture = tex
        self.object:set_properties({textures = {tex}})
        
        -- Winking/digging animation for character.b3d is frames 189-198
        self.object:set_animation({x=189, y=198}, 30, 0)
        self.object:set_acceleration({x=0, y=-9.81, z=0})
    end,

    get_staticdata = function(self)
        return self._texture or ""
    end,

    on_step = function(self, dtime)
        self.timer = (self.timer or 0) + dtime
        if self.timer > 1.0 then
            self.timer = 0
            local pos = self.object:get_pos()
            local node = minetest.get_node(pos)
            
            if minetest.get_item_group(node.name, "lava") > 0 then
                self.object:punch(self.object, 1.0, {
                    full_punch_interval = 1.0,
                    damage_groups = {fleshy = 10},
                }, nil)
            elseif minetest.get_item_group(node.name, "water") > 0 then
                self.object:punch(self.object, 1.0, {
                    full_punch_interval = 1.0,
                    damage_groups = {fleshy = 2},
                }, nil)
            end
        end
    end
})

minetest.register_craftitem(modname .. ":spawner", {
    description = "Winker NPC Spawner",
    inventory_image = minetest.inventorycube(npc_textures[1], npc_textures[1], npc_textures[1]),
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type == "node" then
            local pos = pointed_thing.above
            local obj = minetest.add_entity(pos, modname .. ":npc")
            
            if obj and placer and placer:is_player() then
                local placer_pos = placer:get_pos()
                local dir = vector.subtract(placer_pos, pos)
                local yaw = minetest.dir_to_yaw(dir)
                obj:set_yaw(yaw)
            end
            
            local player_name = placer and placer:get_player_name() or ""
            local is_creative = false
            if minetest.is_creative_enabled and minetest.is_creative_enabled(player_name) then
                is_creative = true
            end
            
            if not is_creative then
                itemstack:take_item()
            end
            return itemstack
        end
    end,
})
