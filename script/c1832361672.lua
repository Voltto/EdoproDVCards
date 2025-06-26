--Gargazelle
local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,s.matfilter,2,2)

	-- Effect 1: On Link Summon - shuffle & summon Xyz
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.spcon)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Effect 2: Protection if you control Laevateinn Dragon or it's attached
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_ONFIELD,0)
	e2:SetCondition(s.protcon)
	e2:SetTarget(s.prottg)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)
end

-- Link material: EARTH or "Gar" monsters
function s.matfilter(c,lc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_EARTH,lc,sumtype,tp) or c:IsSetCard(0x219b,lc,sumtype,tp)
end

------------------------------------
-- Effect 1: Link Summon Trigger
------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end
function s.tdfilter(c)
	return c:IsSetCard(0x219b) and c:IsAbleToDeck()
end
function s.xyzfilter(c,e,tp)
	return (c:IsSetCard(0x107f) or c:IsSetCard(0x219b)) and c:IsType(TYPE_XYZ)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end
function s.matfilter2(c)
	return c:IsAttribute(ATTRIBUTE_EARTH) and not c:IsImmuneToEffect()
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE,0,2,nil)
			and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
			and Duel.GetLocationCountFromEx(tp,tp,nil,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(Card.IsAttribute,tp,LOCATION_DECK,0,1,nil,ATTRIBUTE_EARTH)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,2,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp,tp,nil,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local tdg=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE,0,2,2,nil)
	if #tdg<2 then return end
	Duel.SendtoDeck(tdg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local xyz=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
	if not xyz then return end
	if Duel.SpecialSummon(xyz,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)~=0 then
		xyz:CompleteProcedure()
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local mat=Duel.SelectMatchingCard(tp,Card.IsAttribute,tp,LOCATION_DECK,0,1,1,nil,ATTRIBUTE_EARTH)
		if #mat>0 then
			Duel.Overlay(xyz,mat)
		end
	end
end

------------------------------------
-- Effect 2: Protection
------------------------------------
local LAEVATEINN_DRAGON_ID = 1832361655

function s.protcon(e)
	local tp=e:GetHandlerPlayer()
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	return g:IsExists(function(c)
		return c:IsCode(LAEVATEINN_DRAGON_ID)
			or (c:IsType(TYPE_XYZ) and c:GetOverlayGroup():IsExists(Card.IsCode,1,nil,LAEVATEINN_DRAGON_ID))
	end,1,nil)
end
function s.prottg(e,c)
	return c~=e:GetHandler()
end
