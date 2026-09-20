<!-- last-sync: 2026-09-20 | commit: 54c28dd -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**Le lot D de P-41 est engagé : sa partie 1 est fusionnée dans `main` par la PR #44** (2026-09-20,
merge `54c28dd`, `30d48dc`..`639a222`, 9 commits, détail plus bas) — **le tutoriel enseigne enfin la
classe qu'on y choisit** : le passif s'y choisit, dans le widget même de l'écran de sélection ;
l'étape « Armure & Dégâts » fait passer son gain de démonstration par les `statRules` de la classe ;
l'étape « Jouer des cartes » annonce le gain réel. **Aucun mécanisme nouveau, donc aucun ADR** :
la livraison applique ADR-081, ADR-090 et ADR-097. La note `0.5.2` a été **rouverte en place une
sixième fois**, même numéro, pour deux entrées neuves et aucune réécriture ; toujours **ni taguée
ni publiée** (dernière release `v0.5.1`). Métriques dans `progress.md`.

Réserves à ne pas perdre de vue :

- **⚠️ Les lots 1-2 de P-48 cassent toujours les sauvegardes antérieures à leurs ids de passifs en
  `snake_case`** (commit `7da5db2`). P-41 lot A a posé une chaîne de migration (`SaveMigrator`) et
  changé de clé de stockage (`run_save`, repli sur `run_save_v1`), mais sa seule étape migre
  `attaque` → `attackPower` : l'id de passif n'y est pas touché, et une partie d'avant `7da5db2` perd
  toujours son passif de classe au chargement, signalé par un `MissingSaveItem`. La note de version
  reste le seul canal qui prévienne *avant*.
- **La note `0.5.1` est close et publiée** (décision du 2026-09-16). La version que visent P-42 et la
  suite est tenue dans `docs/ROADMAP.md` ; le numéro publié se lit dans `pubspec.yaml` et la 1ʳᵉ
  entrée de `assets/data/patch_notes.json`, jamais ici.
- **Les cartes de signature non `unique` fuient toujours entre classes** en boutique et sur le bonus
  de boss — [filtre de classe](../../docs/possible_upgrades/08-09-2026_filtre_cartes_de_classe_Opus5.md),
  à joindre à `CardRarity.isAcquirable`, avant ou avec P-42. **Re-vérifié contre le code le
  2026-09-16 : non fait.** Les deux prédicats fautifs ne testent que le type et la rareté
  (`shop_controller.dart:45-51`, `reward_controller.dart:189`), aucun des deux `Notifier` ne lit
  `runProvider.heroClassId`, et `CardData` ne porte aucun prédicat de proposabilité. Ce que P-40
  bloc 2 a fait à ces deux mêmes lignes, c'est y substituer `CardRarity.isAcquirable` au
  `rarity != unique` en ligne — la condition de classe n'y est jamais entrée, et le seul commit sur
  le sujet reste `39ac887`, qui documente le défaut sans le corriger.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **P-41 lot D, partie 1 — le tutoriel enseigne la classe qu'on a choisie**
   (2026-09-20, **fusionné dans `main` par la PR #44**, merge `54c28dd`, 9 commits,
   `30d48dc` → `639a222`, branche `feat/p41-lot-d-tutoriel`) — **le tutoriel cesse d'enseigner
   une règle que la classe choisie ne suit pas.** Trois étapes arrêtaient chacune de court-circuiter
   un point de passage qui existait déjà : l'étape 02 déplie les passifs que `availablePassivesFor`
   ouvre à la classe — dans le **`ClassPassiveList` de l'écran de sélection**, le widget de
   production et non une seconde implémentation (spec §1.4) — et retaper la classe déjà choisie
   replie sa carte au lieu de reposer son passif. L'étape « Armure & Dégâts » fait passer son gain
   de démonstration par `StatGains.apply` et les `statRules` de la classe au lieu d'écrire 4 Armure
   en dur : elle se joue **en deux temps** (le gain, puis le coup), son panneau droit part de 0, son
   titre est **généré** depuis la règle qui vise l'Armure (`shortTitle`, deux clés ARB neuves) et la
   règle est écrite en clair sous les panneaux par `StatRuleLabel.describe`. L'étape « Jouer des
   cartes » **mesure le gain réel** de part et d'autre de `playCard` au lieu de lire la valeur
   imprimée sur la carte. Les deux acquis que le lot B avait livrés sans les verrouiller —
   `critChance` forcé à 0, conversion d'armure appliquée par `playCard` — passent sous test.
   **Aucun mécanisme nouveau, donc aucun ADR** : la livraison applique ADR-081, ADR-090 et
   ADR-097. **1159 tests** (+24), `dart analyze` propre.
2. **P-41 lot C, partie 2 — le choix du passif, et le conditionnement des récompenses**
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
3. **P-41 lot C, partie 1 — les récompenses de niveau deviennent de la donnée** (2026-09-18,
   **fusionné dans `main` par la PR #42**, merge `152fbcc`, 11 commits, `face77b` → `9a2f375`) —
   **le jeu ne change pas** : seule la provenance des valeurs change. Les huit récompenses — six
   tirables, deux mythiques, séparées par un champ `pool` — vivent sous
   `assets/data/level_up_rewards/`, neuvième source d'entités. `LevelUpRewardType`, son
   `rng.nextInt(6)` **indexé sur l'ordre de l'énumération** et 17 clés ARB disparaissent ; les deux
   régimes de valeur concurrents (multiplicateur générique **et** cascade de `if`) cèdent à une table
   `values` explicite, celle-là même dont l'absence avait laissé un légendaire retomber sur la valeur
   d'un commun. Les descriptions deviennent des **gabarits à trous** (`{amount}`, `{passive}`,
   `{effect}`) : composer l'*Affinité* avec le passif actif est une règle unique, non une branche par
   récompense. L'application du gain quitte l'écran de draft pour `PlayerStatsManager`, `switch`
   exhaustif sur `RewardStat` ; la prose du tutoriel lit le registre par une fonction pure, ADR-081
   intact. **Un seul texte joueur bouge** : la liste des mythiques du tutoriel perd ses articles.
   **1065 tests** (+44), `dart analyze` propre —
   [ADR-098](../_adr/ADR-098-recompenses-de-niveau-en-donnee-et-gabarits-a-tr.md).
> [!NOTE]
> **Rotations.** Sorties le 2026-09-20 : `../_archive/2026-09-20-activeContext-livraisons-2.md`
> (P-41 lot B partie 2) et `../_archive/2026-09-20-activeContext-livraisons.md` (P-41 lot B
> partie 1, avec quatre réserves closes). Sorties le 2026-09-18 :
> `../_archive/2026-09-18-activeContext-livraisons-2.md` (P-49) et
> `../_archive/2026-09-18-activeContext-livraisons.md` (P-41 lot A). Les onze rotations précédentes
> portent le même nom, daté du 2026-09-17 au 2026-08-20, dans `../_archive/`.

## Prochaine étape

**P-41 lot D, partie 2 — la console de debug** (spec §9.2) est tout ce qui reste du chantier :
`statRules` validé par l'éditeur (`"mode": "convrt"` passe encore), création guidée de classe
garantissant un passif disponible, récompenses de niveau en 8ᵉ catégorie éditable, et cibles de la
Puissance réglables depuis le menu de debug. Son
[plan](../../docs/superpowers/plans/2026-09-20-p41-lot-d-partie-2-console-de-debug.md) est écrit et
non exécuté ; il ne partage aucun fichier de `lib/` avec la partie 1.

Il reste au propriétaire à **regarder tourner les lots B, C et D** — les trois identités de classe,
le nouvel écran de sélection et le tutoriel ne se vérifient pas par la suite de tests, et les cartes
de classe ont été recalibrées à l'œil. Le tag `v0.5.2` attend cette campagne manuelle et P-42 ; le
filtre de classe des cartes de signature se traite avant ou avec P-42.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05. **P-07 doit lire [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md)
D6 avant de toucher aux animations.**
