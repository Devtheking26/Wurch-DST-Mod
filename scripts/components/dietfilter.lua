-- dietfilter.lua
local DietFilter = Class(function(self, inst)
    self.inst = inst
end)

-- Call once from your prefab after adding the component.
function DietFilter:Apply()
    local inst = self.inst
    if inst.components.eater ~= nil then
        inst.components.eater:SetDiet({
            FOODTYPE.VEGGIE,
            FOODTYPE.SEEDS,
        }, nil)
    else
        -- If eater isn’t present yet, set it next tick without listeners.
        inst:DoTaskInTime(0, function()
            if inst.components.eater ~= nil then
                inst.components.eater:SetDiet({
                    FOODTYPE.VEGGIE,
                    FOODTYPE.SEEDS,
                }, nil)
            end
        end)
    end
end

return DietFilter
