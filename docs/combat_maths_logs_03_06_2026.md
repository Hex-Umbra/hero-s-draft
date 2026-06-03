=== COMBAT INITIALIZATION MATHEMATICS ===
Player Level: 1, Act: 1, Node Type: MapNodeType.combat
Player Max HP: 80, Attack: 0, Max Mana: 3, Relics Count: 0
PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) +
(relicsCount * 5)
PlayerPower calculation: 80 + (0 * 10) + (3 * 15) + (0 * 5) = 125
ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1)* 20]
ExpectedPower calculation: 145 + [(1 - 1) * 15] + [(1 - 1) * 20] = 145
BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]
BaseBudget calculation: 40 + [(1 - 1) * 10] + [(1 - 1) * 25] = 40
PowerRatio calculation: PlayerPower / ExpectedPower = 125 / 145 = 0.8620689655172413
PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5
PowerModifier calculation: 1.0 + (0.8620689655172413 - 1.0) * 0.5 = 0.9310344827586207
NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)
FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier
FinalBudget calculation: 40 * 0.9310344827586207 * 1 = 37.241379310344826
Enemy Level calculation: max(1, playerLevel + (act - 1) * 2 +
nodeModifier) = 1
HP scaling multiplier: 1
Damage scaling multiplier: 1
Generated Enemy Data count: 1
 - Enemy: Slime (Tier: 1), HP scaled: 18, Damage scaled: 4,
 CombatRating: 32.2
=========================================