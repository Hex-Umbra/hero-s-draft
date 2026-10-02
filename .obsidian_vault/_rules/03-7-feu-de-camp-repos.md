### 3.7. 🏕️ Feu de Camp / Repos (`RestScreen`)

Trois options interactives s'offrent au joueur sur l'écran `RestScreen`, **une seule par visite** :
1. **Repos** : Soigne 30% du HP maximum.
2. **Affûter** — à la place de l'ancienne forge depuis le lot E2 de P-43
   ([ADR-106](../_adr/ADR-106-fusion-egale-forge.md), branche de la vague 2, en attente du
   propriétaire) : **une rune d'une carte gagne un niveau, contre 50 or × son niveau**
   ([`_rules/03-8`](03-8-systeme-de-forge-forge-de-fusion.md) §3.8.5). L'option se montre **inactive,
   avec son motif**, quand aucune rune du deck ne peut monter (« Aucune rune de votre deck ne peut
   gagner de niveau. »). Elle ouvre l'écran de sélection de cartes, où **une carte sans rune
   affûtable est grisée et refusée au toucher**, avec son message ; puis un dialogue liste les runes
   de la carte, chacune avec ce que le niveau suivant lui ajoute et « Affûter — coût or », inactif au
   plafond (« Niveau maximal ») ou faute d'or. **Annuler ramène à la sélection** ; affûter ferme le
   dialogue et la sélection, et la visite est faite.
3. **Oubli** : Sélectionne une carte pour la supprimer définitivement du Master Deck.

**Une action faite, toute sortie résout le nœud.** Le bouton « Continuer » résout le nœud
(`completeCurrentNode`) ; depuis E2, **le retour système le fait aussi** dès qu'un repos, un
affûtage ou un oubli a eu lieu (`canPop: false` et `onPopInvokedWithResult`, qui appelle le même
`_leave`). Avant toute action, le retour reste bloqué. Jusque-là, revenir par le retour système
laissait le nœud non résolu, et la carte du monde permettait d'y rentrer pour un second repos ou un
second oubli — défaut fermé par le même mécanisme, et dit dans la note de version. L'état de visite
reste local à l'écran (`_actionTaken`).
