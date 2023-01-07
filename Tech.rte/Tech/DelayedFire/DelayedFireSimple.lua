function Create(self)
	self.preFireTimer = Timer()
	self.preFire = false
	self.preFireFired = false
	self.preFireActive = false
end
function Update(self)
	
	if self:IsReloading() then
		-- Just in case!
		self.preFireFired = false
		self.preFire = false
		
	end
	
	-- Prefire
	if self.soundFirePre and self.preDelay > 0 then
		local active = self:IsActivated()
		if active or self.preFire then
			if not self.preFireActive then
				if self.preSound then
					self.preSound:Play(self.Pos);
				end
				self.preFire = true
				self.preFireActive = true
			end
			
			if self.preFireTimer:IsPastSimMS(self.preDelay) then
				if self.FiredFrame then
					self.preFireFired = false
					self.preFire = false
				elseif not self.preFireFired then
					self:Activate()
				end
				
			else
				self:Deactivate()
			end
		else
			self.preFireActive = active
			self.preFireTimer:Reset()
		end
	end
end

function OnDetach(self)
	self.preFireFired = false
	self.preFire = false
end