┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 1    Act: 1    Node Type: combat                                  │
│   • Max HP: 80   Attack: 0    Max Mana: 3    Relics: 0                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (0 * 10) + (3 * 15) + (0 * 5) = 125                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(1 - 1) * 15] + [(1 - 1) * 20] = 145                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(1 - 1) * 10] + [(1 - 1) * 25] = 40                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     125 / 145 = 0.8620689655172413                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.8620689655172413 - 1.0) * 0.5 = 0.9310344827586207              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     40 * 0.9310344827586207 * 1 = 37.241379310344826                         │
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
│   • Max HP: 80   Attack: 0    Max Mana: 3    Relics: 0                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (0 * 10) + (3 * 15) + (0 * 5) = 125                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(1 - 1) * 15] + [(1 - 1) * 20] = 145                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(1 - 1) * 10] + [(1 - 1) * 25] = 40                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     125 / 145 = 0.8620689655172413                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.8620689655172413 - 1.0) * 0.5 = 0.9310344827586207              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     40 * 0.9310344827586207 * 1 = 37.241379310344826                         │
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
│   • Max HP: 80   Attack: 0    Max Mana: 3    Relics: 0                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (0 * 10) + (3 * 15) + (0 * 5) = 125                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(1 - 1) * 15] + [(1 - 1) * 20] = 145                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(1 - 1) * 10] + [(1 - 1) * 25] = 40                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     125 / 145 = 0.8620689655172413                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.8620689655172413 - 1.0) * 0.5 = 0.9310344827586207              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     40 * 0.9310344827586207 * 1 = 37.241379310344826                         │
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
│   • Max HP: 80   Attack: 0    Max Mana: 3    Relics: 0                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (0 * 10) + (3 * 15) + (0 * 5) = 125                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(1 - 1) * 15] + [(1 - 1) * 20] = 145                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(1 - 1) * 10] + [(1 - 1) * 25] = 40                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     125 / 145 = 0.8620689655172413                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.8620689655172413 - 1.0) * 0.5 = 0.9310344827586207              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     40 * 0.9310344827586207 * 1 = 37.241379310344826                         │
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
│   • Level: 2    Act: 1    Node Type: elite                                   │
│   • Max HP: 80   Attack: 0    Max Mana: 5    Relics: 1                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (0 * 10) + (5 * 15) + (1 * 5) = 160                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(2 - 1) * 15] + [(1 - 1) * 20] = 160                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(2 - 1) * 10] + [(1 - 1) * 25] = 50                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     160 / 160 = 1                                                            │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (1 - 1.0) * 0.5 = 1                                                │
│   • NodeMultiplier: 1.5 (Boss = 2.0, Elite = 1.5, Normal = 1.0)              │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     50 * 1 * 1.5 = 75                                                        │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 3      │
│   • HP scaling multiplier: 1.6800000000000002                                │
│   • Damage scaling multiplier: 1.62                                          │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Skeleton (Tier: 2), HP: 37, Dmg: 13, CR: 71.3                     │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 2    Act: 1    Node Type: boss                                    │
│   • Max HP: 80   Attack: 1    Max Mana: 5    Relics: 2                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (1 * 10) + (5 * 15) + (2 * 5) = 175                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(2 - 1) * 15] + [(1 - 1) * 20] = 160                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(2 - 1) * 10] + [(1 - 1) * 25] = 50                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     175 / 160 = 1.09375                                                      │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (1.09375 - 1.0) * 0.5 = 1.046875                                   │
│   • NodeMultiplier: 2 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     50 * 1.046875 * 2 = 104.6875                                             │
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
│   • Max HP: 80   Attack: 1    Max Mana: 5    Relics: 3                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (1 * 10) + (5 * 15) + (3 * 5) = 180                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(2 - 1) * 15] + [(2 - 1) * 20] = 180                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(2 - 1) * 10] + [(2 - 1) * 25] = 75                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     180 / 180 = 1                                                            │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (1 - 1.0) * 0.5 = 1                                                │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     75 * 1 * 1 = 75                                                          │
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
│   • Level: 2    Act: 2    Node Type: combat                                  │
│   • Max HP: 80   Attack: 2    Max Mana: 5    Relics: 3                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (2 * 10) + (5 * 15) + (3 * 5) = 190                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(2 - 1) * 15] + [(2 - 1) * 20] = 180                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(2 - 1) * 10] + [(2 - 1) * 25] = 75                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     190 / 180 = 1.0555555555555556                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (1.0555555555555556 - 1.0) * 0.5 = 1.0277777777777777              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     75 * 1.0277777777777777 * 1 = 77.08333333333333                          │
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
│   • Level: 3    Act: 2    Node Type: combat                                  │
│   • Max HP: 80   Attack: 2    Max Mana: 5    Relics: 3                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (2 * 10) + (5 * 15) + (3 * 5) = 190                                 │
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
│   • Max HP: 80   Attack: 2    Max Mana: 5    Relics: 3                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (2 * 10) + (5 * 15) + (3 * 5) = 190                                 │
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

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 3    Act: 2    Node Type: boss                                    │
│   • Max HP: 80   Attack: 3    Max Mana: 5    Relics: 3                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (3 * 10) + (5 * 15) + (3 * 5) = 200                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(3 - 1) * 15] + [(2 - 1) * 20] = 195                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(3 - 1) * 10] + [(2 - 1) * 25] = 85                                │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     200 / 195 = 1.0256410256410255                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (1.0256410256410255 - 1.0) * 0.5 = 1.0128205128205128              │
│   • NodeMultiplier: 2 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     85 * 1.0128205128205128 * 2 = 172.17948717948718                         │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 7      │
│   • HP scaling multiplier: 4.896                                             │
│   • Damage scaling multiplier: 4.278                                         │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Goblin (Tier: 1), HP: 137, Dmg: 21, CR: 170.1                     │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 3    Act: 3    Node Type: combat                                  │
│   • Max HP: 80   Attack: 3    Max Mana: 5    Relics: 4                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (3 * 10) + (5 * 15) + (4 * 5) = 205                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(3 - 1) * 15] + [(3 - 1) * 20] = 215                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(3 - 1) * 10] + [(3 - 1) * 25] = 110                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     205 / 215 = 0.9534883720930233                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.9534883720930233 - 1.0) * 0.5 = 0.9767441860465116              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     110 * 0.9767441860465116 * 1 = 107.44186046511628                        │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 7      │
│   • HP scaling multiplier: 1.9039999999999997                                │
│   • Damage scaling multiplier: 1.612                                         │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Goblin (Tier: 1), HP: 53, Dmg: 8, CR: 71.8                        │
└──────────────────────────────────────────────────────────────────────────────┘

🎉 Draft Reel Land: Index 0 Revealed!
🎉 Draft Reel Land: Index 1 Revealed!
🎉 Draft Reel Land: Index 2 Revealed!
┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 4    Act: 3    Node Type: combat                                  │
│   • Max HP: 80   Attack: 3    Max Mana: 5    Relics: 4                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (3 * 10) + (5 * 15) + (4 * 5) = 205                                 │
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
│ 👾 GENERATED ENEMIES (Count: 2):                                             │
│   - Enemy: Slime (Tier: 1), HP: 36, Dmg: 7, CR: 53.35                        │
│   - Enemy: Slime (Tier: 1), HP: 36, Dmg: 7, CR: 53.35                        │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 4    Act: 3    Node Type: combat                                  │
│   • Max HP: 80   Attack: 3    Max Mana: 5    Relics: 4                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (3 * 10) + (5 * 15) + (4 * 5) = 205                                 │
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

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 4    Act: 3    Node Type: combat                                  │
│   • Max HP: 80   Attack: 3    Max Mana: 5    Relics: 4                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (3 * 10) + (5 * 15) + (4 * 5) = 205                                 │
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
│   - Enemy: Skeleton (Tier: 2), HP: 44, Dmg: 13, CR: 78.3                     │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 4    Act: 3    Node Type: combat                                  │
│   • Max HP: 80   Attack: 3    Max Mana: 5    Relics: 4                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (3 * 10) + (5 * 15) + (4 * 5) = 205                                 │
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
│   - Enemy: Skeleton (Tier: 2), HP: 44, Dmg: 13, CR: 78.3                     │
└──────────────────────────────────────────────────────────────────────────────┘

🎉 Draft Reel Land: Index 0 Revealed!
🎉 Draft Reel Land: Index 1 Revealed!
🎉 Draft Reel Land: Index 2 Revealed!
┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 5    Act: 3    Node Type: boss                                    │
│   • Max HP: 80   Attack: 3    Max Mana: 5    Relics: 4                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (3 * 10) + (5 * 15) + (4 * 5) = 205                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(5 - 1) * 15] + [(3 - 1) * 20] = 245                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(5 - 1) * 10] + [(3 - 1) * 25] = 130                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     205 / 245 = 0.8367346938775511                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.8367346938775511 - 1.0) * 0.5 = 0.9183673469387755              │
│   • NodeMultiplier: 2 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     130 * 0.9183673469387755 * 2 = 238.77551020408163                        │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 11     │
│   • HP scaling multiplier: 6.719999999999999                                 │
│   • Damage scaling multiplier: 5.459999999999999                             │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Slime (Tier: 1), HP: 121, Dmg: 22, CR: 154.1                      │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 5    Act: 4    Node Type: combat                                  │
│   • Max HP: 80   Attack: 3    Max Mana: 5    Relics: 5                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (3 * 10) + (5 * 15) + (5 * 5) = 210                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(5 - 1) * 15] + [(4 - 1) * 20] = 265                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(5 - 1) * 10] + [(4 - 1) * 25] = 155                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     210 / 265 = 0.7924528301886793                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.7924528301886793 - 1.0) * 0.5 = 0.8962264150943396              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     155 * 0.8962264150943396 * 1 = 138.91509433962264                        │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 11     │
│   • HP scaling multiplier: 2.5600000000000005                                │
│   • Damage scaling multiplier: 2.03                                          │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Skeleton (Tier: 2), HP: 56, Dmg: 16, CR: 93.6                     │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 5    Act: 4    Node Type: combat                                  │
│   • Max HP: 80   Attack: 3    Max Mana: 5    Relics: 5                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (3 * 10) + (5 * 15) + (5 * 5) = 210                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(5 - 1) * 15] + [(4 - 1) * 20] = 265                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(5 - 1) * 10] + [(4 - 1) * 25] = 155                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     210 / 265 = 0.7924528301886793                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.7924528301886793 - 1.0) * 0.5 = 0.8962264150943396              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     155 * 0.8962264150943396 * 1 = 138.91509433962264                        │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 11     │
│   • HP scaling multiplier: 2.5600000000000005                                │
│   • Damage scaling multiplier: 2.03                                          │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 2):                                             │
│   - Enemy: Slime (Tier: 1), HP: 46, Dmg: 8, CR: 64.4                         │
│   - Enemy: Slime (Tier: 1), HP: 46, Dmg: 8, CR: 64.4                         │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 5    Act: 4    Node Type: combat                                  │
│   • Max HP: 80   Attack: 3    Max Mana: 5    Relics: 5                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (3 * 10) + (5 * 15) + (5 * 5) = 210                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(5 - 1) * 15] + [(4 - 1) * 20] = 265                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(5 - 1) * 10] + [(4 - 1) * 25] = 155                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     210 / 265 = 0.7924528301886793                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.7924528301886793 - 1.0) * 0.5 = 0.8962264150943396              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     155 * 0.8962264150943396 * 1 = 138.91509433962264                        │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 11     │
│   • HP scaling multiplier: 2.5600000000000005                                │
│   • Damage scaling multiplier: 2.03                                          │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Skeleton (Tier: 2), HP: 56, Dmg: 16, CR: 93.6                     │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 5    Act: 4    Node Type: combat                                  │
│   • Max HP: 80   Attack: 3    Max Mana: 5    Relics: 5                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (3 * 10) + (5 * 15) + (5 * 5) = 210                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(5 - 1) * 15] + [(4 - 1) * 20] = 265                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(5 - 1) * 10] + [(4 - 1) * 25] = 155                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     210 / 265 = 0.7924528301886793                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.7924528301886793 - 1.0) * 0.5 = 0.8962264150943396              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     155 * 0.8962264150943396 * 1 = 138.91509433962264                        │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 11     │
│   • HP scaling multiplier: 2.5600000000000005                                │
│   • Damage scaling multiplier: 2.03                                          │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 2):                                             │
│   - Enemy: Slime (Tier: 1), HP: 46, Dmg: 8, CR: 64.4                         │
│   - Enemy: Slime (Tier: 1), HP: 46, Dmg: 8, CR: 64.4                         │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 5    Act: 4    Node Type: elite                                   │
│   • Max HP: 80   Attack: 3    Max Mana: 5    Relics: 5                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (3 * 10) + (5 * 15) + (5 * 5) = 210                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(5 - 1) * 15] + [(4 - 1) * 20] = 265                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(5 - 1) * 10] + [(4 - 1) * 25] = 155                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     210 / 265 = 0.7924528301886793                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.7924528301886793 - 1.0) * 0.5 = 0.8962264150943396              │
│   • NodeMultiplier: 1.5 (Boss = 2.0, Elite = 1.5, Normal = 1.0)              │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     155 * 0.8962264150943396 * 1.5 = 208.37264150943395                      │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 12     │
│   • HP scaling multiplier: 3.984                                             │
│   • Damage scaling multiplier: 3.132                                         │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Skeleton (Tier: 2), HP: 88, Dmg: 25, CR: 135.5                    │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 6    Act: 4    Node Type: boss                                    │
│   • Max HP: 80   Attack: 6    Max Mana: 5    Relics: 7                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (6 * 10) + (5 * 15) + (7 * 5) = 250                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(6 - 1) * 15] + [(4 - 1) * 20] = 280                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(6 - 1) * 10] + [(4 - 1) * 25] = 165                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     250 / 280 = 0.8928571428571429                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.8928571428571429 - 1.0) * 0.5 = 0.9464285714285714              │
│   • NodeMultiplier: 2 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     165 * 0.9464285714285714 * 2 = 312.32142857142856                        │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 14     │
│   • HP scaling multiplier: 8.544                                             │
│   • Damage scaling multiplier: 6.611999999999999                             │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Slime (Tier: 1), HP: 154, Dmg: 26, CR: 191.3                      │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 6    Act: 5    Node Type: combat                                  │
│   • Max HP: 80   Attack: 6    Max Mana: 5    Relics: 8                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (6 * 10) + (5 * 15) + (8 * 5) = 255                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(6 - 1) * 15] + [(5 - 1) * 20] = 300                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(6 - 1) * 10] + [(5 - 1) * 25] = 190                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     255 / 300 = 0.85                                                         │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.85 - 1.0) * 0.5 = 0.925                                         │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     190 * 0.925 * 1 = 175.75                                                 │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 14     │
│   • HP scaling multiplier: 3.204                                             │
│   • Damage scaling multiplier: 2.4320000000000004                            │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Goblin (Tier: 1), HP: 90, Dmg: 12, CR: 113.2                      │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 6    Act: 5    Node Type: elite                                   │
│   • Max HP: 80   Attack: 8    Max Mana: 5    Relics: 8                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (8 * 10) + (5 * 15) + (8 * 5) = 275                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(6 - 1) * 15] + [(5 - 1) * 20] = 300                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(6 - 1) * 10] + [(5 - 1) * 25] = 190                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     275 / 300 = 0.9166666666666666                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.9166666666666666 - 1.0) * 0.5 = 0.9583333333333333              │
│   • NodeMultiplier: 1.5 (Boss = 2.0, Elite = 1.5, Normal = 1.0)              │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     190 * 0.9583333333333333 * 1.5 = 273.125                                 │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 15     │
│   • HP scaling multiplier: 4.968                                             │
│   • Damage scaling multiplier: 3.7440000000000007                            │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Goblin (Tier: 1), HP: 139, Dmg: 19, CR: 169.9                     │
└──────────────────────────────────────────────────────────────────────────────┘

---

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 6    Act: 5    Node Type: combat                                  │
│   • Max HP: 80   Attack: 8    Max Mana: 5    Relics: 9                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (8 * 10) + (5 * 15) + (9 * 5) = 280                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(6 - 1) * 15] + [(5 - 1) * 20] = 300                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(6 - 1) * 10] + [(5 - 1) * 25] = 190                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     280 / 300 = 0.9333333333333333                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.9333333333333333 - 1.0) * 0.5 = 0.9666666666666667              │
│   • NodeMultiplier: 1 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     190 * 0.9666666666666667 * 1 = 183.66666666666666                        │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 14     │
│   • HP scaling multiplier: 3.204                                             │
│   • Damage scaling multiplier: 2.4320000000000004                            │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Goblin (Tier: 1), HP: 90, Dmg: 12, CR: 113.2                      │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ ⚔️  COMBAT INITIALIZATION MATHEMATICS                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│ 👤 PLAYER STATS:                                                             │
│   • Level: 6    Act: 5    Node Type: boss                                    │
│   • Max HP: 80   Attack: 8    Max Mana: 5    Relics: 9                       │
│                                                                              │
│ 📊 FORMULAS & CALCULATIONS:                                                  │
│   • PlayerPower formula: maxHP + (attaque * 10) + (maxMana * 15) + (relicsCount * 5) │
│     80 + (8 * 10) + (5 * 15) + (9 * 5) = 280                                 │
│   • ExpectedPower formula: 145 + [(playerLevel - 1) * 15] + [(act - 1) * 20] │
│     145 + [(6 - 1) * 15] + [(5 - 1) * 20] = 300                              │
│   • BaseBudget formula: 40 + [(playerLevel - 1) * 10] + [(act - 1) * 25]     │
│     40 + [(6 - 1) * 10] + [(5 - 1) * 25] = 190                               │
│   • PowerRatio calculation: PlayerPower / ExpectedPower                      │
│     280 / 300 = 0.9333333333333333                                           │
│   • PowerModifier formula: 1.0 + (PowerRatio - 1.0) * 0.5                    │
│     1.0 + (0.9333333333333333 - 1.0) * 0.5 = 0.9666666666666667              │
│   • NodeMultiplier: 2 (Boss = 2.0, Elite = 1.5, Normal = 1.0)                │
│   • FinalBudget formula: BaseBudget * PowerModifier * NodeMultiplier         │
│     190 * 0.9666666666666667 * 2 = 367.3333333333333                         │
│                                                                              │
│ ⚙️  SCALING DETAILS:                                                         │
│   • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = 16     │
│   • HP scaling multiplier: 10.26                                             │
│   • Damage scaling multiplier: 7.6800000000000015                            │
│                                                                              │
│ 👾 GENERATED ENEMIES (Count: 1):                                             │
│   - Enemy: Skeleton (Tier: 2), HP: 226, Dmg: 61, CR: 313.1                   │
└──────────────────────────────────────────────────────────────────────────────┘