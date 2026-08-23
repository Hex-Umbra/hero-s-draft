<!-- last-sync: 2026-08-23 | commit: 3045971 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**P-04 et P-45 sont clos.** Publier une version se réduit désormais à poser un tag `v*.*.*`,
**mais seulement après** que le skill `patch-notes-writer` a déplacé ensemble les trois
fichiers qui portent le numéro : sinon `verify-version` échoue avant le moindre build. Ce
n'est pas une panne, c'est le garde-fou. Depuis le 2026-08-23, le titre cliquable de
l'annonce Discord mène au **site vitrine** et non plus au build jouable — cliquer un titre
est un geste de curiosité, pas une intention de lancer une partie. Le champ « Jouer » reste,
lui, la porte d'entrée du jeu.

Le Jalon 1 « Socle » n'a plus qu'un chantier ouvert : **P-03 (audio)** — le plus gros gain
de game feel par heure investie du projet selon l'audit du 25/07. Son chemin critique est
le sourcing (~15 bruitages, 4 musiques), pas le code. P-45 (Tier A) était hors de ce
séquencement — un chantier de fidélité documentaire/tutoriel mené en parallèle.

Quatre réserves à ne pas perdre de vue :

- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04). Les traiter comme non vérifiés. Inchangé
  depuis le 2026-08-06.
- **Le webhook Discord a transité en clair** pendant la conception du 19/08 et n'a pas été
  régénéré depuis.
- **Bouton de téléchargement mort** : si le build Windows échoue quand le build web
  réussit, le site affiche un lien vers un asset absent. Correctif identifié, non fait —
  voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).
- **`patch-notes-writer` ne rafraîchit que les `href` de repli, pas les libellés visibles**
  qui citent la version en toutes lettres. Découvert le 2026-08-23 : à la sortie de `0.4.9`,
  `site/index.html` liait déjà `/v0.4.9/` mais affichait encore le libellé `0.4.7`, un
  décalage présent depuis au moins `0.4.8`. Les libellés trouvés ont été corrigés
  ponctuellement à cette date, mais la cause vit dans le skill et se reproduira à la
  prochaine release tant qu'il n'est pas corrigé pour les couvrir aussi.

## 3 dernières livraisons

1. **Fidélité du tutoriel — P-45** (2026-08-23, publié en `0.4.9`) — un audit avait relevé
   **50 écarts** entre `lib/tutorial/` et le jeu réel, nés d'une règle d'autonomie qui
   interdisait au tutoriel de lire même les données immuables du jeu, forçant une recopie
   manuelle qui a dérivé. La règle devient « zéro provider d'*état* » plutôt que « zéro
   Riverpod » : `gameDataLoaderProvider` est désormais autorisé en un point unique,
   `tutorial_loader.dart`, critère vérifié par `test/tutorial/tutorial_isolation_test.dart`.
   Le parcours passe de 13 à **15 étapes** (choix de classe et draft du deck de départ
   ajoutés en amont, verrouillés une fois franchis). Correctif d'affichage inclus : la
   légende de la carte du monde annonçait « Boss (XP & Or x2) », le jeu applique `×3`
   depuis longtemps — seul l'affichage a changé. Voir
   [ADR-081](../_adr/ADR-081-amendement-autonomie-tutoriel-zero-provider-etat.md),
   [`_rules/08-00`](../_rules/08-00-systeme-de-tutoriel-autonome.md) et
   [`_patterns/09-00`](../_patterns/09-00-architecture-du-systeme-de-tutoriel-autonome.md).
   **Deux correctifs de jeu sans rapport ont rejoint le même tag par la PR #28, et la note
   joueur `0.4.9` ne les décrit pas** : le panneau d'intentions ennemies débordait de sa
   largeur fixe et peignait la bande d'erreur en plein HUD, et la Forge d'Acier légendaire
   rendait +1 Maîtrise d'Armure — la valeur d'un commun — au lieu de +7. La table des 30
   valeurs de récompense, dont l'absence avait laissé le trou invisible, est désormais
   écrite dans [`_rules/06-00`](../_rules/06-00-economie-de-jeu.md).
2. **CI/CD et site vitrine — P-04** (2026-08-17 → 2026-08-20, publié en `0.4.8`) — livré en
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
3. **Assainissement du système de pioche — P-02** (2026-08-06) — le remélange de la défausse
   devient automatique et n'intervient plus qu'une fois la pioche réellement vide (l'ancien
   seuil `< 5` détruisait la capacité à compter son deck) ; la pioche s'arrête net sur main
   pleine sans rien consommer ; `TurnPhaseManager` gagne `startPlayerCombat()` /
   `startPlayerTurn()`, de sorte que le tour 1 et le tour N+1 empruntent enfin le même code ;
   l'aléatoire devient injectable et six éléments de code mort disparaissent. Première
   relique touchant au deck (`scholars_satchel`). **+18 tests neufs, 2 réécrits** — la
   ROADMAP en annonçait 6. Voir
   [ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md).

> [!NOTE]
> **Rotations.** La livraison sortie au 2026-08-23 (refonte documentaire du memory bank,
> 2026-08-03) est conservée verbatim dans
> `../_archive/2026-08-23-activeContext-livraisons.md`. Celle sortie au 2026-08-20
> (réactivité du bouton « Continuer », ADR-073) est conservée verbatim dans
> `../_archive/2026-08-20-activeContext-livraisons.md`. Celle sortie au 2026-08-06
> (accélération de la cadence du scaling, ADR-072) n'avait pas été ré-archivée : son détail
> figure déjà verbatim dans `../_archive/2026-08-03-activeContext-journal.md` §2.1.

## Prochaine étape

Voir `docs/ROADMAP.md` — Jalon 1 « Socle » : ~~P-01~~ ✅, ~~P-02~~ ✅, ~~P-04~~ ✅, puis P-03.
Hors séquencement : ~~P-45~~ ✅ (Tier A, fidélité du tutoriel).
