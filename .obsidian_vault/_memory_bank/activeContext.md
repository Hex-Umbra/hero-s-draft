<!-- last-sync: 2026-08-20 | commit: 6fd4c61 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**P-04 est clos** — les deux lots sont livrés, mergés et vérifiés en production. Publier une
version se réduit désormais à poser un tag `v*.*.*`, **mais seulement après** que le skill
`patch-notes-writer` a déplacé ensemble les trois fichiers qui portent le numéro : sinon
`verify-version` échoue avant le moindre build. Ce n'est pas une panne, c'est le garde-fou.

Le Jalon 1 « Socle » n'a plus qu'un chantier ouvert : **P-03 (audio)** — le plus gros gain
de game feel par heure investie du projet selon l'audit du 25/07. Son chemin critique est
le sourcing (~15 bruitages, 4 musiques), pas le code.

Trois réserves à ne pas perdre de vue :

- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04). Les traiter comme non vérifiés. Inchangé
  depuis le 2026-08-06.
- **Le webhook Discord a transité en clair** pendant la conception du 19/08 et n'a pas été
  régénéré depuis.
- **Bouton de téléchargement mort** : si le build Windows échoue quand le build web
  réussit, le site affiche un lien vers un asset absent. Correctif identifié, non fait —
  voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **CI/CD et site vitrine — P-04** (2026-08-17 → 2026-08-20, publié en `0.4.8`) — livré en
   deux lots, **sans toucher au jeu** : aucun fichier de `lib/`, `test/` ou `assets/` n'a
   changé. *Lot 1* : trois workflows GitHub Actions, publication déclenchée par tag,
   garde-fou `verify-version` comparant le tag à `pubspec.yaml`, `patch_notes.json` et
   `versions.json` avant tout build, smoke test HTTP post-déploiement, pré-release avec le
   zip Windows, annonce Discord. Cinq scripts shell testables, harnais à **55 assertions**
   — [ADR-079](../_adr/ADR-079-chaine-de-release-declenchee-par-tag-et-garde-fou.md).
   *Lot 2* : la page de sélection des versions quitte `../Prototypes/Web/` pour `site/`,
   pilotée par `site/_site/versions.json`, sans étape de build ni dépendance npm, logique
   pure testée par `node --test` (**20 tests**) —
   [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).
   Le 20/08, les quatorze dates historiques ont été relevées sur l'archive locale des
   builds et deux jointures déclarées (`v0.0.5` → note `0.0.4`, `v0.0.9` → note `0.0.93`).
2. **Assainissement du système de pioche — P-02** (2026-08-06) — le remélange de la défausse
   devient automatique et n'intervient plus qu'une fois la pioche réellement vide (l'ancien
   seuil `< 5` détruisait la capacité à compter son deck) ; la pioche s'arrête net sur main
   pleine sans rien consommer ; `TurnPhaseManager` gagne `startPlayerCombat()` /
   `startPlayerTurn()`, de sorte que le tour 1 et le tour N+1 empruntent enfin le même code ;
   l'aléatoire devient injectable et six éléments de code mort disparaissent. Première
   relique touchant au deck (`scholars_satchel`). **+18 tests neufs, 2 réécrits** — la
   ROADMAP en annonçait 6. Voir
   [ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md).
3. **Refonte documentaire du memory bank** (2026-08-03, mergée via PR #23) — `decisionLog.md`
   (2704 lignes), `systemPatterns.md` (1478) et `productContext.md` (807) sont
   devenus des index adossés à des fiches adressables sous `../_adr/`,
   `../_patterns/` et `../_rules/` ; `progress.md` a été réécrit sur des métriques
   re-mesurées. Pour les tailles courantes, lire les fichiers — ce document ne les
   réénonce pas. Design : `docs/superpowers/specs/2026-08-03-documentation-overhaul-design.md`.

> [!NOTE]
> **Rotations.** La livraison sortie au 2026-08-20 (réactivité du bouton « Continuer »,
> ADR-073) est conservée verbatim dans `../_archive/2026-08-20-activeContext-livraisons.md`.
> Celle sortie au 2026-08-06 (accélération de la cadence du scaling, ADR-072) n'avait pas
> été ré-archivée : son détail figure déjà verbatim dans
> `../_archive/2026-08-03-activeContext-journal.md` §2.1.

## Prochaine étape

Voir `docs/ROADMAP.md` — Jalon 1 « Socle » : ~~P-01~~ ✅, ~~P-02~~ ✅, ~~P-04~~ ✅, puis P-03.
