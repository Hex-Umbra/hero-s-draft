# Archive — livraison sortie d'`activeContext.md` le 2026-09-18

Rotation FIFO à 3 livraisons. L'arrivée de **P-41 lot B, partie 2 — l'identité de classe** a poussé
l'entrée ci-dessous hors du fichier vivant. Texte conservé **verbatim** : chiffres, dates et
affirmations sont ceux du 2026-09-17 et ne doivent pas être corrigés.

---

3. **P-41 lot A — passage unique des gains, scission des puissances, migration de sauvegarde**
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
