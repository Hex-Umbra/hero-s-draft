# Rotation de `activeContext.md` — 2026-09-21

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-09-21**,
poussée par l'entrée du **filtre de classe sur les pools d'offre** (commit `3727f09`). FIFO strict
à 3 : la 4ᵉ livraison sort. Recopiée **telle quelle** — chiffres, dates et affirmations intouchés,
seuls les chemins relatifs ont été rebasés d'un niveau pour rester résolvables depuis ce répertoire.

## La livraison sortie

**P-41 lot C, partie 2 — le choix du passif, et le conditionnement des récompenses**
(2026-09-20, **fusionné dans `main` par la PR #43**, merge `2f850c4`, 20 commits de code,
`2d167fa` → `0db8d4e`, branche `feat/p41-lot-c-selection`) — **l'écran de sélection de classe
cesse de mentir deux fois.** Le joueur y **choisit son passif** : la carte déplie *tous* ceux
que `availablePassivesFor()` rend — jamais un `take(3)`, trois étant un compte et non une règle
que P-13 fera varier — et le retenu part avec la run. Six des neuf passifs du lot B étaient
jusque-là livrés, testés et inatteignables. `baseDamage` (5 / 15 / 10) quitte `HeroData`, les
trois `class.json` et `sword_icon.dart` : aucune run ne le reprenait, toutes démarrant à
`might: 0`. La carte montre à la place les PV et le mana **toujours**, `mastery`, `critChance`
et `luck` **seulement si > 0**, plus l'orientation de la Puissance et la règle de stat en clair
— trois textes **générés depuis la donnée**, sur des `switch` exhaustifs dans
`model_extensions.dart`, aucun `hero.id` comparé (ADR-090) ; premier **pluriel ICU** des ARB du
projet. *Affinité* n'est plus tirée quand le passif actif ne déclare pas de `mastery` : un champ
`requires` sur `LevelUpRewardData`, **le mécanisme et non la récompense**, qui lit
`RunState.activePassive` et non le point d'accès de P-49. La carte se dimensionne désormais à
son contenu — une colonne sur mobile, rangées intrinsèques en desktop. **1135 tests** (+70),
`dart analyze` propre —
[ADR-099](../_adr/ADR-099-choix-du-passif-et-conditionnement-des-recompenses.md).
