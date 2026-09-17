<!-- last-sync: 2026-09-17 | commit: 56be78d -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**P-49 (passifs partagés) est fusionné dans `main`** par la PR #39 (2026-09-17, merge `56be78d`,
détail en « 3 dernières livraisons ») : chaque passif déclare ses classes éligibles et sa Maîtrise,
lus par un point d'accès unique et un répartiteur de stratégies — voir
[ADR-096](../_adr/ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md), qui remplace la D4
d'ADR-086. La note `0.5.2` a été rouverte en place pour l'absorber (`5f168db`), **toujours pas
taguée**. Les métriques de `main` sont dans `progress.md`.

Le programme « Identité de classe & catalogue » continue avec **P-41 lot B**, dont les deux dépendances,
le lot A et P-49, sont fusionnées. Sa conception a été **reprise le 2026-09-17** : une Puissance unique,
`might`, que la classe oriente, remplace les trois puissances du lot A, et le lot se livre en deux
parties ([spec, §0.3 et §7](../../docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md)).
Aucun plan encore.

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

1. **P-49 — passifs partagés, éligibilité déclarée par le passif et Maîtrise hybride**
   (2026-09-17, **fusionné dans `main` par la PR #39**, 11 commits,
   `a422544` → `4e937fa`) — chaque passif déclare ses classes éligibles (`classes`, absent = toutes)
   et ce qu'un point de Maîtrise lui apporte (`mastery`) ; `availablePassivesFor` devient l'unique
   point d'accès aux passifs d'une classe (sélection, tutoriel) ; `TraitSystem.dispatch` remplace
   les trois méthodes de trigger par un répartiteur sur `PassiveStrategies.byEffectType` (modèle
   ADR-061). La Maîtrise d'Armure devient la Maîtrise, sa récompense l'Affinité ; `StatGains` perd
   sa règle spéciale. Changement de jeu assumé : Armure du Berserker devient multiplicative avec la
   Maîtrise. 923 tests (+47), `dart analyze` propre. Voir [ADR-096](../_adr/ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md) (remplace la D4 d'ADR-086).
2. **P-41 lot A — passage unique des gains, scission des puissances, migration de sauvegarde**
   (2026-09-16, **fusionné dans `main` par la PR #38**, branche `feat/p41-lot-a` supprimée, 10 commits,
   `674545c` → `b94c854`) — `StatGains.apply` devient le seul point de passage d'un gain d'armure,
   de mana ou de puissance, étiqueté par sa source (`GainSource`) ; la Maîtrise d'Armure ne s'ajoute
   qu'aux gains passifs, comportement préservé et désormais verrouillé par un guard test.
   `attaque` devient `attackPower`, rejoint par `skillPower` et `alterationPower` (à 0) ; `PowerRules`
   décide quelle puissance renforce quelle carte — aucun effet visible aujourd'hui. `SaveMigrator`
   pose la première chaîne de migration du projet ; le jeu écrit désormais sous la clé `run_save`
   (repli sur `run_save_v1`) et ne détruit plus jamais une sauvegarde écrite par un build plus récent,
   conservée avec un message à l'accueil. 876 tests (+65), `dart analyze` propre. Voir
   [ADR-095](../_adr/ADR-095-passage-unique-des-gains-scission-des-puissances-et.md).
3. **P-40 bloc 2 — cartes et forge** (2026-09-15, branche `fix/p40-bloc-2` **fusionnée par la
   PR #37**, 11 commits de code et de
   test, `b19b39a` → `9196a6e`) — une carte de classe porte 5 runes et non plus 10 ; trois
   légendaires ne fusionnent plus en une `unique`, et une carte ainsi abîmée redevient légendaire
   au chargement ; ni le draft de boss ni les deux Miroirs ne
   copient plus une carte de classe ; Persistant retire l'épuisement à tout tier et ne se fusionne
   plus. Trois causes plutôt que quatre symptômes : l'échelle de rareté devient `CardRarity.next` et
   `forgeSlotBonus` au lieu de l'ordre de l'enum, la règle d'acquisition `CardRarity.isAcquirable`,
   et une rune se déclare `stackable: false` en donnée, lue par un service unique, `ForgeRuneRules`
   ([ADR-094](../_adr/ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md)). 811 tests,
   38 de plus ; la revue a vérifié que les tests de régression échouent sur l'ancien code.

> [!NOTE]
> **Rotations.** La livraison sortie le 2026-09-17 (éditeur de contenu, habillage) est conservée
> verbatim dans `../_archive/2026-09-17-activeContext-livraisons.md`. Les rotations précédentes :
> `../_archive/2026-09-16-activeContext-livraisons.md`,
> `../_archive/2026-09-15-activeContext-livraisons-2.md`,
> `../_archive/2026-09-15-activeContext-livraisons.md`,
> `../_archive/2026-09-14-activeContext-livraisons.md`,
> `../_archive/2026-09-05-activeContext-livraisons.md`,
> `../_archive/2026-09-01-activeContext-livraisons.md`,
> `../_archive/2026-08-25-activeContext-livraisons.md`,
> `../_archive/2026-08-23-activeContext-livraisons.md` et
> `../_archive/2026-08-20-activeContext-livraisons.md`.

## Prochaine étape

**Écrire le plan de la partie 1 du lot B de P-41** : la Puissance, `might`, à comportement identique
([spec, §7.6](../../docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md)). Le tag
`v0.5.2` — seul geste déclenchant
`release.yml` — attend toujours P-42 et la campagne de test manuelle du propriétaire. Le filtre de
classe des cartes de signature se traite avant ou avec P-42 — sa réserve ci-dessus dit où et
combien.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05. **P-07 doit lire [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md)
D6 avant de toucher aux animations.**
