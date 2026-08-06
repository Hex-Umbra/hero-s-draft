# Archive — progress.md, historique des releases (2026-08-06)

Lignes sorties du tableau « Historique des releases (10 dernières) » de
`../_memory_bank/progress.md` par débordement du plafond FIFO, lors de la synchronisation
du 6 août 2026 (livraison de P-02). Conservées verbatim. **Ne pas éditer.**

| Version | Date | Titre | Description des changements clés |
|:---|:---|:---|:---|
| **v0.2.7** | 2026-06-16 | Révision du Scaling et du Spawn des Ennemis | Révision des formules de génération des combats et de scaling de difficulté. Prise en compte du nombre de cartes du deck (`playerCardsCount * 2.0`) dans la puissance estimée du joueur. Ajustement du calcul du Combat Rating des ennemis (division par 4 des PV de base, multiplication par 2 des dégâts) pour encourager le spawn de plus d'ennemis. Augmentation des coefficients de croissance par acte (HP passe de 20% à 35%, dégâts de 15% à 25%). |

Décision correspondante — [ADR-066](../_adr/ADR-066-revision-du-scaling-de-difficulte-et-du-spawn-des.md).
