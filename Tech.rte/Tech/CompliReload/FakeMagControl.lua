function Create(self)

	self.fakeMag = nil;
	for attachable in self.Attachables do
		
		if string.find(attachable.PresetName, "Fake Magazine") then
			self.fakeMag = attachable
			self.fakeMag.InheritsRotAngle = false
			self.fakeMag:AddScript("Tech.rte/Tech/CompliReload/FakeMag.lua") -- SAFE MEASURE
		end
	end
end

function Update(self)
	
	if self.fakeMag and not self:NumberValueExists("LostFakeMag") then
		self.fakeMag:ClearForces();
		self.fakeMag:ClearImpulseForces();
		
		self.fakeMag:RemoveWounds(self.fakeMag.WoundCount);
		
		self.fakeMag.GetsHitByMOs = false;
			
		if self:NumberValueExists("MagRemoved") then
			self.fakeMag.Frame = 0;
		else
			self.fakeMag.Frame = 1;
		end
		if self:NumberValueExists("MagRotation") then
			self.fakeMag.RotAngle = self.RotAngle + self:GetNumberValue("MagRotation");
		end
		if self:NumberValueExists("MagOffsetX") and self:NumberValueExists("MagOffsetY") then
			self.fakeMag.Pos = self.fakeMag.Pos + Vector(self:GetNumberValue("MagOffsetX"), self:GetNumberValue("MagOffsetY"));
		end
	end
	
end



