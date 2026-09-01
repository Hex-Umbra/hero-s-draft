# Archive — livraison sortie d'`activeContext.md` le 2026-09-01

Rotation FIFO du bloc « 3 dernières livraisons » : le chantier audio post-`0.5.0` y est
entré, la plus ancienne en est sortie. Bloc conservé **verbatim**, jamais réécrit.

3. **CI/CD et site vitrine — P-04** (2026-08-17 → 2026-08-20, publié en `0.4.8`) — livré en
   deux lots, **sans toucher au jeu**. *Lot 1* : trois workflows GitHub Actions, publication
   déclenchée par tag, garde-fou `verify-version` à trois fichiers, smoke test HTTP,
   annonce Discord — [ADR-079](../_adr/ADR-079-chaine-de-release-declenchee-par-tag-et-garde-fou.md).
   *Lot 2* : site vitrine piloté par `site/_site/versions.json`, testé par `node --test`
   (20 tests) — [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).
