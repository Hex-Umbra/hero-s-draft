### 3.7. 🏕️ Feu de Camp / Repos (`RestScreen`)

Trois options interactives s'offrent au joueur sur l'écran `RestScreen` :
1. **Repos** : Soigne 30% du HP maximum.
2. **Forge** : Ouvre un écran de sélection de cartes. Lors de la sélection d'une carte, ouvre la boîte de dialogue `ForgeUpgradeDialog` pour appliquer des améliorations probabilistes permanentes, consommant de l'or. **Correction de navigation** : Si le joueur annule la forge (en fermant le dialogue), il est reconduit à l'écran de sélection de cartes pour changer de cible au lieu d'être renvoyé directement au menu du repos. **L'écran de sélection refuse deux cartes**, chacune avec son message, sans ouvrir la forge : une carte pleine (sa capacité de runes atteinte), et une carte à laquelle **aucune rune ne peut plus être ajoutée** — « Aucune rune ne peut être ajoutée à cette carte. » ([`_rules/03-8`](03-8-systeme-de-forge-forge-de-fusion.md), [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md)).
3. **Oubli** : Sélectionne une carte pour la supprimer définitivement du Master Deck.
