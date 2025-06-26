--Gar-Break
local s,id=GetID()
function s.initial_effect(c)
	-- Activation
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

local LAEVATEINN_DRAGON_ID = 1832361655

-- Target 1 face-up Laevateinn Dragon you control
function s.filter(c)
	return c:IsFaceup() and c:IsCode(LAEVATEINN_DRAGON_ID)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end

	-- Gain 1500 ATK
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(1500)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)

	-- Add client hint (hover text)
	local e_hint=Effect.CreateEffect(e:GetHandler())
	e_hint:SetType(EFFECT_TYPE_SINGLE)
	e_hint:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e_hint:SetDescription(aux.Stringid(id,0)) -- Will be defined below
	e_hint:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e_hint)

	-- Opponent cannot activate cards/effects when it attacks
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(0,1)
	e2:SetValue(s.aclimit)
	e2:SetCondition(s.chaincon)
	e2:SetLabelObject(tc)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)

	-- If it attacks a face-down monster, destroy it, cancel the attack, and allow another
	local e3=Effect.CreateEffect(e:GetHandler())
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetCondition(s.fdcon)
	e3:SetOperation(s.fdop)
	e3:SetLabelObject(tc)
	e3:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e3,tp)
end

-- Prevent opponent from activating cards/effects when the targeted monster attacks
function s.aclimit(e,re,tp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) or re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP)
end
function s.chaincon(e)
	local c=e:GetLabelObject()
	local a=Duel.GetAttacker()
	return a and a==c
end

-- If the monster attacks a face-down, trigger the special effect
function s.fdcon(e,tp,eg,ep,ev,re,r,rp)
	local atker=Duel.GetAttacker()
	local target=Duel.GetAttackTarget()
	local c=e:GetLabelObject()
	return atker and target and atker==c and target:IsFacedown() and target:IsRelateToBattle()
end

function s.fdop(e,tp,eg,ep,ev,re,r,rp)
	local atker=Duel.GetAttacker()
	local target=Duel.GetAttackTarget()
	if not (atker and target and target:IsFacedown() and target:IsRelateToBattle()) then return end

	-- Destroy face-down monster by effect
	if Duel.Destroy(target,REASON_EFFECT)~=0 then
		-- Cancel battle
		Duel.NegateAttack()

		-- Grant 1 more attack
		if atker:IsFaceup() and atker:IsRelateToBattle() and atker:IsControler(tp) then
			Duel.BreakEffect()
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EXTRA_ATTACK)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			atker:RegisterEffect(e1)
		end
	end
end

-- Client hint description text
function s.stringid() return aux.Stringid(id,0) end
