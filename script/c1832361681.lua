--Mordecai the Duelist
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Fusion materials: 2 DARK Zombie monsters
	Fusion.AddProcMixRep(c,true,true,s.matfilter,2,2)

	-- Effect 1: Your Zombie monsters cannot be destroyed by card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.efilter)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Effect 2: Gains 100 ATK per Zombie in both GYs
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	-- Effect 3: After this card battles, revive Level 5+ Zombie from your GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLED)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- Fusion material must be DARK + Zombie
function s.matfilter(c,fc,sub,mg,sg,chkf)
	return c:IsRace(RACE_ZOMBIE) and c:IsAttribute(ATTRIBUTE_DARK)
end

-----------------------------------------------------------
-- Effect 1: Indestructible Zombie monsters
-----------------------------------------------------------
function s.efilter(e,c)
	return c:IsRace(RACE_ZOMBIE)
end

-----------------------------------------------------------
-- Effect 2: Gains 100 ATK per Zombie in both GYs
-----------------------------------------------------------
function s.atkval(e,c)
	local g1=Duel.GetMatchingGroup(Card.IsRace,c:GetControler(),LOCATION_GRAVE,LOCATION_GRAVE,nil,RACE_ZOMBIE)
	return #g1*100
end

-----------------------------------------------------------
-- Effect 3: After Battle - revive Level 5+ Zombie from GY
-----------------------------------------------------------
function s.spfilter(c,e,tp)
	return c:IsRace(RACE_ZOMBIE) and c:IsLevelAbove(5)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end
