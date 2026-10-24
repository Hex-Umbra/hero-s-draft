# Rotation de `activeContext.md` — 2026-10-16

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-10-16**,
poussée par l'entrée de la **vague 4 du programme P-43 → P-42 → P-44 lot 1** — lot E4 de P-43,
« les signatures en compétences de classe », livré sur la branche `feat/v0.5.6-p43-e4-signatures`.
FIFO strict à 3 : la 4ᵉ livraison sort. Recopiée **telle quelle** — chiffres, dates et affirmations
intouchés ; ses liens `../_adr/` se résolvent depuis ce dossier comme depuis le sien.

## La livraison sortie

3. **Vague 1 — P-43 lots E0 et E1 : la Puissance par source, le `ratio`, et le moteur de runes en
   donnée** (2026-10-01 → 2026-10-02, branche `feat/v0.5.3-p43-e0-e1`, 22 commits `0f56cd4` →
   `52cba87` sur `main` à `0ccacce` — **fusionnée dans `main` le 2026-10-02 par la PR #47, merge
   `559df08`, taguée, CI/CD verte, release publiée**) — **la Puissance garde la
   durée de ce qui la donne, et une rune devient un fichier.** *E0* : un statut retient sa source,
   et `addStatus` ne fusionne plus que même statut **et** même source — seule la Puissance en
   reçoit une ; *Forme Démoniaque* puis *Mur de Fer* donnent 7 ce tour-ci puis 2, au lieu de 12
   pendant quatre tours. La règle de classe gagne un `ratio` borné à ]0, 1] : le Berserker convertit
   la moitié de son Armure, arrondie au-dessus, et sa règle le dit en clair. *E1* : une rune
   déclare son effet en **deltas typés** (`percentBonus`, `addEffect`, `removeExhaust`), qu'un
   **applicateur unique**, `EffectiveCard`, calcule pour le moteur, les rendus de carte et le tutoriel ;
   son éligibilité par **un prédicat** lu dans la donnée, exclusions symétriques comprises ; son
   plafond par **`maxLevel`**, borné aux quatre endroits qui écrivent un niveau. *Tranchant* et
   *Endurci* passent à +15 % de la base, au moins +1 ; G1 fait gagner au moins 1 par fusion à tout
   chiffre que la rareté multiplie, G2 gèle la pioche et le mana ; les statuts des runes
   élémentaires fusionnent avec ceux de la cible ; le feu refuse une carte qui ne peut plus
   recevoir de rune. **La revue d'ensemble a trouvé un trou** — la fusion de cartes réunissait
   *Persistant* et *Économe*, que le prédicat interdit ensemble : corrigé avant la note (`ee814e9`).
   La simulation, relancée en un seul temps, rend sa référence à l'identique (compte rendu §4) :
   E0 et E1 n'y changent rien qu'elle lise. Note de version écrite (`52cba87`). **1375 tests** (+188
   sur la base de **1187**, re-mesurée sur `main` à `0ccacce`), `dart analyze` propre (**vérifié le
   2026-10-02**) — [ADR-104](../_adr/ADR-104-un-statut-par-source-et-ratio-de-conversion.md),
   [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md), qui amende ADR-094.
