# Archive — livraisons sorties de `activeContext.md` le 2026-09-05

Rotation FIFO. Trois livraisons **P-48 lot 3**, **P-48 lots 1-2** et **P-40 bloc 1** entrent
dans `activeContext.md` ; les trois ci-dessous en sortent, conservées **verbatim**.

> [!WARNING]
> Lecture seule. Ces textes décrivent l'état du projet à la date où ils ont été écrits.

---

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
