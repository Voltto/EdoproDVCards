--Protector of Swords, Gar-Einer
local s,id=GetID()
function s.initial_effect(c)
	-- E1: On Summon - Destroy & Revive
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	-- E2: Grant effects while attached to Blast Mode
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_XMATERIAL)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetCondition(s.matcon)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_XMATERIAL)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetTargetRange(0,1)
	e3:SetCondition(s.matcon2)
	e3:SetValue(s.aclimit)
	c:RegisterEffect(e3)

	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_XMATERIAL+EFFECT_TYPE_TRIGGER_F)
	e4:SetCode(EVENT_ATTACK_ANNOUNCE)
	e4:SetCondition(s.matcon3)
	e4:SetOperation(s.atkop)
	c:RegisterEffect(e4)
end

local BLAST_MODE_ID = 1832361656

-------------------------------------------------------
-- E1: On Summon: Destroy 1 card, then revive Blast Mode
-------------------------------------------------------
function s.filter1(c)
	return c:IsOnField()
end
function s.filter2(c,e,tp)
	return c:IsCode(BLAST_MODE_ID) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then
		return Duel.IsExistingTarget(s.filter1,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
			and Duel.IsExistingTarget(s.filter2,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectTarget(tp,s.filter1,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g2=Duel.SelectTarget(tp,s.filter2,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g2,1,0,0)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	local g1=tg:Filter(Card.IsLocation,nil,LOCATION_ONFIELD)
	local g2=tg:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
	local tc1=g1:GetFirst()
	local tc2=g2:GetFirst()
	if tc1 and Duel.Destroy(tc1,REASON_EFFECT)~=0 and tc2 and Duel.SpecialSummon(tc2,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- Attach this card as material
		local c=e:GetHandler()
		if c:IsRelateToEffect(e) and c:IsFaceup() and not tc2:IsImmuneToEffect(e) then
			Duel.BreakEffect()
			Duel.Overlay(tc2,Group.FromCards(c))
		end
	end
end

-------------------------------------------------------
-- E2: Grant effects while attached to Blast Mode
-------------------------------------------------------
-- • Cannot be destroyed by card effects
function s.matcon(e)
	local c=e:GetHandler():GetOwner()
	local rc=e:GetOwner():GetReasonCard()
	return rc and rc:IsCode(BLAST_MODE_ID)
end

-- • Opponent cannot activate cards/effects when this card attacks
function s.matcon2(e)
	local rc=e:GetOwner():GetReasonCard()
	return rc and rc:IsCode(BLAST_MODE_ID) and Duel.GetAttacker()==rc
end
function s.aclimit(e,re,tp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) or re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP)
end

-- • When this card attacks a monster: Gain 500 ATK per card in your hand
function s.matcon3(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetOwner():GetReasonCard()
	local at=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	return rc and rc==at and at:IsCode(BLAST_MODE_ID) and d and d:IsControler(1-tp)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetOwner():GetReasonCard()
	if not rc or not rc:IsFaceup() then return end
	local atk=Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)*500
	local e1=Effect.CreateEffect(rc)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(atk)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE)
	rc:RegisterEffect(e1)
end
