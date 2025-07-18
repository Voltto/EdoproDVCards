--Harmonics Messiah
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Special Summon procedure from Extra Deck
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- LP becomes 2000 if 5+ different banished monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.lpcon)
	e2:SetOperation(s.lpop)
	c:RegisterEffect(e2)

	-- Mulligan effect (optional, once per duel per player)
	for p=0,1 do
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e3:SetCode(EVENT_PREDRAW)
		e3:SetCountLimit(1,id+p,EFFECT_COUNT_CODE_DUEL)
		e3:SetLabel(p)
		e3:SetCondition(s.mullcon)
		e3:SetOperation(s.mullop)
		Duel.RegisterEffect(e3,p)
	end

	-- If destroyed, move to Pendulum Zone
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCondition(s.pzcon)
	e4:SetTarget(s.pztg)
	e4:SetOperation(s.pzop)
	c:RegisterEffect(e4)
end

-- Custom Fusion-like summon from Extra Deck by banishing 5 monsters
function s.spfilter(c)
	return c:IsMonster() and c:IsAbleToRemoveAsCost()
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCountFromEx(tp,tp,c)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,5,nil)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,5,5,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

-- LP = 2000 if 5 or more different banished monsters
function s.lpcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end
function s.lpop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsMonster,tp,LOCATION_REMOVED,0,nil)
	local seen={}
	local count=0
	for tc in g:Iter() do
		local code=tc:GetCode()
		if not seen[code] then
			seen[code]=true
			count=count+1
		end
	end
	if count>=5 then
		Duel.SetLP(tp,2000)
	end
end

-- Mulligan effect (optional for each player)
function s.exreveal(c)
	return c:IsCode(id) and not c:IsPublic()
end
function s.mullcon(e,tp,eg,ep,ev,re,r,rp)
	local p=e:GetLabel()
	return Duel.GetTurnCount()==1 and Duel.GetDrawCount(p)>0
		and Duel.IsExistingMatchingCard(s.exreveal,p,LOCATION_EXTRA,0,1,nil)
end
function s.mullop(e,tp,eg,ep,ev,re,r,rp)
	local p=e:GetLabel()
	if Duel.SelectYesNo(p,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,p,aux.Stringid(id,0))
		local g=Duel.SelectMatchingCard(p,s.exreveal,p,LOCATION_EXTRA,0,1,1,nil)
		if #g>0 then
			Duel.ConfirmCards(1-p,g)
			Duel.Hint(HINT_SELECTMSG,p,HINTMSG_TODECK)
			local hand=Duel.GetFieldGroup(p,LOCATION_HAND,0)
			local tg=hand:Filter(Card.IsAbleToDeck,nil)
			if #tg>0 then
				local sg=tg:Select(p,0,#tg,nil)
				local ct=Duel.SendtoDeck(sg,nil,SEQ_DECKBOTTOM,REASON_EFFECT)
				if ct>0 then
					Duel.Draw(p,ct,REASON_EFFECT)
				end
			end
		end
	end
end

-- If destroyed, place in Pendulum Zone
function s.pzcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_MZONE)
end
function s.pztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1)
	end
end
function s.pzop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.CheckLocation(tp,LOCATION_PZONE,0) and not Duel.CheckLocation(tp,LOCATION_PZONE,1) then return end
	Duel.MoveToField(e:GetHandler(),tp,tp,LOCATION_PZONE,POS_FACEUP,true)
end
