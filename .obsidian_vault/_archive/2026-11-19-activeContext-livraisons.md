# Rotation de `activeContext.md` — 2026-11-19

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-11-19**,
poussée par l'entrée de la **clôture du chantier « Économie unifiée et catalogue »** — la vague 8
fusionnée dans `main` par la PR #56 et taguée `v0.6.0`, le chantier clos.
FIFO strict à 3 : la 4ᵉ livraison sort. Recopiée **telle quelle** — chiffres, dates et affirmations
intouchés ; ses liens `../_adr/` se résolvent depuis ce dossier comme depuis le sien.

## La livraison sortie

3. **Vague 6 — P-42 tranche 2 : Croisé, Vampire, Voile, et la banque de mana de *Canalisation***
   (2026-11-15, branche `feat/v0.5.8-p42-tranche-2`, 12 commits `b8e0641b` → `074d53ac` sur `main`
   à `df1b671d` — **fusionnée dans `main` le 2026-11-15 par la PR #54, merge `56fae9df`, taguée,
   CI/CD verte**) — **six passifs sur neuf se jouent.**
   **Trois lots de cinq cartes**, toutes communes, rangés sous `cards/<passif>/` : **Croisé**
   (*Ferveur*, Paladin) — cinq Attaques, trois qui donnent de l'Armure, deux multi-coups à
   `mightRatio` 0,75 ; **Vampire** (*Soif de Sang*, Berserker) — cinq Attaques, trois qui piochent,
   *Lacération* à 0 qui s'épuise, *Frénésie sanglante* à 1 mana qui grandit avec les cartes jouées
   ce tour ; **Voile** (*Canalisation*, Mage) — Pouvoirs durables et Compétences à 3, courbe
   1-2-3-3-3. Leur arrivée **démasque leurs passifs par la donnée** (O5), sans code ; le Mage
   démarre de nouveau sur *Canalisation*. **La banque de mana** (D30) : à la fin du tour, le mana
   non dépensé passe en réserve, jusqu'au Mana max + Maîtrise, et le tour suivant commence avec
   — `RunState.manaReserve`, jamais sauvegardée ; un seul calcul, `ManaReserve.preview`, pour la
   stratégie et l'écran ; hors de `StatGains`. **À l'écran**, réponse C et D du propriétaire sur
   maquettes (15/11) : flèches sur les cristaux qui passeront en réserve, légende cyan « +n au
   prochain tour », message de fin de tour « n Mana en réserve », bordé de cyan ; Mage sous
   *Canalisation* seulement. **Un statut neuf**, `mana_regen` (*Source de Mana*), posé par
   *Méditation* ; *Persistant* et *Résonant* le refusent par `excludesEffects`, qui lit désormais
   `status:<id>` (D44). **Deux corrections de la revue d'ensemble** : la main de l'étape « Jouer des
   cartes » du tutoriel tient dans le Mana max ; la légende de la réserve quitte le combat fini.
   Une question P, A14 — l'affichage de la réserve —, tranchée par le propriétaire sur maquettes
   le 15/11 (`df1b671d`) ; T1.1, rendue P par le vérificateur, reclassée T. Note de version écrite (`074d53ac`). **1682 tests** (+62 sur la base de **1620**, celle
   de la porte d'entrée), `dart analyze` propre (**vérifié le 2026-11-15**) —
   [ADR-116](../_adr/ADR-116-canalisation-une-banque-de-mana.md).
