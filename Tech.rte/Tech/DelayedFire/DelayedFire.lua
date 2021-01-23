function Create(self)
	
	self.parentSet = false;
	
	self.delayedFire = false
	self.delayedFireTimer = Timer();
	self.delayedFireTimeMS = 50
	self.delayedFireEnabled = true
	
	self.lastAge = self.Age + 0
	
	self.fireDelayTimer = Timer()
	
	self.activated = false
	
	local ms = 1 / (self.RateOfFire / 60) * 1000
	ms = ms + self.delayedFireTimeMS
	self.RateOfFire = 1 / (ms / 1000) * 60
end
function Update(self)

	if not self.delayedFireDisabled == true then
	
		if self:NumberValueExists("DelayedFireTimeMS") then
			self.delayedFireTimeMS = self:GetNumberValue("DelayedFireTimeMS")
			self:RemoveNumberValue("DelayedFireTimeMS")
		end
		
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
		
		-- Check if switched weapons/hide in the inventory, etc.
		if self.Age > (self.lastAge + TimerMan.DeltaTimeSecs * 2000) then
			if self.delayedFire then
				self.delayedFire = false
			end
			self.fireDelayTimer:Reset()
		end
		self.lastAge = self.Age + 0
		
		if self:DoneReloading() or self:IsReloading() then
			self.fireDelayTimer:Reset()
		end

		if self.parent then
			local fire = self:IsActivated()
			self:Deactivate()
			
			--if self.parent:GetController():IsState(Controller.WEAPON_FIRE) and not self:IsReloading() then
			if fire and not self:IsReloading() then
				if not self.Magazine or self.Magazine.RoundCount < 1 then
					--self:Reload()
					self:Activate()
				elseif not self.activated and not self.delayedFire and (self.Chamber == nil or self.Chamber == false) and self.fireDelayTimer:IsPastSimMS(1 / (self.RateOfFire / 60) * 1000) then
					self.activated = true
					
					if self.preSound then
						self.preSound:Play(self.Pos);
					end
					
					self.fireDelayTimer:Reset()
					
					self.delayedFire = true
					self.delayedFireTimer:Reset()
				end
			else
				if self.activated then
					self.activated = false
				end
			end
		end
		
		if self.delayedFire and self.delayedFireTimer:IsPastSimMS(self.delayedFireTimeMS) then
			self:Activate()
			self.delayedFire = false
		end
	end
	
end