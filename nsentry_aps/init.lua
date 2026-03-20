AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- ============================================================
--  CONFIG
-- ============================================================
local CONFIG = {
    MODEL           = "models/codbo6/other/sentry.mdl",
    MASS            = 150,
    MAX_HEALTH      = 500,
    HEIGHT_OFFSET   = 55,
    MUZZLE_FALLBACK = Vector(34, 0, 55),

    SCAN_RADIUS          = 600,
    SCAN_INTERVAL        = 0.01,
    MIN_SPEED            = 1100,
    INTERCEPT_DELAY      = 0.04,
    OVERHEAT_VISUAL_TIME = 0.4,

    TURN_SPEED      = 60,

    IDLE_SCAN_DELAY_MIN = 3,
    IDLE_SCAN_DELAY_MAX = 6,
    IDLE_HOLD_TIME_MIN  = 1,
    IDLE_HOLD_TIME_MAX  = 2,
    IDLE_YAW_RANGE      = 40,
    IDLE_PITCH_RANGE    = 15,

    BURST_DURATION  = 0.4,   -- seconds of fire after intercept
    BURST_INTERVAL  = 0.02, -- <0.03 per shot — insane fire rate
}

-- ============================================================
--  THREAT CLASS LIST
-- ============================================================
local INTERCEPT_TARGETS = {
    -- Source / HL2 base
    ["rpg_missile"]               = true,
    ["grenade_ar2"]               = true,
    ["npc_grenade_frag"]          = true,
    ["prop_combine_ball"]         = true,
    ["hunter_flechette"]          = true,
    ["crossbow_bolt"]             = true,
    ["grenade_helicopter"]        = true,
    ["combine_mine"]              = true,
    ["npc_satchel"]               = true,
    ["satchel_charge"]            = true,
    ["npc_manhack"]               = true,

    -- VJ Base
    ["obj_vj_grenade"]            = true,
    ["obj_vj_rocket"]             = true,
    ["obj_vj_flechette"]          = true,

    -- Javelin / Stinger addons
    ["sent_javelin_missile"]      = true,
    ["sent_stinger_missile"]      = true,

    -- Neurotec weapons
    ["neuro_missile"]             = true,
    ["neuro_rocket"]              = true,

    -- M9K weapons
    ["m9k_released_rpg"]          = true,
    ["m9k_davy_crockett_payload"] = true,
    ["m9k_40mm_grenade"]          = true,
    ["m9k_mad_grenade"]           = true,

    -- CW 2.0
    ["cw_grenade_thrown"]         = true,

    -- FA:S 2
    ["fas2_thrown_m67"]           = true,

    -- WAC Helicopters
    ["wac_hc_rocket"]             = true,

    -- LVS vehicles
    ["lvs_missile"]               = true,

    -- TFA Base projectiles
    ["tfa_proj_arrow"]            = true,
    ["tfa_proj_arrow_fire"]       = true,
    ["tfa_arrow"]                 = true,
    ["tfa_missile"]               = true,
    ["tfa_rocket"]                = true,
    ["tfa_proj_grenade"]          = true,
    ["tfa_thrown_knife"]          = true,

    -- Modern Warfare sweps
    ["mw_throwingknife"]          = true,
    ["mw_missile"]                = true,
    ["mw_rocket"]                 = true,
    ["mw_gl_grenade"]             = true,
    ["mw_fraggrenade"]            = true,
    ["mw_semtex"]                 = true,
    ["mw_flashbang"]              = true,
    ["mw_smokegrenade"]           = true,

    -- ArcCW projectiles
    ["arccw_rocket"]              = true,
    ["arccw_missile"]             = true,
    ["arccw_gl_projectile"]       = true,
    ["arccw_grenade_thrown"]      = true,
    ["arccw_c4"]                  = true,
    ["arccw_semtex"]              = true,
    ["arccw_flashbang"]           = true,
    ["arccw_smoke"]               = true,
    ["arccw_thermite"]            = true,

    -- ArcCW9 projectiles
    ["arccw9_rocket"]             = true,
    ["arccw9_missile"]            = true,
    ["arccw9_gl_projectile"]      = true,
    ["arccw9_thrown_grenade"]     = true,
    ["arccw9_c4"]                 = true,

    -- Simfphys missiles
    ["simfphys_missile"]          = true,
    ["simfphys_rocket"]           = true,
    ["simfphys_tankrocket"]       = true,
    ["simfphys_glshell"]          = true,

    -- DrGBase projectiles
    ["drg_projectile"]            = true,
    ["drg_grenade"]               = true,
    ["drg_rocket"]                = true,

    -- LFS aircraft weapons
    ["lfs_missile"]               = true,
    ["lfs_rocket"]                = true,
    ["lfs_torpedo"]               = true,

    -- generic addon missiles
    ["sent_homingrocket"]         = true,
    ["sent_guidedmissile"]        = true,
    ["sent_stickynade"]           = true,
    ["sent_cluster_grenade"]      = true,
    ["sent_flashbang"]            = true,
}

-- ============================================================
--  SOUNDS
-- ============================================================
local RADAR_LOOP       = "npc/turret_floor/ping.wav"
local LOCK_SOUNDS      = { "npc/turret_floor/active.wav", "npc/scanner/scanner_scan2.wav" }
local INTERCEPT_SOUNDS = {
    "ambient/explosions/explode_4.wav",
    "ambient/explosions/explode_5.wav",
    "weapons/stinger/fire.wav",
    "weapons/shotgun/shotgun_fire7.wav",
}
local ELECTRONIC_DISRUPT = {
    "npc/roller/mine/rmine_blip3.wav",
    "npc/roller/mine/rmine_explode_shock1.wav",
}

-- ============================================================
--  SOUND HELPERS
-- ============================================================
function ENT:StartRadarLoop()
    if self.RadarSound then return end
    self.RadarSound = CreateSound(self, RADAR_LOOP)
    if self.RadarSound then self.RadarSound:PlayEx(0.6, 110) end
end

function ENT:StopRadarLoop()
    if self.RadarSound then
        self.RadarSound:Stop()
        self.RadarSound = nil
    end
end

function ENT:PlayLockSound()
    for _, snd in ipairs(LOCK_SOUNDS) do self:EmitSound(snd, 80, 120) end
end

function ENT:PlayInterceptSounds()
    for _, snd in ipairs(INTERCEPT_SOUNDS)   do self:EmitSound(snd, 95,  math.random(95,  105)) end
    for _, snd in ipairs(ELECTRONIC_DISRUPT) do self:EmitSound(snd, 85,  math.random(105, 120)) end
end

-- ============================================================
--  INITIALIZE
-- ============================================================
function ENT:Initialize()
    self:SetModel(CONFIG.MODEL)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(CONFIG.MASS)
    end

    self:SetState(self.STATE_OFF)
    self:SetHP(CONFIG.MAX_HEALTH)
    self:SetAimPitch(0)
    self:SetAimYaw(0)
    self:SetHeat(0)
    self:SetBarrelSpin(0)

    self.MaxHealth        = CONFIG.MAX_HEALTH
    self.TurnSpeed        = CONFIG.TURN_SPEED
    self.BarrelSpinTarget = 0

    self.IsLocked       = false
    self.LockedTarget   = nil
    self.FireTime       = 0

    self.NextIdleLook    = 0
    self.IdleTargetYaw   = nil
    self.IdleTargetPitch = nil
    self.IdleHoldUntil   = nil
    self.IdleScanPhase   = nil

    self.Owner          = nil
    self.Whitelist      = {}
    self.HoldingPlayers = {}
    self.LastClickTime  = {}
end

-- ============================================================
--  SPAWN FUNCTION
-- ============================================================
function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end
    local ent = ents.Create(ClassName)
    ent:SetPos(tr.HitPos + tr.HitNormal * 10)
    ent:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
    ent:Spawn()
    ent:Activate()
    ent.Owner = ply
    ent.Whitelist = ent.Whitelist or {}
    ent.Whitelist[ply] = true
    return ent
end

-- ============================================================
--  USE  (short press = toggle | long press = pickup)
-- ============================================================
local WHITELIST_HOLD_TIME = 2

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self:GetState() == self.STATE_BROKEN then return end
    self.HoldingPlayers = self.HoldingPlayers or {}
    if not self.HoldingPlayers[activator] then
        self.HoldingPlayers[activator] = CurTime()
    end
end

-- ============================================================
--  UPDATE HOLDING PLAYERS
-- ============================================================
function ENT:UpdateHoldingPlayers()
    if not self.HoldingPlayers then self.HoldingPlayers = {} return end
    local time = CurTime()
    for ply, startTime in pairs(self.HoldingPlayers) do
        if not IsValid(ply) or not ply:KeyDown(IN_USE) then
            local held = time - startTime
            if held < WHITELIST_HOLD_TIME then
                local state = self:GetState()
                if state == self.STATE_OFF then
                    self:SetState(self.STATE_WATCHING)
                    self:StartRadarLoop()
                    self:EmitSound("npc/turret_floor/active.wav", 65, 100)
                else
                    self:SetState(self.STATE_OFF)
                    self:StopRadarLoop()
                    self:EmitSound("npc/turret_floor/retract.wav", 65, 100)
                    self.IsLocked     = false
                    self.LockedTarget = nil
                end
           else
    ply.APS_Queue = ply.APS_Queue or {}
    table.insert(ply.APS_Queue, "nsentry_aps")
    ply:EmitSound("items/ammo_pickup.wav", 80, 100)
    ply:ChatPrint("[APS] Picked up. Queue: " .. #ply.APS_Queue)
                self.HoldingPlayers = {}
                self:Remove()
                return
            end
            self.HoldingPlayers[ply] = nil
        end
    end
end

-- ============================================================
--  UPDATE BARREL SPIN
-- ============================================================
function ENT:UpdateBarrelSpin()
    local cur    = self:GetBarrelSpin()
    local target = self.BarrelSpinTarget or 0
    if cur ~= target then
        local rate = target > cur and 0.15 or 0.1
        self:SetBarrelSpin(math.Clamp(cur + (target - cur) * rate, 0, 1))
    end
end

-- ============================================================
--  MAIN THINK  (10ms)
-- ============================================================
function ENT:Think()
    local time = CurTime()

    self:UpdateHoldingPlayers()
    self:UpdateBarrelSpin()

    local state = self:GetState()

    if state == self.STATE_BROKEN or state == self.STATE_OFF then
        self.BarrelSpinTarget = 0
        self:NextThink(time + CONFIG.SCAN_INTERVAL)
        return true
    end

    if self.RadarSound then
        self.RadarSound:ChangePitch(math.random(105, 115), 0)
    end

    if state == self.STATE_ENGAGING then
        if not IsValid(self.LockedTarget) then
            self:StandDown()
        elseif time >= self.FireTime then
            self:Intercept(self.LockedTarget)
        end
        self:NextThink(time + CONFIG.SCAN_INTERVAL)
        return true
    end

    -- STATE_OVERHEATED and STATE_WATCHING: scan runs, orange is cosmetic
    local threat = self:ScanForThreat()
    if threat then
        self:LockOn(threat)
    else
        self:PerformIdleScan(time)
    end

    self:NextThink(time + CONFIG.SCAN_INTERVAL)
    return true
end

-- ============================================================
--  THREAT DETECTION
-- ============================================================
function ENT:ScanForThreat()
    local myPos    = self:GetPos()
    local entities = ents.FindInSphere(myPos, CONFIG.SCAN_RADIUS)

    for _, ent in ipairs(entities) do
        if not IsValid(ent)                  then continue end
        if ent == self                       then continue end
        if ent == self:GetOwner()            then continue end
        if ent:GetClass() == self:GetClass() then continue end

        local class    = string.lower(ent:GetClass())
        local isThreat = false

        if INTERCEPT_TARGETS[class] then
            isThreat = true
        elseif string.find(class, "missile")
            or string.find(class, "rocket")
            or string.find(class, "grenade") then
            isThreat = true
        elseif ent.Base == "sent_neuro_missile_base"
            or ent.Base == "sent_neuro_missile" then
            isThreat = true
        elseif not ent:IsPlayer() and not ent:IsVehicle() then
            if ent:GetVelocity():Length() > CONFIG.MIN_SPEED then
                isThreat = true
            end
        end

        if isThreat then return ent end
    end

    return nil
end

-- ============================================================
--  LOCK ON  — instant aim snap
-- ============================================================
function ENT:LockOn(threat)
    self.IsLocked         = true
    self.LockedTarget     = threat
    self.FireTime         = CurTime() + CONFIG.INTERCEPT_DELAY
    self.BarrelSpinTarget = 1.0

    local targPos   = threat:GetPos()
    local selfPos   = self:GetPos() + self:GetUp() * CONFIG.HEIGHT_OFFSET
    local targAng   = self:WorldToLocalAngles((targPos - selfPos):Angle())
    local snapPitch = math.Clamp(-targAng.p, -45, 45)
    local snapYaw   = targAng.y
    if snapYaw >  180 then snapYaw = snapYaw - 360 end
    if snapYaw < -180 then snapYaw = snapYaw + 360 end
    self:SetAimPitch(snapPitch)
    self:SetAimYaw(math.Clamp(snapYaw, -180, 180))

    self:StopRadarLoop()
    self:PlayLockSound()
    self:SetState(self.STATE_ENGAGING)
end

-- ============================================================
--  VISUAL BURST FIRE  (pure visuals, no damage)
-- ============================================================
function ENT:StartVisualBurst()
    local burstEnd   = CurTime() + CONFIG.BURST_DURATION
    local timerName  = "nsentry_burst_" .. self:EntIndex()

    -- Kill any previous burst still running (back-to-back intercepts)
    timer.Remove(timerName)

    timer.Create(timerName, CONFIG.BURST_INTERVAL, 0, function()
        if not IsValid(self) or CurTime() >= burstEnd then
            timer.Remove(timerName)
            return
        end

        local muzzlePos, aimAng = self:GetMuzzlePositionAndAngle()

        -- Muzzle flash geometry
        local flash = EffectData()
        flash:SetOrigin(muzzlePos)
        flash:SetNormal(aimAng:Forward())
        flash:SetAngles(aimAng)
        util.Effect("MuzzleEffect", flash)

        -- Particle muzzle flash (the bright visible one from FireWeapon)
        ParticleEffect("muzzleflash_pistol", muzzlePos, aimAng, self)

        -- Tracer following the barrel direction
        local tr = util.TraceLine({
            start   = muzzlePos,
            endpos  = muzzlePos + aimAng:Forward() * 10000,
            filter  = self,
            mask    = MASK_SHOT,
        })
        local tracerData = EffectData()
        tracerData:SetStart(muzzlePos)
        tracerData:SetOrigin(tr.HitPos)
        tracerData:SetScale(5000)
        util.Effect("Tracer", tracerData)

        -- AR2 fire sound with small pitch shift per shot — insane rate
        self:EmitSound("weapons/ar2/fire1.wav", 75, math.random(97, 108))
    end)
end

-- ============================================================
--  INTERCEPT
-- ============================================================
function ENT:Intercept(target)
    if not IsValid(target) then
        self:StandDown()
        return
    end

    local targetPos            = target:GetPos()
    local muzzlePos, muzzleAng = self:GetMuzzlePositionAndAngle()
    local dir                  = (targetPos - muzzlePos):GetNormalized()

    -- One-shot kill flash at barrel tip pointing at target
    local flash = EffectData()
    flash:SetOrigin(muzzlePos)
    flash:SetNormal(dir)
    flash:SetAngles(muzzleAng)
    util.Effect("MuzzleEffect", flash)

    ParticleEffect("muzzleflash_pistol", muzzlePos, muzzleAng, self)

    -- Tracer: barrel → intercept point
    local tracer = EffectData()
    tracer:SetStart(muzzlePos)
    tracer:SetOrigin(targetPos)
    tracer:SetScale(5000)
    util.Effect("Tracer", tracer)

    -- Explosion at target pos
    local explosion = EffectData()
    explosion:SetOrigin(targetPos)
    util.Effect("Explosion", explosion)

    self:PlayInterceptSounds()
    util.ScreenShake(self:GetPos(), 20, 250, 0.7, 1500)

    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():Distance(self:GetPos()) < 500 then
            ply:SetVelocity(VectorRand() * 200)
        end
    end

    if target.Destroyed       ~= nil then target.Destroyed       = true end
    if target.ExplodeCallback ~= nil then target.ExplodeCallback = nil  end

    SafeRemoveEntity(target)

    -- Start 1-second visual burst following the barrel
    self:StartVisualBurst()

    -- Reset state — brief orange laser flash, scan resumes immediately
    self.IsLocked         = false
    self.LockedTarget     = nil
    self.BarrelSpinTarget = 0
    self:SetState(self.STATE_OVERHEATED)
    self:StartRadarLoop()
    timer.Simple(CONFIG.OVERHEAT_VISUAL_TIME, function()
        if IsValid(self) and self:GetState() == self.STATE_OVERHEATED then
            self:SetState(self.STATE_WATCHING)
        end
    end)
end

-- ============================================================
--  STAND DOWN
-- ============================================================
function ENT:StandDown()
    self.IsLocked         = false
    self.LockedTarget     = nil
    self.BarrelSpinTarget = 0
    self:SetState(self.STATE_WATCHING)
    self:StartRadarLoop()
end

-- ============================================================
--  3D AIMING MATH
-- ============================================================
function ENT:GetTargetAimOffset(point)
    if not point then return 0, 0 end
    local selfPos = self:GetPos() + self:GetUp() * CONFIG.HEIGHT_OFFSET
    local targAng = self:WorldToLocalAngles((point - selfPos):Angle())
    return -self:GetAimPitch() - targAng.p, self:GetAimYaw() - targAng.y
end

function ENT:Turn(pitch, yaw)
    local dt = CONFIG.SCAN_INTERVAL
    self:Point(
        self:GetAimPitch() + math.Clamp(pitch, -self.TurnSpeed * dt / 8, self.TurnSpeed * dt / 8),
        self:GetAimYaw()   - math.Clamp(yaw,   -self.TurnSpeed * dt / 4, self.TurnSpeed * dt / 4)
    )
end

function ENT:Point(pitch, yaw)
    if pitch then self:SetAimPitch(math.Clamp(pitch, -45, 45)) end
    if yaw then
        if yaw >  180 then yaw = yaw - 360 end
        if yaw < -180 then yaw = yaw + 360 end
        self:SetAimYaw(math.Clamp(yaw, -180, 180))
    end
end

function ENT:ReturnToForward()
    local x, y = self:GetAimYaw(), self:GetAimPitch()
    if x == 0 and y == 0 then return end
    local dt = CONFIG.SCAN_INTERVAL
    self:Point(
        y + math.Clamp(-y, -self.TurnSpeed * dt / 8, self.TurnSpeed * dt / 8),
        x - math.Clamp( x, -self.TurnSpeed * dt / 4, self.TurnSpeed * dt / 4)
    )
end

-- ============================================================
--  IDLE SCAN
-- ============================================================
function ENT:PerformIdleScan(time)
    if not self.IdleScanPhase then
        self.IdleScanPhase = "centered"
        self.NextIdleLook  = time + math.Rand(CONFIG.IDLE_SCAN_DELAY_MIN, CONFIG.IDLE_SCAN_DELAY_MAX)
    end

    local curYaw   = self:GetAimYaw()
    local curPitch = self:GetAimPitch()

    if self.IdleScanPhase == "centered" then
        if time > self.NextIdleLook then
            self.IdleTargetYaw   = math.Rand(-CONFIG.IDLE_YAW_RANGE,   CONFIG.IDLE_YAW_RANGE)
            self.IdleTargetPitch = math.Rand(-CONFIG.IDLE_PITCH_RANGE, CONFIG.IDLE_PITCH_RANGE)
            self.IdleScanPhase   = "scanning"
        elseif math.abs(curYaw) > 1 or math.abs(curPitch) > 1 then
            self:ReturnToForward()
        end

    elseif self.IdleScanPhase == "scanning" then
        local needYaw   = curYaw   - self.IdleTargetYaw
        local needPitch = -curPitch - self.IdleTargetPitch
        if math.abs(needYaw) > 2 or math.abs(needPitch) > 2 then
            self:Turn(needPitch, needYaw)
        else
            self.IdleScanPhase = "holding"
            self.IdleHoldUntil = time + math.Rand(CONFIG.IDLE_HOLD_TIME_MIN, CONFIG.IDLE_HOLD_TIME_MAX)
        end

    elseif self.IdleScanPhase == "holding" then
        if time > self.IdleHoldUntil then self.IdleScanPhase = "returning" end

    elseif self.IdleScanPhase == "returning" then
        if math.abs(curYaw) > 1 or math.abs(curPitch) > 1 then
            self:ReturnToForward()
        else
            self.IdleScanPhase = "centered"
            self.NextIdleLook  = time + math.Rand(CONFIG.IDLE_SCAN_DELAY_MIN, CONFIG.IDLE_SCAN_DELAY_MAX)
        end
    end
end

-- ============================================================
--  MUZZLE POSITION  (NSentry bone math, 3-tier fallback)
-- ============================================================
function ENT:GetMuzzlePositionAndAngle()
    local baseUpperBone = self:LookupBone("sentry_base_upper")
    local muzzleBone    = self:LookupBone("sentry_barrels_extrabone")

    if baseUpperBone and muzzleBone then
        local baseUpperMatrix = self:GetBoneMatrix(baseUpperBone)
        local muzzleMatrix    = self:GetBoneMatrix(muzzleBone)
        if baseUpperMatrix and muzzleMatrix then
            local pivotWorldPos  = baseUpperMatrix:GetTranslation()
            local muzzleWorldPos = muzzleMatrix:GetTranslation()
            local pivotToMuzzle  = self:WorldToLocal(muzzleWorldPos) - self:WorldToLocal(pivotWorldPos)
            local pivotLocalPos  = self:WorldToLocal(pivotWorldPos)
            local selfPos        = self:GetPos()
            local up             = self:GetUp()
            local yawAng         = Angle(self:GetAngles())
            yawAng:RotateAroundAxis(up, self:GetAimYaw())
            local pivotPos = selfPos
                + yawAng:Forward() * pivotLocalPos.x
                + yawAng:Right()   * pivotLocalPos.y
                + yawAng:Up()      * pivotLocalPos.z
            local aimAng = Angle(yawAng)
            aimAng:RotateAroundAxis(aimAng:Right(), self:GetAimPitch())
            local muzzlePos = pivotPos
                + aimAng:Forward() * pivotToMuzzle.x
                + aimAng:Right()   * pivotToMuzzle.y
                + aimAng:Up()      * pivotToMuzzle.z
            return muzzlePos, aimAng
        end
    end

    if muzzleBone then
        local boneMatrix = self:GetBoneMatrix(muzzleBone)
        if boneMatrix then
            local boneLocalPos = self:WorldToLocal(boneMatrix:GetTranslation())
            local aimAng       = Angle(self:GetAngles())
            aimAng:RotateAroundAxis(self:GetUp(),   self:GetAimYaw())
            aimAng:RotateAroundAxis(aimAng:Right(), self:GetAimPitch())
            local muzzlePos = self:GetPos()
                + aimAng:Forward() * boneLocalPos.x
                + aimAng:Right()   * boneLocalPos.y
                + aimAng:Up()      * boneLocalPos.z
            return muzzlePos, aimAng
        end
    end

    local aimAng = Angle(self:GetAngles())
    aimAng:RotateAroundAxis(self:GetUp(),   self:GetAimYaw())
    aimAng:RotateAroundAxis(aimAng:Right(), self:GetAimPitch())
    local muzzlePos = self:GetPos()
        + aimAng:Forward() * CONFIG.MUZZLE_FALLBACK.x
        + aimAng:Right()   * CONFIG.MUZZLE_FALLBACK.y
        + aimAng:Up()      * CONFIG.MUZZLE_FALLBACK.z
    return muzzlePos, aimAng
end

-- ============================================================
--  DAMAGE / DEATH
-- ============================================================
function ENT:OnTakeDamage(dmginfo)
    if self:GetState() == self.STATE_BROKEN then return end
    local newHP = self:GetHP() - dmginfo:GetDamage()
    self:SetHP(newHP)
    if newHP <= 0 then self:Break() end
end

function ENT:Break()
    self:SetState(self.STATE_BROKEN)
    self:StopRadarLoop()
    -- Kill any running burst timer cleanly
    timer.Remove("nsentry_burst_" .. self:EntIndex())
    self:EmitSound("npc/turret_floor/die.wav", 75, 100)
    local ed = EffectData()
    ed:SetOrigin(self:GetPos())
    ed:SetMagnitude(2)
    ed:SetScale(1)
    util.Effect("Explosion", ed)
    timer.Simple(1, function() if IsValid(self) then self:Remove() end end)
end

-- ============================================================
--  CLEANUP
-- ============================================================
function ENT:OnRemove()
    self:StopRadarLoop()
    timer.Remove("nsentry_burst_" .. self:EntIndex())
    self.HoldingPlayers = {}
    self.LastClickTime  = {}
end
