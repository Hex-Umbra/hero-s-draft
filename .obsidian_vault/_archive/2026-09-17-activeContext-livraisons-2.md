# Archive — livraison sortie de `activeContext.md` le 2026-09-17 (2e rotation)

Rotation FIFO. La livraison **P-41 lot B, partie 1 — la Puissance orientée par la classe**
(2026-09-17, branche `feat/p41-lot-b-puissance`) entre dans `activeContext.md` ; celle ci-dessous
en sort, conservée **verbatim**, numérotation comprise.

> [!WARNING]
> Lecture seule. Ces textes décrivent l'état du projet à la date où ils ont été écrits.

---

3. **P-40 bloc 2 — cartes et forge** (2026-09-15, branche `fix/p40-bloc-2` **fusionnée par la
   PR #37**, 11 commits de code et de
   test, `b19b39a` → `9196a6e`) — une carte de classe porte 5 runes et non plus 10 ; trois
   légendaires ne fusionnent plus en une `unique`, et une carte ainsi abîmée redevient légendaire
   au chargement ; ni le draft de boss ni les deux Miroirs ne
   copient plus une carte de classe ; Persistant retire l'épuisement à tout tier et ne se fusionne
   plus. Trois causes plutôt que quatre symptômes : l'échelle de rareté devient `CardRarity.next` et
   `forgeSlotBonus` au lieu de l'ordre de l'enum, la règle d'acquisition `CardRarity.isAcquirable`,
   et une rune se déclare `stackable: false` en donnée, lue par un service unique, `ForgeRuneRules`
   ([ADR-094](../_adr/ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md)). 811 tests,
   38 de plus ; la revue a vérifié que les tests de régression échouent sur l'ancien code.
