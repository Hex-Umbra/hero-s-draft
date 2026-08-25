<!-- last-sync: 2026-08-25 | commit: 708f34d -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**Le Jalon 1 « Socle » est clos.** P-01, P-02, P-04 et désormais **P-03 (audio)** sont tous
livrés — `docs/ROADMAP.md` §9. Publier une version se réduit à poser un tag `v*.*.*`, **mais
seulement après** que le skill `patch-notes-writer` a déplacé ensemble les trois fichiers qui
portent le numéro : sinon `verify-version` échoue avant le moindre build. Ce n'est pas une
panne, c'est le garde-fou.

**P-03 est livré en code et en documentation, pas encore en version.** Branche
`feat/p03-systeme-audio`, pas encore mergée dans `main`. `patch-notes-writer` n'a
**délibérément pas** été invoqué : le catalogue audio reste troué, et une note joueur
annoncerait un son que personne ne peut encore entendre — comportement voulu, voir
[ADR-082](../_adr/ADR-082-directeur-audio-central-et-mapping-par-donnees.md) D5. État du
sourcing : `docs/ROADMAP.md` (P-03) ; décompte vivant via `flutter test
test/unit/audio/audio_sourcing_report_test.dart --reporter expanded`.
**Invoquer `patch-notes-writer` une fois le catalogue comblé, pas avant.**

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
  qui citent la version en toutes lettres — cause vivant dans le skill, non corrigée,
  découverte le 2026-08-23 et corrigée ponctuellement à cette date seulement.

## 3 dernières livraisons

1. **Système audio — P-03** (2026-08-25, branche `feat/p03-systeme-audio`, pas encore
   publié) — un directeur central (`AudioDirector.onMoment`/`MusicConductor.onScene`)
   résout un moment de jeu ou une scène musicale en son via `assets/data/audio.json`, chaîne
   de repli à 4 niveaux (son propre à l'entité → type d'animation → défaut → silence), sans
   qu'aucun appelant ne nomme jamais un fichier. 14 moments branchés dans 8 fichiers,
   musique par scène avec déverrouillage autoplay web, écran de réglages et coupure HUD
   persistés hors de `SaveService`. `SilentAudioBackend` par défaut : les 295 tests
   existants n'ont pas bougé (354 aujourd'hui, +59 neufs pour l'audio). Voir
   [ADR-082](../_adr/ADR-082-directeur-audio-central-et-mapping-par-donnees.md),
   [`_rules/09-00`](../_rules/09-00-systeme-audio.md) et
   [`_patterns/16-00`](../_patterns/16-00-architecture-du-systeme-audio.md).
2. **Fidélité du tutoriel — P-45** (2026-08-23, publié en `0.4.9`) — un audit avait relevé
   **50 écarts** entre `lib/tutorial/` et le jeu réel, nés d'une règle d'autonomie qui
   interdisait au tutoriel de lire même les données immuables du jeu, forçant une recopie
   manuelle qui a dérivé. La règle devient « zéro provider d'*état* » plutôt que « zéro
   Riverpod » : `gameDataLoaderProvider` est désormais autorisé en un point unique,
   `tutorial_loader.dart`, critère vérifié par `test/tutorial/tutorial_isolation_test.dart`.
   Le parcours passe de 13 à **15 étapes**. Voir
   [ADR-081](../_adr/ADR-081-amendement-autonomie-tutoriel-zero-provider-etat.md),
   [`_rules/08-00`](../_rules/08-00-systeme-de-tutoriel-autonome.md) et
   [`_patterns/09-00`](../_patterns/09-00-architecture-du-systeme-de-tutoriel-autonome.md).
   **Deux correctifs de jeu sans rapport ont rejoint le même tag par la PR #28** : le
   panneau d'intentions ennemies débordait de sa largeur fixe, et la Forge d'Acier
   légendaire rendait +1 Maîtrise d'Armure au lieu de +7 — table des 30 valeurs désormais
   dans [`_rules/06-00`](../_rules/06-00-economie-de-jeu.md).
3. **CI/CD et site vitrine — P-04** (2026-08-17 → 2026-08-20, publié en `0.4.8`) — livré en
   deux lots, **sans toucher au jeu**. *Lot 1* : trois workflows GitHub Actions, publication
   déclenchée par tag, garde-fou `verify-version` à trois fichiers, smoke test HTTP,
   annonce Discord — [ADR-079](../_adr/ADR-079-chaine-de-release-declenchee-par-tag-et-garde-fou.md).
   *Lot 2* : site vitrine piloté par `site/_site/versions.json`, testé par `node --test`
   (20 tests) — [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

> [!NOTE]
> **Rotations.** La livraison sortie au 2026-08-25 (assainissement de la pioche, P-02,
> ADR-078) est conservée verbatim dans
> `../_archive/2026-08-25-activeContext-livraisons.md`. Celle sortie au 2026-08-23 (refonte
> documentaire du memory bank, 2026-08-03) est dans
> `../_archive/2026-08-23-activeContext-livraisons.md`. Celle sortie au 2026-08-20
> (réactivité du bouton « Continuer », ADR-073) est dans
> `../_archive/2026-08-20-activeContext-livraisons.md`.

## Prochaine étape

Jalon 1 « Socle » clos : ~~P-01~~ ✅, ~~P-02~~ ✅, ~~P-04~~ ✅, ~~P-03~~ ✅. Prochain jalon —
Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) : P-06 (lot P0 animations), puis P-07, le
prototype de P-08, et P-05. Suivi indépendant de ce séquencement : combler le sourcing audio
de P-03, puis invoquer `patch-notes-writer` pour publier la version.
