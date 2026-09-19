<!-- last-sync: 2026-09-20 | commit: c29487e -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**Le lot C de P-41 est clos, et avec lui les lots A, B et C : seul le lot D reste.** Sa **partie 2**
est fusionnée dans `main` par la **PR #43** (2026-09-20, merge `2f850c4`, `2d167fa`..`0db8d4e`,
20 commits de code, détail plus bas) : **le joueur choisit son passif à la sélection de classe**, et
les neuf passifs livrés par le lot B deviennent atteignables — c'est le verrou que le lot C avait à
lever. `baseDamage` quitte l'écran et le modèle de héros ; *Affinité* n'est plus tirée quand le
passif actif ne déclare aucune Maîtrise —
[ADR-099](../_adr/ADR-099-choix-du-passif-et-conditionnement-des-recompenses.md).

La note `0.5.2` a été **rouverte en place une cinquième fois** pour cette partie 2, même numéro :
quatre entrées neuves — dont une section Corrections — et, **pour la première fois, une entrée
existante réécrite**, celle qui annonçait cet écran comme à venir. La note n'étant **ni taguée ni
publiée** (dernière release `v0.5.1`), aucun joueur n'avait lu la phrase corrigée.
Métriques dans `progress.md`.

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

1. **P-41 lot C, partie 2 — le choix du passif, et le conditionnement des récompenses**
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
2. **P-41 lot C, partie 1 — les récompenses de niveau deviennent de la donnée** (2026-09-18,
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
3. **P-41 lot B, partie 2 — l'identité de classe** (2026-09-18, **fusionné dans `main` par la
   PR #41**, merge `5086272`, 18 commits, `74c54cf` → `83e65b9`) — **la première livraison de P-41 que le
   joueur ressent.** Le Paladin renforce tout, le Berserker ses seules Attaques, le Mage ses
   Compétences et ses altérations. Le Berserker **n'a plus jamais d'armure** : toute source devient
   une Puissance d'un tour, par une `statRules` de son `class.json` qu'applique
   `StatGains.apply(stats, gain, rules)`, troisième paramètre désormais obligatoire. Les **neuf
   passifs** remplacent les trois (`berserker_armor` et `spell_armor` supprimés) ; un passif choisit
   son déclencheur par sa donnée, compte par un statut caché, et reçoit ce qu'il ne peut recalculer.
   Stats de départ propres (Maîtrise 1 au Paladin, 10 % de critique au Berserker) ; la Puissance
   porte un éclair. **1021 tests** (+83), `dart analyze` propre —
   [ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md), section « Partie 2 ».
> [!NOTE]
> **Rotations.** Sortie le 2026-09-20 : `../_archive/2026-09-20-activeContext-livraisons.md`
> (P-41 lot B partie 1), avec quatre réserves closes. Sorties le 2026-09-18 :
> `../_archive/2026-09-18-activeContext-livraisons-2.md` (P-49) et
> `../_archive/2026-09-18-activeContext-livraisons.md` (P-41 lot A). Les onze rotations précédentes
> portent le même nom, daté du 2026-09-17 au 2026-08-20, dans `../_archive/`.

## Prochaine étape

**P-41 lot D** est le dernier lot du chantier, et n'a pas encore de plan : mise à jour fonctionnelle
du tutoriel et de la console de debug. Deux reports nommés par le lot C l'attendent — l'étape de
choix de classe du tutoriel, qui suppose toujours un passif unique
(`tutorial_fixtures.dart:58`, spec §9.1), et `statRules` que l'éditeur de contenu ne valide pas
(spec §9.2).

Il reste au propriétaire à **regarder tourner les lots B et C** — les trois identités de classe et
le nouvel écran de sélection ne se vérifient pas par la suite de tests, et la carte de classe a été
recalibrée à l'œil, mobile et desktop. Le tag `v0.5.2` attend cette campagne manuelle et P-42 ; le
filtre de classe des cartes de signature se traite avant ou avec P-42.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05. **P-07 doit lire [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md)
D6 avant de toucher aux animations.**
