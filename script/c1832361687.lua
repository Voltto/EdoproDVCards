--Mischievous Zombie
local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunction(Card.IsRace,RACE_ZOMBIE),1,1)

-- Effect 1: On Link Summon, if DARK Zombie used → Activate Zombie World + lock
local e1=Effect.CreateEffect(c)
e1:SetDescription(aux.Stringid(id,0))
e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
e1:SetCode(EVENT_SPSUMMON_SUCCESS)
e1:SetProperty(EFFECT_FLAG_DELAY)
e1:SetCountLimit(1,id)
e1:SetCondition(s.zwcon)
e1:SetTarget(s.zwtg)
e1:SetOperation(s.zwop)
c:RegisterEffect(e1)


	-- Effect 2: Special Summon self from GY during Main Phase if Zombie Link/Fusion exists
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-----------------------------------------------------------
-- Effect 1: Link Summon → Activate "Zombie World"
-----------------------------------------------------------
function s.zwcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsSummonType(SUMMON_TYPE_LINK) then return false end
	-- Check if DARK Zombie was used as material
	local mat=c:GetMaterial()
	return mat and mat:IsExists(function(mc)
		return mc:IsRace(RACE_ZOMBIE) and mc:IsAttribute(ATTRIBUTE_DARK)
	end,1,nil)
end

function s.zwtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.zwfilter,tp,LOCATION_DECK,0,1,nil)
			and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
	end
end

function s.zwfilter(c)
	return c:IsCode(4064256) and c:IsAbleToHand() -- Zombie World
end

function s.zwop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Activate "Zombie World" from Deck
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2))
	local tc=Duel.SelectMatchingCard(tp,s.zwfilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
		Duel.BreakEffect()

		-- Apply Special Summon restriction: Only Zombies this turn
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,3)) -- Client hint
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.splimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

function s.splimit(e,c)
	return not c:IsRace(RACE_ZOMBIE)
end

-----------------------------------------------------------
-- Effect 2: Special Summon from GY during Main Phase if you control a Zombie Fusion/Link
-----------------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Not the same turn it was sent to the GY
	if c:GetTurnID() == Duel.GetTurnCount() then return false end
	if Duel.GetCurrentPhase()~=PHASE_MAIN1 and Duel.GetCurrentPhase()~=PHASE_MAIN2 then return false end
	return Duel.IsExistingMatchingCard(s.zomfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.zomfilter(c)
	return c:IsRace(RACE_ZOMBIE) and (c:IsType(TYPE_LINK) or c:IsType(TYPE_FUSION))
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end
