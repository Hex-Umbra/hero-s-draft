<!-- last-sync: 2026-09-18 | commit: 5086272 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**P-41 lot B est fusionné dans `main` en entier** : la partie 2 — l'identité de classe — l'a rejoint
par la **PR #41** (2026-09-18, merge `5086272`, `74c54cf`..`83e65b9`, 18 commits, détail plus bas),
après la partie 1 par la PR #40 (merge `e2cc24b`). [ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md)
est **complété** par ses six décisions d'implémentation, dont la seule de portée architecturale : les
règles de stat vivent sur `RunState`, redérivées de la classe au chargement et jamais sérialisées.

**P-49 (passifs partagés) reste fusionné dans `main`** par la PR #39 (2026-09-17, merge `56be78d`) :
chaque passif déclare ses classes éligibles et sa Maîtrise — [ADR-096](../_adr/ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md),
qui remplace la D4 d'ADR-086. La note `0.5.2` a été **rouverte en place une troisième fois** pour
cette partie 2 (`83e65b9`) : le propriétaire a tranché, elle est écrite maintenant et annonce l'écran
de choix des passifs pour plus tard. **Toujours pas taguée.** Métriques dans `progress.md`.

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

1. **P-41 lot B, partie 2 — l'identité de classe** (2026-09-18, **fusionné dans `main` par la
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
2. **P-41 lot B, partie 1 — la Puissance, une seule stat orientée par la classe**
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
3. **P-49 — passifs partagés, éligibilité déclarée par le passif et Maîtrise hybride**
   (2026-09-17, **fusionné dans `main` par la PR #39**, 11 commits,
   `a422544` → `4e937fa`) — chaque passif déclare ses classes éligibles (`classes`, absent = toutes)
   et ce qu'un point de Maîtrise lui apporte (`mastery`) ; `availablePassivesFor` devient l'unique
   point d'accès aux passifs d'une classe (sélection, tutoriel) ; `TraitSystem.dispatch` remplace
   les trois méthodes de trigger par un répartiteur sur `PassiveStrategies.byEffectType` (modèle
   ADR-061). La Maîtrise d'Armure devient la Maîtrise, sa récompense l'Affinité ; `StatGains` perd
   sa règle spéciale. Changement de jeu assumé : Armure du Berserker devient multiplicative avec la
   Maîtrise. 923 tests (+47), `dart analyze` propre. Voir [ADR-096](../_adr/ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md) (remplace la D4 d'ADR-086).
> [!NOTE]
> **Rotations.** La livraison sortie le 2026-09-18 (P-41 lot A) est conservée verbatim dans
> `../_archive/2026-09-18-activeContext-livraisons.md`. Les deux sorties le 2026-09-17 le sont dans
> `../_archive/2026-09-17-activeContext-livraisons-2.md` (P-40 bloc 2, cartes et forge) et
> `../_archive/2026-09-17-activeContext-livraisons.md` (éditeur de contenu, habillage). Les
> rotations précédentes : `../_archive/2026-09-16-activeContext-livraisons.md`,
> `../_archive/2026-09-15-activeContext-livraisons-2.md`,
> `../_archive/2026-09-15-activeContext-livraisons.md`,
> `../_archive/2026-09-14-activeContext-livraisons.md`,
> `../_archive/2026-09-05-activeContext-livraisons.md`,
> `../_archive/2026-09-01-activeContext-livraisons.md`,
> `../_archive/2026-08-25-activeContext-livraisons.md`,
> `../_archive/2026-08-23-activeContext-livraisons.md` et
> `../_archive/2026-08-20-activeContext-livraisons.md`.

## Prochaine étape

**P-41 lot C est le prochain chantier**, encore ni spécifié ni planifié. Son périmètre a gagné
l'**écran de choix du passif** : sans lui, six des neuf passifs livrés par le lot B restent
inatteignables, l'écran de sélection ne proposant que `passives.first` — et la note `0.5.2` a
désormais promis cet écran au joueur. Le reste du lot : récompenses de niveau data-driven
(indépendantes, parallélisables) et filtre d'*Affinité*. Il reste au propriétaire à **regarder
tourner le lot B** — les trois identités de classe ne se vérifient pas par la suite de tests. Le tag
`v0.5.2` attend cette campagne manuelle et P-42 ; le filtre de classe des cartes de signature se
traite avant ou avec P-42.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05. **P-07 doit lire [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md)
D6 avant de toucher aux animations.**
