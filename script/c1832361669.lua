--Mout Gardra
local s,id=GetID()
function s.initial_effect(c)
	-- Effect: On Normal Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
end

-- Filter for "Laevateinn" Xyz in Extra Deck
function s.revealfilter(c)
	return c:IsSetCard(0x219a) and c:IsType(TYPE_XYZ) and not c:IsPublic()
end

-- Filter for "Gar" monster to add
function s.garfilter(c)
	return c:IsSetCard(0x219b) and c:IsMonster() and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.revealfilter,tp,LOCATION_EXTRA,0,1,nil)
			and Duel.IsExistingMatchingCard(s.garfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- Reveal 1 Laevateinn Xyz monster from Extra Deck
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local reveal=Duel.SelectMatchingCard(tp,s.revealfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if #reveal>0 then
		Duel.ConfirmCards(1-tp,reveal)

		-- Add 1 Gar monster from Deck to hand
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.garfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			local tc=g:GetFirst()
			if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_HAND) then
				Duel.ConfirmCards(1-tp,tc)

				-- Change this card's level to match the added card's level
				local lv=tc:GetLevel()
				if lv>0 and e:GetHandler():IsFaceup() and e:GetHandler():IsRelateToEffect(e) then
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_CHANGE_LEVEL)
					e1:SetValue(lv)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
					e:GetHandler():RegisterEffect(e1)
				end

				-- Grant additional Normal Summon for Level 4 or lower monster
				local e2=Effect.CreateEffect(e:GetHandler())
				e2:SetDescription(aux.Stringid(id,1))
				e2:SetType(EFFECT_TYPE_FIELD)
				e2:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
				e2:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
				e2:SetTarget(function(_,c) return c:IsLevelBelow(4) end)
				e2:SetReset(RESET_PHASE+PHASE_END)
				Duel.RegisterEffect(e2,tp)
			end
		end
	end
end
