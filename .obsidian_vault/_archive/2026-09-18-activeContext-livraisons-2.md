# Archive — livraison sortie d'`activeContext.md` le 2026-09-18 (2)

Rotation FIFO à 3 livraisons. L'arrivée de **P-41 lot C, partie 1 — les récompenses de niveau en
donnée** a poussé l'entrée ci-dessous hors du fichier vivant. Texte conservé **verbatim** : chiffres,
dates et affirmations sont ceux du 2026-09-17 et ne doivent pas être corrigés.

---

3. **P-49 — passifs partagés, éligibilité déclarée par le passif et Maîtrise hybride**
   (2026-09-17, **fusionné dans `main` par la PR #39**, 11 commits,
   `a422544` → `4e937fa`) — chaque passif déclare ses classes éligibles (`classes`, absent = toutes)
   et ce qu'un point de Maîtrise lui apporte (`mastery`) ; `availablePassivesFor` devient l'unique
   point d'accès aux passifs d'une classe (sélection, tutoriel) ; `TraitSystem.dispatch` remplace
   les trois méthodes de trigger par un répartiteur sur `PassiveStrategies.byEffectType` (modèle
   ADR-061). La Maîtrise d'Armure devient la Maîtrise, sa récompense l'Affinité ; `StatGains` perd
   sa règle spéciale. Changement de jeu assumé : Armure du Berserker devient multiplicative avec la
   Maîtrise. 923 tests (+47), `dart analyze` propre. Voir [ADR-096](../_adr/ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md) (remplace la D4 d'ADR-086).
