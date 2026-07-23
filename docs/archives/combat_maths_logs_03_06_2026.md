┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 1    Act: 1    Node Type: combat                                  │
│   • Max HP: 100  Attack: 0    Max Mana: 3    Relics: 0                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (0 * 10) + (3 * 15) + (0 * 5) = 145                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(1 - 1) * 15] + [(1 - 1) * 20] = 145                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(1 - 1) * 10] + [(1 - 1) * 25] = 40                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     145 / 145 = 1                                                            │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (1 - 1.0) * 0.5 = 1                                                │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     40 * 1 * 1 = 40                                                          │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 1      │
│   • HP scaling multiplier: 1                                                 │
│   • Damage scaling multiplier: 1                                             │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Slime (Tier: 1), HP: 18, Dmg: 4, CR: 32.2                         │
└──────

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 1    Act: 1    Node Type: elite                                   │
│   • Max HP: 100  Attack: 0    Max Mana: 3    Relics: 0                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (0 * 10) + (3 * 15) + (0 * 5) = 145                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(1 - 1) * 15] + [(1 - 1) * 20] = 145                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(1 - 1) * 10] + [(1 - 1) * 25] = 40                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     145 / 145 = 1                                                            │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (1 - 1.0) * 0.5 = 1                                                │
│   • NodeMultiplier: 1.5 (Boss = 2.0, Elite = 1.5, Normal = 1.0)              │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     40 * 1 * 1.5 = 60                                                        │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 2      │
│   • HP scaling multiplier: 1.59                                              │
│   • Damage scaling multiplier: 1.56                                          │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Slime (Tier: 1), HP: 29, Dmg: 6, CR: 45.3                         │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 1    Act: 1    Node Type: combat                                  │
│   • Max HP: 100  Attack: 0    Max Mana: 3    Relics: 1                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (0 * 10) + (3 * 15) + (1 * 5) = 150                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(1 - 1) * 15] + [(1 - 1) * 20] = 145                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(1 - 1) * 10] + [(1 - 1) * 25] = 40                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     150 / 145 = 1.0344827586206897                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (1.0344827586206897 - 1.0) * 0.5 = 1.0172413793103448              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     40 * 1.0172413793103448 * 1 = 40.689655172413794                         │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 1      │
│   • HP scaling multiplier: 1                                                 │
│   • Damage scaling multiplier: 1                                             │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Slime (Tier: 1), HP: 18, Dmg: 4, CR: 32.2                         │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 1    Act: 1    Node Type: combat                                  │
│   • Max HP: 100  Attack: 0    Max Mana: 3    Relics: 1                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (0 * 10) + (3 * 15) + (1 * 5) = 150                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(1 - 1) * 15] + [(1 - 1) * 20] = 145                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(1 - 1) * 10] + [(1 - 1) * 25] = 40                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     150 / 145 = 1.0344827586206897                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (1.0344827586206897 - 1.0) * 0.5 = 1.0172413793103448              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     40 * 1.0172413793103448 * 1 = 40.689655172413794                         │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 1      │
│   • HP scaling multiplier: 1                                                 │
│   • Damage scaling multiplier: 1                                             │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Slime (Tier: 1), HP: 18, Dmg: 4, CR: 32.2                         │

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 2    Act: 1    Node Type: combat                                  │
│   • Max HP: 100  Attack: 0    Max Mana: 3    Relics: 1                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (0 * 10) + (3 * 15) + (1 * 5) = 150                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(2 - 1) * 15] + [(1 - 1) * 20] = 160                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(2 - 1) * 10] + [(1 - 1) * 25] = 50                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     150 / 160 = 0.9375                                                       │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.9375 - 1.0) * 0.5 = 0.96875                                     │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     50 * 0.96875 * 1 = 48.4375                                               │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 2      │
│   • HP scaling multiplier: 1.06                                              │
│   • Damage scaling multiplier: 1.04                                          │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Goblin (Tier: 1), HP: 30, Dmg: 5, CR: 45.5                        │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 2    Act: 1    Node Type: boss                                    │
│   • Max HP: 100  Attack: 0    Max Mana: 3    Relics: 1                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (0 * 10) + (3 * 15) + (1 * 5) = 150                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(2 - 1) * 15] + [(1 - 1) * 20] = 160                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(2 - 1) * 10] + [(1 - 1) * 25] = 50                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     150 / 160 = 0.9375                                                       │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.9375 - 1.0) * 0.5 = 0.96875                                     │
│   • NodeMultiplier: 2 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     50 * 0.96875 * 2 = 96.875                                                │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 4      │
│   • HP scaling multiplier: 3.54                                              │
│   • Damage scaling multiplier: 3.3600000000000003                            │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Slime (Tier: 1), HP: 64, Dmg: 13, CR: 87.65                       │
└──────────────────────────────────────────────────────────────────────────────┘

--- 

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 2    Act: 2    Node Type: combat                                  │
│   • Max HP: 100  Attack: 0    Max Mana: 3    Relics: 2                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (0 * 10) + (3 * 15) + (2 * 5) = 155                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(2 - 1) * 15] + [(2 - 1) * 20] = 180                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(2 - 1) * 10] + [(2 - 1) * 25] = 75                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     155 / 180 = 0.8611111111111112                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.8611111111111112 - 1.0) * 0.5 = 0.9305555555555556              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     75 * 0.9305555555555556 * 1 = 69.79166666666667                          │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 4      │
│   • HP scaling multiplier: 1.416                                             │
│   • Damage scaling multiplier: 1.288                                         │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Skeleton (Tier: 2), HP: 31, Dmg: 10, CR: 62                       │
└──────────────────────────────────────────────────────────────────────────────┘

--- 

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 2    Act: 2    Node Type: combat                                  │
│   • Max HP: 100  Attack: 0    Max Mana: 3    Relics: 2                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (0 * 10) + (3 * 15) + (2 * 5) = 155                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(2 - 1) * 15] + [(2 - 1) * 20] = 180                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(2 - 1) * 10] + [(2 - 1) * 25] = 75                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     155 / 180 = 0.8611111111111112                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.8611111111111112 - 1.0) * 0.5 = 0.9305555555555556              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     75 * 0.9305555555555556 * 1 = 69.79166666666667                          │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 4      │
│   • HP scaling multiplier: 1.416                                             │
│   • Damage scaling multiplier: 1.288                                         │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Goblin (Tier: 1), HP: 40, Dmg: 6, CR: 56.6                        │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 3    Act: 2    Node Type: combat                                  │
│   • Max HP: 100  Attack: 3    Max Mana: 3    Relics: 2                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (3 * 10) + (3 * 15) + (2 * 5) = 185                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(3 - 1) * 15] + [(2 - 1) * 20] = 195                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(3 - 1) * 10] + [(2 - 1) * 25] = 85                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     185 / 195 = 0.9487179487179487                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.9487179487179487 - 1.0) * 0.5 = 0.9743589743589743              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     85 * 0.9743589743589743 * 1 = 82.82051282051282                          │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 5      │
│   • HP scaling multiplier: 1.488                                             │
│   • Damage scaling multiplier: 1.3339999999999999                            │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Skeleton (Tier: 2), HP: 33, Dmg: 11, CR: 65.1                     │
└──────────────────────────────────────────────────────────────────────────────┘

--- 

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 3    Act: 2    Node Type: elite                                   │
│   • Max HP: 100  Attack: 3    Max Mana: 3    Relics: 2                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (3 * 10) + (3 * 15) + (2 * 5) = 185                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(3 - 1) * 15] + [(2 - 1) * 20] = 195                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(3 - 1) * 10] + [(2 - 1) * 25] = 85                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     185 / 195 = 0.9487179487179487                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.9487179487179487 - 1.0) * 0.5 = 0.9743589743589743              │
│   • NodeMultiplier: 2 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     85 * 0.9743589743589743 * 2 = 165.64102564102564                         │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 7      │
│   • HP scaling multiplier: 4.896                                             │
│   • Damage scaling multiplier: 4.278                                         │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Slime (Tier: 1), HP: 88, Dmg: 17, CR: 115.85                      │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 3    Act: 2    Node Type: combat                                  │
│   • Max HP: 100  Attack: 3    Max Mana: 3    Relics: 3                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (3 * 10) + (3 * 15) + (3 * 5) = 190                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(3 - 1) * 15] + [(2 - 1) * 20] = 195                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(3 - 1) * 10] + [(2 - 1) * 25] = 85                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     190 / 195 = 0.9743589743589743                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.9743589743589743 - 1.0) * 0.5 = 0.9871794871794872              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     85 * 0.9871794871794872 * 1 = 83.91025641025641                          │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 5      │
│   • HP scaling multiplier: 1.488                                             │
│   • Damage scaling multiplier: 1.3339999999999999                            │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Goblin (Tier: 1), HP: 42, Dmg: 7, CR: 59.7                        │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 3    Act: 2    Node Type: combat                                  │
│   • Max HP: 100  Attack: 3    Max Mana: 3    Relics: 3                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (3 * 10) + (3 * 15) + (3 * 5) = 190                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(3 - 1) * 15] + [(2 - 1) * 20] = 195                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(3 - 1) * 10] + [(2 - 1) * 25] = 85                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     190 / 195 = 0.9743589743589743                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.9743589743589743 - 1.0) * 0.5 = 0.9871794871794872              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     85 * 0.9871794871794872 * 1 = 83.91025641025641                          │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 5      │
│   • HP scaling multiplier: 1.488                                             │
│   • Damage scaling multiplier: 1.3339999999999999                            │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Goblin (Tier: 1), HP: 42, Dmg: 7, CR: 59.7                        │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 4    Act: 2    Node Type: boss                                    │
│   • Max HP: 100  Attack: 3    Max Mana: 3    Relics: 3                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (3 * 10) + (3 * 15) + (3 * 5) = 190                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(4 - 1) * 15] + [(2 - 1) * 20] = 210                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(4 - 1) * 10] + [(2 - 1) * 25] = 95                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     190 / 210 = 0.9047619047619048                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.9047619047619048 - 1.0) * 0.5 = 0.9523809523809523              │
│   • NodeMultiplier: 2 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     95 * 0.9523809523809523 * 2 = 180.95238095238093                         │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 8      │
│   • HP scaling multiplier: 5.112                                             │
│   • Damage scaling multiplier: 4.416                                         │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Goblin (Tier: 1), HP: 143, Dmg: 22, CR: 177.2                     │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 4    Act: 3    Node Type: combat                                  │
│   • Max HP: 100  Attack: 3    Max Mana: 3    Relics: 4                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (3 * 10) + (3 * 15) + (4 * 5) = 195                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(4 - 1) * 15] + [(3 - 1) * 20] = 230                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(4 - 1) * 10] + [(3 - 1) * 25] = 120                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     195 / 230 = 0.8478260869565217                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.8478260869565217 - 1.0) * 0.5 = 0.9239130434782609              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     120 * 0.9239130434782609 * 1 = 110.8695652173913                         │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 8      │
│   • HP scaling multiplier: 1.9879999999999998                                │
│   • Damage scaling multiplier: 1.6640000000000001                            │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Goblin (Tier: 1), HP: 56, Dmg: 8, CR: 74.8                        │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 4    Act: 3    Node Type: combat                                  │
│   • Max HP: 100  Attack: 3    Max Mana: 3    Relics: 4                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (3 * 10) + (3 * 15) + (4 * 5) = 195                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(4 - 1) * 15] + [(3 - 1) * 20] = 230                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(4 - 1) * 10] + [(3 - 1) * 25] = 120                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     195 / 230 = 0.8478260869565217                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.8478260869565217 - 1.0) * 0.5 = 0.9239130434782609              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     120 * 0.9239130434782609 * 1 = 110.8695652173913                         │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 8      │
│   • HP scaling multiplier: 1.9879999999999998                                │
│   • Damage scaling multiplier: 1.6640000000000001                            │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Goblin (Tier: 1), HP: 56, Dmg: 8, CR: 74.8                        │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 4    Act: 3    Node Type: combat                                  │
│   • Max HP: 100  Attack: 4    Max Mana: 3    Relics: 4                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (4 * 10) + (3 * 15) + (4 * 5) = 205                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(4 - 1) * 15] + [(3 - 1) * 20] = 230                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(4 - 1) * 10] + [(3 - 1) * 25] = 120                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     205 / 230 = 0.8913043478260869                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.8913043478260869 - 1.0) * 0.5 = 0.9456521739130435              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     120 * 0.9456521739130435 * 1 = 113.47826086956522                        │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 8      │
│   • HP scaling multiplier: 1.9879999999999998                                │
│   • Damage scaling multiplier: 1.6640000000000001                            │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Goblin (Tier: 1), HP: 56, Dmg: 8, CR: 74.8                        │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 4    Act: 3    Node Type: elite                                   │
│   • Max HP: 100  Attack: 4    Max Mana: 3    Relics: 4                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (4 * 10) + (3 * 15) + (4 * 5) = 205                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(4 - 1) * 15] + [(3 - 1) * 20] = 230                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(4 - 1) * 10] + [(3 - 1) * 25] = 120                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     205 / 230 = 0.8913043478260869                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.8913043478260869 - 1.0) * 0.5 = 0.9456521739130435              │
│   • NodeMultiplier: 1.5 (Boss = 2.0, Elite = 1.5, Normal = 1.0)              │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     120 * 0.9456521739130435 * 1.5 = 170.2173913043478                       │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 9      │
│   • HP scaling multiplier: 3.108                                             │
│   • Damage scaling multiplier: 2.5740000000000003                            │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Skeleton (Tier: 2), HP: 68, Dmg: 21, CR: 111.1                    │
└──────────────────────────────────────────────────────────────────────────────┘

--- 

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 5    Act: 3    Node Type: boss                                    │
│   • Max HP: 100  Attack: 6    Max Mana: 3    Relics: 5                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     100 + (6 * 10) + (3 * 15) + (5 * 5) = 230                                │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(5 - 1) * 15] + [(3 - 1) * 20] = 245                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(5 - 1) * 10] + [(3 - 1) * 25] = 130                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     230 / 245 = 0.9387755102040817                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.9387755102040817 - 1.0) * 0.5 = 0.9693877551020409              │
│   • NodeMultiplier: 2 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     130 * 0.9693877551020409 * 2 = 252.04081632653063                        │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 11     │
│   • HP scaling multiplier: 6.719999999999999                                 │
│   • Damage scaling multiplier: 5.459999999999999                             │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Slime (Tier: 1), HP: 121, Dmg: 22, CR: 154.1                      │
└──────────────────────────────────────────────────────────────────────────────┘

