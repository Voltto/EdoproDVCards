--Deity Dragon Tribe's Banquet
local s,id=GetID()
function s.initial_effect(c)
	-- This card is always treated as a "Gar" card
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetValue(0x3b25) -- Gar archetype setcode
	c:RegisterEffect(e0)

	-- Effect 1: Search Gar Spell/Trap, then put 1 hand card on bottom
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- Effect 2: GY effect - banish, revive 2 Gar monsters, then Xyz Summon Utopia
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.xyzcon)
	e2:SetCost(s.xyzcost)
	e2:SetTarget(s.xyztg)
	e2:SetOperation(s.xyzop)
	c:RegisterEffect(e2)
end

--------------------------------
-- Effect 1: Search & bottom deck
--------------------------------
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x219b) -- "Gar" monster
end
function s.thfilter(c)
	return c:IsSetCard(0x219b) and (c:IsSpell() or c:IsTrap()) and c:IsAbleToHand()
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
			and Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local hg=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_HAND,0,1,1,nil)
		if #hg>0 then
			Duel.SendtoDeck(hg,nil,SEQ_DECKBOTTOM,REASON_EFFECT)
		end
	end
end

--------------------------------
-- Effect 2: GY revive + Xyz Summon
--------------------------------
function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsSetCard(0x219a) end, tp, LOCATION_MZONE, 0, 1, nil) -- Laevateinn
end
function s.xyzcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return aux.bfgcost(e,tp,eg,ep,ev,re,r,rp,0) end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end
function s.revfilter(c,e,tp)
	return c:IsSetCard(0x219b) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.utopiafilter(c,mg,e,tp)
	return c:IsSetCard(0x107f) and c:IsType(TYPE_XYZ)
		and c:IsRank(4)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
		and c:IsXyzSummonable(nil,mg)
end
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.revfilter,tp,LOCATION_GRAVE,0,nil,e,tp)
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>=2 and #g>=2
			and Duel.IsExistingMatchingCard(s.utopiafilter,tp,LOCATION_EXTRA,0,1,nil,g,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_GRAVE)
end
function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.revfilter,tp,LOCATION_GRAVE,0,2,2,nil,e,tp)
	if #g<2 then return end
	for tc in aux.Next(g) do
		Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP)
	end
	Duel.SpecialSummonComplete()
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local xyz=Duel.SelectMatchingCard(tp,s.utopiafilter,tp,LOCATION_EXTRA,0,1,1,nil,g,e,tp):GetFirst()
	if xyz then
		Duel.XyzSummon(tp,xyz,nil,g)
	end
end
