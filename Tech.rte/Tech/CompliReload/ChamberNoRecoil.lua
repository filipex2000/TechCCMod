function Create(self)
	self.parentSet = false;
	self.Module = "Tech.rte"
	self.Preset = "CompliReload Example"
	
	
	self.magOutSound = CreateSoundContainer("MagOut "..self.Preset, self.Module);
	
	self.magOutPrepareSound = CreateSoundContainer("MagOutPrepare "..self.Preset, self.Module);
	
	
	self.magInSound = CreateSoundContainer("MagIn "..self.Preset, self.Module);
	
	self.magInPrepareSound = CreateSoundContainer("MagInPrepare "..self.Preset, self.Module);
	
	
	self.magHitSound = CreateSoundContainer("MagHit "..self.Preset, self.Module);
	
	self.boltReleaseSound = CreateSoundContainer("BoltRelease "..self.Preset, self.Module);
	
	
	self.originalStanceOffset = Vector(math.abs(self.StanceOffset.X), self.StanceOffset.Y)
	self.originalSharpStanceOffset = Vector(self.SharpStanceOffset.X, self.SharpStanceOffset.Y)
	
	self.rotation = 0
	self.rotationTarget = 0
	self.rotationSpeed = 5
	
	self.horizontalAnim = 0
	self.verticalAnim = 0
	
	self.angVel = 0
	self.lastRotAngle = self.RotAngle
	
	self.reloadTimer = Timer();
	
	self.magOutPrepareDelay = 450;
	self.magOutAfterDelay = 500;
	self.magInPrepareDelay = 950;
	self.magInAfterDelay = 200;
	self.magHitPrepareDelay = 400;
	self.magHitAfterDelay = 500;
	self.boltForwardPrepareDelay = 700;
	self.boltForwardAfterDelay = 400;
	
	-- phases:
	-- 0 magout
	-- 1 magin
	-- 2 maghit
	-- 3 boltforward
	
	self.reloadPhase = 0;
	
	self.ReloadTime = 9999;

	local actor = MovableMan:GetMOFromID(self.RootID);
	if actor and IsAHuman(actor) then
		self.parent = ToAHuman(actor);
	end
	
	self.fakeMagazineMOSRotating = "Fake Magazine MOSRotating "..self.Preset -- nil for no magazine mosrotating
	self.fakeMagazineMOSRotatingOffset = Vector(0, 2)
	self.fakeMagazineMOSRotatingVelocity = Vector(0.5, 3)
	
end

function Update(self)

	if self.ID == self.RootID then
		self.parent = nil;
		self.parentSet = false;
	elseif self.parentSet == false then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if actor and IsAHuman(actor) then
			self.parent = ToAHuman(actor);
			self.parentSet = true;
		end
	end
	
    -- Smoothing
    local min_value = -math.pi;
    local max_value = math.pi;
    local value = self.RotAngle - self.lastRotAngle
    local result;
    local ret = 0
    
    local range = max_value - min_value;
    if range <= 0 then
        result = min_value;
    else
        ret = (value - min_value) % range;
        if ret < 0 then ret = ret + range end
        result = ret + min_value;
    end
    
    self.lastRotAngle = self.RotAngle
    self.angVel = (result / TimerMan.DeltaTimeSecs) * self.FlipFactor
    
    if self.lastHFlipped ~= nil then
        if self.lastHFlipped ~= self.HFlipped then
            self.lastHFlipped = self.HFlipped
            self.angVel = 0
        end
    else
        self.lastHFlipped = self.HFlipped
    end
	--PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(-20, 20), "Angular Velocity = "..self.angVel, true, 0);
	--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + Vector(15 * self.FlipFactor,0):RadRotate(self.RotAngle),  13);
	--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + Vector(15 * self.FlipFactor,0):RadRotate(self.RotAngle + (self.angVel * 0.05)),  5);
	
	if self:IsReloading() then
		if self.parent then
			self.parent:GetController():SetState(Controller.AIM_SHARP,false);
		end
	
		if self.reloadPhase == 0 then
			self.reloadDelay = self.magOutPrepareDelay;
			self.afterDelay = self.magOutAfterDelay;
			
			self.prepareSound = self.magOutPrepareSound
			self.afterSound = self.magOutSound
			
			self.rotationTarget = -5 * self.reloadTimer.ElapsedSimTimeMS / (self.reloadDelay + self.afterDelay)
			
		elseif self.reloadPhase == 1 then
			self.reloadDelay = self.magInPrepareDelay;
			self.afterDelay = self.magInAfterDelay;
			
			self.prepareSound = self.magInPrepareSound
			self.afterSound = self.magInSound
			
			self.rotationTarget = 15-- * self.reloadTimer.ElapsedSimTimeMS / (self.reloadDelay + self.afterDelay)
			
		elseif self.reloadPhase == 2 then
			self.reloadDelay = self.magHitPrepareDelay;
			self.afterDelay = self.magHitAfterDelay;
			
			self.prepareSound = nil;
			self.afterSound = self.magHitSound
			
			self.rotationTarget = 5-- * self.reloadTimer.ElapsedSimTimeMS / (self.reloadDelay + self.afterDelay)
			
		elseif self.reloadPhase == 3 then
			self.Frame = 3;
			self.reloadDelay = self.boltForwardPrepareDelay;
			self.afterDelay = self.boltForwardAfterDelay;
			
			self.prepareSound = nil;
			self.afterSound = self.boltReleaseSound
			
			self.rotationTarget = -4-- * self.reloadTimer.ElapsedSimTimeMS / (self.reloadDelay + self.afterDelay)
		end
		
		if self.prepareSoundPlayed ~= true then
			self.prepareSoundPlayed = true;
			if self.prepareSound then
				self.prepareSound:Play(self.Pos)
			end
		end
	
		if self.reloadTimer:IsPastSimMS(self.reloadDelay) then
		
			if self.reloadPhase == 0 then
				self:SetNumberValue("MagRemoved", 1);
			elseif self.reloadPhase == 1 then
				self:RemoveNumberValue("MagRemoved");
			elseif self.reloadPhase == 3 then
				if self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*1)) then
					self.Frame = 0;
				elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.75)) then
					self.Frame = 1;
				elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.5)) then
					self.Frame = 2;
				end
			end
			
			if self.afterSoundPlayed ~= true then
			
				if self.reloadPhase == 0 then
					self.phaseOnStop = 1;
					if self.fakeMagazineMOSRotating then
						local fake
						fake = CreateMOSRotating(self.fakeMagazineMOSRotating, self.Module);
						fake.Pos = self.Pos + Vector(self.fakeMagazineMOSRotatingOffset.X * self.FlipFactor, self.fakeMagazineMOSRotatingOffset.Y):RadRotate(self.RotAngle);
						fake.Vel = self.Vel + Vector(self.fakeMagazineMOSRotatingVelocity.X *self.FlipFactor, self.fakeMagazineMOSRotatingVelocity.Y):RadRotate(self.RotAngle);
						fake.RotAngle = self.RotAngle;
						fake.AngularVel = self.AngularVel + (-1*self.FlipFactor);
						fake.HFlipped = self.HFlipped;
						MovableMan:AddParticle(fake);
					end
					
					self.verticalAnim = self.verticalAnim + 1
				elseif self.reloadPhase == 1 then

					self:RemoveNumberValue("MagRemoved");
					
					self.verticalAnim = self.verticalAnim - 0.3
				elseif self.reloadPhase == 2 then		
					if self.chamberOnReload then
						self.phaseOnStop = 3;
					else
						self.ReloadTime = 0; -- done! no after delay if non-chambering reload.
						self.reloadPhase = 0;
						self.phaseOnStop = nil;
					end				
					self.verticalAnim = self.verticalAnim - 1				
					self.phaseOnStop = nil;				
				elseif self.reloadPhase == 3 then				
					self.angVel = self.angVel - 10;
					self.phaseOnStop = nil;
				else
					self.phaseOnStop = nil;
				end
			
				self.afterSoundPlayed = true;
				if self.afterSound then
					self.afterSound:Play(self.Pos)
				end
			end
			if self.reloadTimer:IsPastSimMS(self.reloadDelay + self.afterDelay) then
				self.reloadTimer:Reset();
				self.prepareSoundPlayed = false;
				self.afterSoundPlayed = false;
				if self.chamberOnReload and self.reloadPhase == 2 then
					self.reloadPhase = self.reloadPhase + 1;
				elseif self.reloadPhase == 2 or self.reloadPhase == 3 then
					self.ReloadTime = 0;
					self.reloadPhase = 0;
				else
					self.reloadPhase = self.reloadPhase + 1;
				end
			end
		end
	else
		self.rotationTarget = 0
		
		if self.chamberOnReload then
			self.Frame = 3;
		else
			self.Frame = 0;
		end
		self.reloadTimer:Reset();
		self.prepareSoundPlayed = false;
		self.afterSoundPlayed = false;
		if self.reloadPhase == 3 then
			self.reloadPhase = 2;
		end
		if self.phaseOnStop then
			self.reloadPhase = self.phaseOnStop;
			self.phaseOnStop = nil;
		end
		self.ReloadTime = 9999;
	end
	
	if self:DoneReloading() == true and self.chamberOnReload then
		self.Magazine.RoundCount = 30;
		self.chamberOnReload = false;
	elseif self:DoneReloading() then
		self.Magazine.RoundCount = 31;
		self.chamberOnReload = false;
	end
	
	if self.FiredFrame then	
		
		self.horizontalAnim = self.horizontalAnim + 0.2
		self.angVel = self.angVel + RangeRand(0,1) * 3
		self.Frame = 3;
		
		if self.Magazine then
			if self.Magazine.RoundCount > 0 then			
			else
				self.chamberOnReload = true;
			end
		end
		
	end
	
	if not self:IsActivated() then
		self.firstShot = true;
	end	
	
	-- Animation
	if self.parent then
		self.horizontalAnim = math.floor(self.horizontalAnim / (1 + TimerMan.DeltaTimeSecs * 12.0) * 1000) / 1000
		self.verticalAnim = math.floor(self.verticalAnim / (1 + TimerMan.DeltaTimeSecs * 8.0) * 1000) / 1000
		
		local stance = Vector()
		stance = stance + Vector(-5,0) * self.horizontalAnim -- Horizontal animation
		stance = stance + Vector(0,6) * self.verticalAnim -- Vertical animation
		
		self.rotationTarget = self.rotationTarget + (self.angVel * 3)
		
		self.rotation = (self.rotation + self.rotationTarget * TimerMan.DeltaTimeSecs * self.rotationSpeed) / (1 + TimerMan.DeltaTimeSecs * self.rotationSpeed)
		local total = math.rad(self.rotation) * self.FlipFactor
		
		self.RotAngle = self.RotAngle + total;
		self:SetNumberValue("MagRotation", total);
		
		local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
		local offsetTotal = Vector(jointOffset.X, jointOffset.Y):RadRotate(-total) - jointOffset
		self.Pos = self.Pos + offsetTotal;
		self:SetNumberValue("MagOffsetX", offsetTotal.X);
		self:SetNumberValue("MagOffsetY", offsetTotal.Y);
		
		self.StanceOffset = Vector(self.originalStanceOffset.X, self.originalStanceOffset.Y) + stance
		self.SharpStanceOffset = Vector(self.originalSharpStanceOffset.X, self.originalSharpStanceOffset.Y) + stance
	end
	
end