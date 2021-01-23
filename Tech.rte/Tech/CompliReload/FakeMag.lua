
function OnDetach(self, exParent)
	exParent:SetNumberValue("LostFakeMag", 1)
	self.ToDelete = true
end
