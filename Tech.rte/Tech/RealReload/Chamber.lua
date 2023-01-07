function Create(self)
	self.module = "Tech.rte"
	self.preset = "RealReload Example"
	
	function self:MagazineIn()
		if self.fakeMagazine then return end
		
		local magazineMO = CreateAttachable(self.fakeMagazinePreset, self.module);
		self:AddAttachable(magazineMO);
		self.fakeMagazine = magazineMO
	end
	
	function self:MagazineOut()
		if not self.fakeMagazine then return end
		
		if self.fakeMagazine then
			
			self:RemoveAttachable(self.fakeMagazine, true, false)
			self.fakeMagazine.Vel = self.Vel + Vector(1 * self.FlipFactor, 2):RadRotate(self.RotAngle)
			self.fakeMagazine.AngularVel = 1 * self.FlipFactor
			self.fakeMagazine = nil
		end
	end
	
	self.parent = nil
	
	local parent = self:GetRootParent()
	if parent and IsActor(parent) then
		parent = ToActor(parent)
		if IsAHuman(parent) then
			parent = ToAHuman(parent)
		elseif IsACrab(parent) then
			parent = ToACrab(parent)
		end
		
		self.parent = parent
	end
	
	self.roundCountMax = self.Magazine.RoundCount
	
	self.soundMagOut = CreateSoundContainer("Mag Out "..self.preset, self.module);
	self.soundMagIn = CreateSoundContainer("Mag In "..self.preset, self.module);
	self.soundChamber = CreateSoundContainer("Chamber "..self.preset, self.module);
	
	self.soundActiveReload = CreateSoundContainer("Active Reload "..self.preset, self.module);
	self.soundActiveReloadBegin = CreateSoundContainer("Active Reload Begin "..self.preset, self.module);
	self.soundActiveReloadEnd = CreateSoundContainer("Active Reload End "..self.preset, self.module);
	
	self.fakeMagazinePreset = "Fake Magazine "..self.preset
	self.fakeMagazine = nil
	
	self.reloading = false
	
	self:MagazineIn()
	
	self.reloadTimer = Timer()
	self.reloadStage = 0
	self.reloadStageEndNormal = 2
	self.reloadStageEndChamber = 3
	self.reloadStageEnd = self.reloadStageEndNormal
	self.reloadStageStart = true
	self.reloadTimes = {900, 1500, 950}
	self.reloadActiveSound = 0
	self.reloadActiveState = 1
	self.reloadActivePos = {0.5, 0.7, 0.8}
	self.reloadActiveSize = {0.2, 0.25, 0.4}
	self.reloadSounds = {self.soundMagOut, self.soundMagIn, self.soundChamber}
	self.reloadStageNames = {"Magazine Out", "Magazine In", "Chamber Round"}
	self.reloadLogicStart = {
		function ()
		end,
		function ()
		end,
		function ()
		end
	}
	self.reloadLogicUpdate = {
		function ()
		end,
		function ()
		end,
		function ()
		end
	}
	self.reloadLogicDetach = {
		function ()
		end,
		function ()
		end,
		function ()
		end
	}
	self.reloadLogicEnd = {
		function ()
			self:MagazineOut()
		end,
		function ()
			self:MagazineIn()
		end,
		function ()
		end
	}
end

function OnAttach(self)
	local parent = self:GetRootParent()
	if parent and IsActor(parent) then
		parent = ToActor(parent)
		if IsAHuman(parent) then
			parent = ToAHuman(parent)
		elseif IsACrab(parent) then
			parent = ToACrab(parent)
		end
		
		self.parent = parent
	end
	
	self.reloadTimer:Reset()
end

function OnDetach(self)
	self.parent = nil
	
	self.reloadActiveState = 1
	self.reloadActiveSound = 0
	
	self.reloadTimer:Reset()
	
	-- Call the detach logic
	if self.reloadStage > 0 and self.reloadLogicDetach and self.reloadLogicDetach[self.reloadStage] then self.reloadLogicDetach[self.reloadStage]() end
end

function Update(self)
	
	if not self.parent then return end
	
	if self.Magazine then
		if self.roundCount == nil then
			self.Magazine.RoundCount = self.Magazine.RoundCount - 1
		end
		self.roundCount = self.Magazine.RoundCount
	end
	
	if self:IsReloading() then
		if self.roundCount ~= nil then
			if self.roundCount < 1 then
				self.reloadStageEnd = self.reloadStageEndChamber
				self.roundCount = nil
			else
				self.reloadStageEnd = self.reloadStageEndNormal
			end
		end
		
		-- Initiate reload!
		if not self.reloading then
			self.reloadTimer:Reset()
			self.reloading = true
		end
		
		if self.reloadStage < 1 then
			self.reloadStage = 1
			self.reloadActiveState = 1
			self.reloadActiveSound = 0
			self.ReloadTime = 999999999
			self.reloadStageStart = true
			self.reloadTimer:Reset()
		end
		
		-- Get the stage index
		local stage = math.min(self.reloadStage, self.reloadStageEnd)
		
		
		-- Call the start logic, once!
		if self.reloadStageStart then
			self.reloadStageStart = false
			self.reloadLogicStart[stage]()
			
			--print(self.reloadStageNames[stage] .. " start")
		end
		
		-- Call the update logic
		self.reloadLogicUpdate[stage]()
		
		-- Calculate time, factors, etc based on current maximum time to stage end
		local timeMax = self.reloadTimes[stage]
		local timeCurrent = self.reloadTimer.ElapsedSimTimeMS
		local timeFactor = math.min(timeCurrent / timeMax, 1.0)
		
		-- Active reload
		local activeReloadPos = self.reloadActivePos[stage]
		local activeReloadSize = self.reloadActiveSize[stage]
		if activeReloadPos > 0 and activeReloadSize > 0 then
			if self.reloadActiveState == 1 then
				local ctrl = self.parent:GetController()
				local input = (ctrl and (ctrl:IsState(Controller.WEAPON_RELOAD)) or false)
				if timeFactor >= (activeReloadPos - activeReloadSize * 0.5) and timeFactor <= (activeReloadPos + activeReloadSize * 0.5) then
					if input then
						self.reloadActiveState = 2
						self.soundActiveReload:Play(self.Pos)
					end
					if self.reloadActiveSound == 0 then
						self.reloadActiveSound = 1
						self.soundActiveReloadBegin:Play(self.Pos)
					end
				else
					if input then
						self.reloadActiveState = 0
						self.soundActiveReloadEnd.Volume = 2.0
						self.soundActiveReloadEnd:Play(self.Pos)
					end
					
					if (self.reloadActiveSound < 2 and input) or self.reloadActiveSound == 1 then
						self.reloadActiveSound = 2
						self.reloadActiveState = 0
						self.soundActiveReloadEnd.Volume = 1.2
						self.soundActiveReloadEnd:Play(self.Pos)
					end
				end
				
			end
		end
		
		--- Debug / HUD
		PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(0, -36), self.reloadStageNames[stage], false, 1);
		
		
		local barPos = Vector(math.floor(self.parent.Pos.X), math.floor(self.parent.Pos.Y)) + Vector(-18 * self.FlipFactor, -3)
		local barWidth = 4
		local barHeight = 28
		local barWay = ((stage % 2) - 0.5) * 2
		
		local colorFG = 50
		local colorBG = (self.reloadActiveState == 2 and colorFG or 20)
		
		if self.reloadActiveState == 0 then
			colorFG = 47
		end
		
		-- BG
		PrimitiveMan:DrawBoxFillPrimitive(barPos + Vector(barWidth * -0.5, barHeight * -0.5), barPos + Vector(barWidth * 0.5, barHeight * 0.5), colorBG)
		-- FG
		PrimitiveMan:DrawBoxFillPrimitive(barPos + Vector(barWidth * -0.5, barHeight * -0.5 * barWay), barPos + Vector(barWidth * 0.5, (barHeight * -0.5 + barHeight * timeFactor) * barWay), colorFG)
		-- Active reload thingie!
		if activeReloadPos > 0 and activeReloadSize > 0 and self.reloadActiveState == 1 then
			local color = 116
			if timeFactor >= (activeReloadPos - activeReloadSize * 0.5) and timeFactor <= (activeReloadPos + activeReloadSize * 0.5) then
				color = 122
			end
			
			local yPos = (barHeight * -0.5 + barHeight * activeReloadPos) * barWay
			local ySize = activeReloadSize * barHeight * 0.5
			PrimitiveMan:DrawBoxFillPrimitive(barPos + Vector(barWidth * -0.5, yPos - ySize), barPos + Vector(barWidth * 0.5, yPos + ySize), color)
		end
		
		-- Outline
		--PrimitiveMan:DrawBoxPrimitive(barPos + Vector(barWidth * -0.5, barHeight * -0.5), barPos + Vector(barWidth * 0.5, barHeight * 0.5), colorFG)
		
		if self.reloadActiveState == 2 then
			PrimitiveMan:DrawBoxFillPrimitive(barPos + Vector(barWidth * -0.5, barHeight * -0.5), barPos + Vector(barWidth * 0.5, barHeight * 0.5), 223)
		end
		
		--PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(-healthbarWidth * 0.5, -healthbarHeight * 0.5), pos + Vector(healthbarWidth * 0.5, healthbarHeight * 0.5), colorBackground)
		--PrimitiveMan:DrawBoxPrimitive(pos + Vector(-healthbarWidth * 0.5, -healthbarHeight * 0.5), pos + Vector(healthbarWidth * 0.5, healthbarHeight * 0.5), colorOutlineBackground)
		---
		
		-- Stage end
		if self.reloadTimer:IsPastSimMS(timeMax) or self.reloadActiveState == 2 then
			local sound = self.reloadSounds[stage]
			if sound then
				sound:Play(self.Pos)
			end
			
			--print(self.reloadStageNames[stage] .. " end")
			self.reloadLogicEnd[stage]()
			
			self.reloadStage = self.reloadStage + 1
			self.reloadStageStart = true
			
			self.reloadTimer:Reset()
			
			self.reloadActiveState = 1
			self.reloadActiveSound = 0
			
			if self.reloadStage > self.reloadStageEnd then
				self.ReloadTime = 0
				self.reloadStage = 0
				--print("reload done")
			end
		end
		
	else
		self.reloading = false
		
		-- Ammo bar
		if self.Magazine then
			local barPos = Vector(math.floor(self.parent.Pos.X), math.floor(self.parent.Pos.Y)) + Vector(-18 * self.FlipFactor, -3)
			local barWidth = 4
			local barHeight = 28
			
			local max = 8
			local segmentsProper = math.min(self.roundCountMax, max)
			local segments = self.roundCountMax
			local factorM = 1
			if segments > segmentsProper then
				factorM = (segments - segmentsProper) / max
			end
			
			segments = math.floor(segments / factorM)
			
			PrimitiveMan:DrawBoxPrimitive(barPos + Vector(barWidth * -0.5, barHeight * -0.5), barPos + Vector(barWidth * 0.5, barHeight * 0.5), 50)
			
			for segment = 1, segments do
				if segment <= self.Magazine.RoundCount / factorM then
					local factorA = (segment - 1) / (segments)
					local factorB = segment / (segments)
					PrimitiveMan:DrawBoxFillPrimitive(barPos + Vector(barWidth * -0.5, barHeight * -0.5 + math.floor(barHeight * factorA)), barPos + Vector(barWidth * 0.5,  barHeight * -0.5 + math.floor(barHeight * factorB)), (segment % 2 == 0 and 53 or 50))
				end
			end
		else
			local barPos = Vector(math.floor(self.parent.Pos.X), math.floor(self.parent.Pos.Y)) + Vector(-18 * self.FlipFactor, -3)
			local barWidth = 4
			local barHeight = 28
			PrimitiveMan:DrawBoxPrimitive(barPos + Vector(barWidth * -0.5, barHeight * -0.5), barPos + Vector(barWidth * 0.5, barHeight * 0.5), 47)
		end
	end
end