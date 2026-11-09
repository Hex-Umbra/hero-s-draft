---
description: Amends ADR-108 on what a wave tests — automated tests keep only what an agent that cannot play would not otherwise see (calculations, data loading and integrity, controllers, the save), no new screen test is written, what a screen test would have checked becomes a point of the wave's manual test file, and the existing screen tests were triaged file by file and removed in wave 5 (1916 to 1524 tests, six rules found unguarded and re-guarded)
---

# ADR-113 — Les Tests Gardent les Calculs et les Données, Plus Aucun Test d'Écran

### Statut

✅ Accepté — 2026-11-04, par le propriétaire (brainstorm v3, décision **D77**, de méthode), pendant la
vague 5, entre ses parties 2 et 3. **Amende
[ADR-108](ADR-108-methode-par-vagues-calibree-plans-de-decisions-sans-simulation.md)** pour ce qu'une
vague teste ; ADR-108 ne change que de Statut. Le tri des tests existants est appliqué sur la branche
`feat/v0.5.7-p42-tranche-1-p44-lot-1` — vague 5 du
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
en attente du test, de la PR, de la fusion et du tag du propriétaire — par trois commits
(`fa948c1a`, `27a55f2a`, `5fbbe63f`) ; la spec et le plan de la partie 3 sont repris sous elle
(`9c1a02a3`, `d125d597`). Le code de jeu (`lib/`, `assets/`) n'est pas touché par le tri.

### Contexte

À la fin de la partie 2 de la vague 5, la suite comptait 1916 tests, dont 556 dans `test/widget/`,
`test/tutorial/` et quelques fichiers de `test/unit/` qui figeaient de l'affichage : mise en page,
opacité, couleur, durée d'animation, texte affiché, présence d'un widget. Le plan de la partie 3 en
prescrivait une quarantaine de plus pour la barre de signatures et l'écran d'évolution. Ces tests
coûtaient à écrire, à vérifier et à réécrire à chaque retouche visuelle, et ce qu'ils gardaient, le
propriétaire le voit en jouant. Motif du propriétaire : « un jeu se teste à la main et non par des
programmes de tests » ; les tests de calcul restent, parce qu'un agent ne peut pas jouer.

### Décision

**D1 — Les tests automatiques gardent ce qu'un agent ne verrait pas autrement** : **les calculs**
(dégâts, statuts, coûts, stats, probabilités, XP), **les données** (chargement, intégrité
référentielle, conventions d'id, `sync_assets`), **les contrôleurs et la sauvegarde**.

**D2 — Plus aucun nouveau test d'écran**, à partir de la partie 3 de la vague 5. Ce qu'un test
d'écran aurait vérifié devient **un point du fichier de tests manuels** de la vague (ADR-108 D6) ;
une spec ou un plan n'en prescrit plus.

**D3 — Les tests d'écran existants sont triés fichier par fichier et supprimés dans la vague 5.**
Critère, test par test : « si ce test devenait rouge, le propriétaire le verrait-il tout de suite en
jouant à l'écran concerné ? » Oui : supprimé. Non — un chiffre faux de quelques pour cent, un cas
rare, une donnée corrompue, une sauvegarde perdue, une règle d'état — : gardé, ou réécrit en test de
calcul ou de contrôleur. Un test qui garde une règle que nul autre ne garde reste.

**D4 — Le tri est vérifié comme un document** : un vérificateur indépendant a relevé **six règles**
laissées sans garde par le premier passage ; deux sont réécrites en tests unitaires
(`completeCurrentNode`, les remèdes du *Colporteur*), quatre restaurées telles quelles (le retour
système de trois écrans, le plafond de rune relevé, le ciblage Flame sans rendu, l'affûtage du
*Rémouleur*). Deux ordres d'affichage gardés à tort sont supprimés à la seconde lecture.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| La décision du propriétaire | [brainstorm v3](../../docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md), §1, D77 |
| Le tri, fichier par fichier, ses cas limites et ses corrections | [rapport du tri](../../docs/superpowers/reports/2026-11-04-vague-5-tri-des-tests-d-ecran.md) |
| Les trois commits | `fa948c1a` (le tri), `27a55f2a` (corrections après vérification, six règles), `5fbbe63f` (l'ordre du draft de départ) |
| L'arrêt et sa levée | fichier d'orchestration, §2, « Arrêts », vague 5, 04/11 |
| Ce qui reste d'écran sous `test/widget/` | 11 fichiers et 2 sous `content_editor/` (**vérifié le 2026-11-04**, `ls test/widget`) : l'éditeur de contenu, dont l'écran *est* la logique, et les règles restaurées en D4 |
| Les points de tests manuels de la partie 3 | [spec](../../docs/superpowers/specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md), §9.1 (M7 à M34) |

### Conséquences

- **1916 → 1524 tests** au tri, puis 1612 à la fin de la partie 3, qui n'a ajouté que des tests de
  calcul, de donnée, de contrôleur et de sauvegarde (compte rendu §1).
- **Le fichier de tests manuels porte davantage** : le compteur de ❌ du propriétaire (ADR-108 D6)
  devient la seule mesure de ce que l'interface fait.
- **Du code de production reste sans test**, assumé : `parseBoldSegments`, l'opacité de
  `FloatingText`, `HerosDraftGame.handlePlayerTargeting`, le câblage `capBonus` de deux écrans hors
  des tests restaurés ; le soin du repos (`rest_screen.dart`) garde deux tests d'écran faute de
  fonction pure.
- **Les fiches du vault qui décrivaient des tests d'écran** comme pratique du projet sont alignées
  dans la même passe ([`_patterns/08-00`](../_patterns/08-00-conventions-de-code-standards-techniques.md)).
- **Ce qui ne change pas** : `dart analyze` propre et la suite verte à chaque tâche ; la preuve rouge
  avant le code pour un test de calcul (S15).
