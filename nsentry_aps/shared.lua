ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "NSentry APS"
ENT.Author = "NachinBombin"
ENT.Category = "Defense Systems"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.IconOverride = "materials/entities/nsentrygun.png"

ENT.STATE_BROKEN     = -1
ENT.STATE_OFF        =  0
ENT.STATE_WATCHING   =  1
ENT.STATE_SEARCHING  =  2
ENT.STATE_ENGAGING   =  3
ENT.STATE_OVERHEATED =  4  -- repurposed: intercept cooldown

function ENT:SetupDataTables()
    self:NetworkVar("Int",   0, "State")
    self:NetworkVar("Int",   1, "HP")
    self:NetworkVar("Float", 0, "AimPitch")
    self:NetworkVar("Float", 1, "AimYaw")
    self:NetworkVar("Float", 2, "Heat")
    self:NetworkVar("Float", 3, "BarrelSpin")
end
