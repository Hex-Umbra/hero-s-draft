# Archive — activeContext.md, livraisons (2026-08-20)

Livraison sortie de la liste « 3 dernières livraisons » de `../_memory_bank/activeContext.md`
par débordement du plafond FIFO, lors de la synchronisation du 20 août 2026 (livraison de
P-04). Conservée verbatim. **Ne pas éditer.**

3. **Réactivité du bouton « Continuer » de `HomeScreen`** (2026-07-26) — le bouton
   pouvait afficher un état obsolète après un retour via `Navigator.popUntil`
   (pause, défaite) car `HomeScreen` ne se reconstruisait pas et son
   `FutureProvider` sur `SaveService.hasSave()` n'était jamais réévalué. Correctif :
   `await` sur `Navigator.push` puis `setState(() {})` au retour. Voir
   [ADR-073](../_adr/ADR-073-reactivite-du-bouton-continuer-de-homescreen-apres.md).
