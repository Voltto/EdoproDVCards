--Dolch Gardra
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure
	Xyz.AddProcedure(c,nil,4,2)
	c:EnableReviveLimit()

	-- Main Effect (only active if Gar is material)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

-----------------------------
-- Condition: This card has a "Gar" monster as material
-----------------------------
function s.matfilter(c)
	return c:IsSetCard(0x219b) -- "Gar" SetCode
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetOverlayGroup():IsExists(s.matfilter,1,nil)
end

-----------------------------
-- Cost: Detach 1 material
-----------------------------
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

-----------------------------
-- Target: 1 "Gar" or "Laevateinn" monster in GY
-----------------------------
function s.thfilter(c)
	return c:IsSetCard(0x219b) or c:IsSetCard(0x219a) -- Gar or Laevateinn
end
function s.utzfilter(c,e,tp)
	return c:IsRank(4) and c:IsSetCard(0x107f) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,true,false)
end
function s.xyzgycheck(c)
	return c:IsType(TYPE_XYZ)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

-----------------------------
-- Operation
-----------------------------
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		if Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and Duel.IsExistingMatchingCard(s.xyzgycheck,tp,LOCATION_GRAVE,0,1,nil) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sc=Duel.SelectMatchingCard(tp,s.utzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
			if sc and Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,true,false,POS_FACEUP)>0 then
				sc:CompleteProcedure()
				-- Optional: attach 1 material from this card to Utopia
				if c:IsRelateToEffect(e) and #c:GetOverlayGroup()>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
					local ovg=c:GetOverlayGroup()
					Duel.HintSelection(Group.FromCards(sc))
					Duel.Overlay(sc,ovg:Select(tp,1,1,nil))
				end
			end
		end
	end
end
