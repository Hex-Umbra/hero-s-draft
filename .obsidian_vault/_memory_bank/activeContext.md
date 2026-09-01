<!-- last-sync: 2026-09-01 | commit: 5a0a81d -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**Le Jalon 1 « Socle » est clos.** P-01, P-02, P-04 et désormais **P-03 (audio)** sont tous
livrés — `docs/ROADMAP.md` §9. Publier une version se réduit à poser un tag `v*.*.*`, **mais
seulement après** que le skill `patch-notes-writer` a déplacé ensemble les trois fichiers qui
portent le numéro : sinon `verify-version` échoue avant le moindre build. Ce n'est pas une
panne, c'est le garde-fou.

**P-03 est livré et publié en `0.5.0`.** La branche `feat/p03-systeme-audio` est **fusionnée
dans `main`** (PR #30), suivie de deux correctifs sans rapport entre eux (PR #31, PR #32).
`patch-notes-writer` n'avait **délibérément pas** été invoqué tant que le catalogue restait
vide : une note joueur aurait annoncé des sons que personne ne pouvait entendre — voir
[ADR-082](../_adr/ADR-082-directeur-audio-central-et-mapping-par-donnees.md) D5. **Le motif est
tombé le 2026-08-28** : les 19 bruitages sont posés, chaque `GameMoment` a son son, et les
trois livraisons partagent enfin le même numéro. Les bruitages sont passés en WAV, la musique
reste en MP3 — [`_rules/09-00`](../_rules/09-00-systeme-audio.md) §9.3.
**La note `0.5.0` couvre tout le chantier audio**, sourcing et chemin de lecture compris :
elle a été écrite avant les sept commits qui ont suivi, puis rouverte pour les intégrer, la
version n'ayant jamais été taguée entre-temps. C'est la seule fois où une entrée de
`patch_notes.json` a été rouverte, et c'est légitime : personne ne l'avait encore vue.
`0.4.9` reste la dernière version réellement distribuée. Les 4 musiques sortent vers le
chantier **P-46** ; décompte vivant via
`flutter test test/unit/audio/audio_sourcing_report_test.dart --reporter expanded`.

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
  qui citent la version en toutes lettres — cause vivante dans le skill, non corrigée.
  Contournée à la main aux **deux** dernières publications (2026-08-23 puis 2026-08-28) :
  `site/index.html` porte le numéro en clair dans sa carte de version et doit être repris
  à chaque fois. Le contournement répété est le symptôme, pas le remède.

## 3 dernières livraisons

1. **Chemin de lecture audio — latence, disponibilité, synchronisation** (2026-08-29,
   branche `feat/audio-bruitages-en-wav`, replié dans la note `0.5.0`) — le moteur de P-03 était
   livré et testé, mais personne ne l'avait jamais *entendu* : le sourcing a révélé quatre
   défauts que le vert des tests ne pouvait pas voir. Les bruitages passent par un réservoir
   de lecteurs pré-armés au lieu d'allouer un lecteur natif et quatre allers-retours de canal
   par son ; une piste manquante devient silencieuse au lieu de bruyante ; le système est
   réveillé au lancement, sans quoi le premier son de la session était toujours perdu ; et le
   son de conséquence tombe sur la **frappe d'impact** de l'animation, plus à sa fin. Le
   catalogue passe de 14 à **22 moments** et de 19 à **31 bruitages**. Voir
   [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md),
   [`_rules/09-1`](../_rules/09-1-catalogue-des-moments.md) et
   [`_patterns/16-00`](../_patterns/16-00-architecture-du-systeme-audio.md) §16.7.
   ⚠️ **Le retiming n'est couvert par aucun test** — le dépôt n'a pas `flame_test`.
2. **Système audio — P-03** (2026-08-25, PR #30, **publié en `0.5.0`** le 2026-08-28 avec son
   sourcing) — un directeur central (`AudioDirector.onMoment`/`MusicConductor.onScene`)
   résout un moment de jeu ou une scène musicale en son via `assets/data/audio.json`, chaîne
   de repli à 4 niveaux (son propre à l'entité → type d'animation → défaut → silence), sans
   qu'aucun appelant ne nomme jamais un fichier. 14 moments branchés dans 8 fichiers,
   musique par scène avec déverrouillage autoplay web, écran de réglages et coupure HUD
   persistés hors de `SaveService`. `SilentAudioBackend` par défaut : les 295 tests
   existants n'ont pas bougé (369 aujourd'hui — décomposition dans `progress.md`
   §Métriques). Voir
   [ADR-082](../_adr/ADR-082-directeur-audio-central-et-mapping-par-donnees.md),
   [`_rules/09-00`](../_rules/09-00-systeme-audio.md) et
   [`_patterns/16-00`](../_patterns/16-00-architecture-du-systeme-audio.md).
   **Deux correctifs sans rapport ont suivi le même jour** : *(PR #31)* deux débordements
   de `RenderFlex` — `StatusEffectsPanel`, jumeau oublié du panneau corrigé par la PR #28,
   et une troisième copie manuscrite du même motif dans
   `tutorial_combat_overview_widget.dart` ; le test qui aurait dû les voir avalait
   l'exception par un `takeException()` sans assertion. *(PR #32)* le compte de callbacks
   de `HerosDraftGame` dans [`_patterns/04-00`](../_patterns/04-00-synchronisation-bidirectionnelle-flame-riverp.md),
   annoncé à 16 depuis dix-neuf jours, ramené à 14.
3. **Fidélité du tutoriel — P-45** (2026-08-23, publié en `0.4.9`) — un audit avait relevé
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
> [!NOTE]
> **Rotations.** La livraison sortie au 2026-09-01 (CI/CD et site vitrine, P-04, ADR-079 et
> ADR-080) est conservée verbatim dans
> `../_archive/2026-09-01-activeContext-livraisons.md`. Les trois rotations précédentes sont
> dans `../_archive/2026-08-25-activeContext-livraisons.md`,
> `../_archive/2026-08-23-activeContext-livraisons.md` et
> `../_archive/2026-08-20-activeContext-livraisons.md`.

## Prochaine étape

Jalon 1 « Socle » clos : ~~P-01~~ ✅, ~~P-02~~ ✅, ~~P-04~~ ✅, ~~P-03~~ ✅. Prochain jalon —
Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) : P-06 (lot P0 animations), puis P-07, le
prototype de P-08, et P-05. **P-07 doit lire [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md) D6 avant de toucher aux animations** :
la frappe d'impact y est déjà posée, et `spawnImpactParticles` l'attend, déclarée et jamais
appelée. **P-03 est clos** : `v0.5.0` est taguée sur `main` et déployée, les neuf jobs de
`release.yml` au vert. Ce qui reste du son part en deux chantiers indépendants du
séquencement — les 4 musiques (**P-46**) et la seconde passe de couverture et de mixage
(**P-47**).
