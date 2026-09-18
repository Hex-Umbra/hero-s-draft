<!-- last-sync: 2026-09-18 | commit: 152fbcc -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**P-41 lot C, partie 1 est fusionnée dans `main`** par la **PR #42** (2026-09-18, merge `152fbcc`,
`face77b`..`9a2f375`, 11 commits, détail plus bas) : les huit récompenses de montée de niveau
quittent le code pour `assets/data/level_up_rewards/`, **à valeurs, textes et probabilités
identiques** — [ADR-098](../_adr/ADR-098-recompenses-de-niveau-en-donnee-et-gabarits-a-tr.md).
Le lot B reste fusionné en entier (PR #40 puis #41), et P-49 par la PR #39.

La note `0.5.2` a été **rouverte en place une quatrième fois** pour cette partie 1, même numéro,
une seule entrée en Technique — c'est la seule livraison de P-41 que le joueur ne ressent pas.
**Toujours pas taguée.** Métriques dans `progress.md`.

Réserves à ne pas perdre de vue :

- **Les trois décisions du propriétaire du 2026-09-15 sont intégrées à `main`** par la PR #37 :
  changements visibles ajoutés à la note `0.5.1` (`2d19d42`), cartes abîmées par l'ancienne fusion
  de légendaires réparées au chargement (`71d97cb`), corpus `docs/formation-heros-draft/` figé en
  instantané daté (`69fef58`). Plus aucune branche de P-40 n'est en attente.
- **Un dossier de classe `gambler` vide**, laissé par une écriture de l'éditeur, faisait rougir deux
  tests sur `main`. Supprimé le 2026-09-15 ; `entity_writer.dart` tient ce cas pour « sans conséquence ».
- **Les changements visibles de P-30 ont rejoint la note `0.5.1`** (`d8d9319`, décision du
  propriétaire le 2026-09-14) : bouton « Quitter », retours arrière, fin du badge « NEW »,
  illustration de classe. Rien sur le menu de debug ni l'éditeur, absents des builds publiés.
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
- **La modification d'entité par l'éditeur** est testée (`47f6731`, `25b2945`), sans passe dédiée consignée.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **P-41 lot C, partie 1 — les récompenses de niveau deviennent de la donnée** (2026-09-18,
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
2. **P-41 lot B, partie 2 — l'identité de classe** (2026-09-18, **fusionné dans `main` par la
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
3. **P-41 lot B, partie 1 — la Puissance, une seule stat orientée par la classe**
   (2026-09-17, **fusionné dans `main` par la PR #40**, 6 commits,
   `f20c353` → `e9b193d`) — `attackPower`/`skillPower`/`alterationPower` (lot A) fusionnent en une
   seule `might` ; `HeroData.mightTargets` (`class.json`, obligatoire) déclare ce qu'elle renforce,
   copié dans `EntityStats.mightTargets` à la création du héros ; `PowerRules` lit cette copie sans
   changer la forme de ses huit appels. Le statut `strength` devient `might` (`gain_might`,
   `charge_might_turn`, `charge_might_combat`), `applyAttackBuff` (code mort) supprimé. Tous les
   textes joueur disent Puissance/Might ; le sous-titre de la fiche de stats liste ce qu'elle
   renforce (`Set<MightTarget>.shortLabel`). **Comportement de jeu inchangé** : les trois classes
   ciblent `attack`. **Aucune migration de sauvegarde** (spec §7.5) : `SaveMigrator` reste en
   version 2, son étape v1→v2 garde `attackPower` en format gelé, désormais ignoré à la lecture.
   938 tests (+15), `dart analyze` propre. Voir
   [ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md) (amende la décision 2 d'ADR-095).
> [!NOTE]
> **Rotations.** Sorties le 2026-09-18 : `../_archive/2026-09-18-activeContext-livraisons-2.md`
> (P-49) et `../_archive/2026-09-18-activeContext-livraisons.md` (P-41 lot A). Sorties le
> 2026-09-17 : `../_archive/2026-09-17-activeContext-livraisons-2.md` (P-40 bloc 2, cartes et forge)
> et `../_archive/2026-09-17-activeContext-livraisons.md` (éditeur de contenu, habillage). Les neuf
> rotations précédentes portent le même nom, daté du 2026-09-16 au 2026-08-20, dans `../_archive/`.

## Prochaine étape

**P-41 lot C, partie 2** est le prochain chantier, [plan](../../docs/superpowers/plans/2026-09-18-p41-lot-c-partie-2-filtre-et-ecran-de-selection.md)
écrit et en attente : filtre d'*Affinité* quand le passif actif ne déclare pas de Maîtrise, retrait
de `baseDamage`, et l'**écran de choix du passif** — sans lui, six des neuf passifs du lot B restent
inatteignables, l'écran de sélection ne proposant que `passives.first`, et la note `0.5.2` a promis
cet écran au joueur. Il étend le modèle créé par la partie 1 d'un champ `requires`.

Il reste au propriétaire à **regarder tourner le lot B** — les trois identités de classe ne se
vérifient pas par la suite de tests. Le tag `v0.5.2` attend cette campagne manuelle et P-42 ; le
filtre de classe des cartes de signature se traite avant ou avec P-42.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05. **P-07 doit lire [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md)
D6 avant de toucher aux animations.**
