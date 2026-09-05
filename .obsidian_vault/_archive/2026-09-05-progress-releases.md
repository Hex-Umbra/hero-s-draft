# Archive — historique des releases sorti de `progress.md` le 2026-09-05

Rotation FIFO du tableau `## 4. Historique des releases (10 dernières)` de
`_memory_bank/progress.md` : l'entrée `0.5.1` y est entrée, la plus ancienne en est
sortie. Ligne conservée **verbatim**, jamais réécrite.

| Version | Date | Titre | Description des changements clés |
|:---|:---|:---|:---|
| **v3.1.0** | 2026-07-01 | Forge de Fusion et Forge Data-Driven | Introduction du nœud Forge de Fusion (`MapNodeType.forgeFusion` à 25% de chance) sur les étages 3 à 7. Écran `ForgeFusionScreen` pour fusionner les runes identiques pour un coût de 80 Or. Remplacement des upgrades codés en dur par une structure data-driven (`assets/data/forge_upgrades.json` + `ForgeUpgradeData`). Cumul de runes sans épuisement (alreadyHas retiré). Correction de la navigation au repos : annuler la forge ramène à la sélection de cartes au lieu de quitter au menu du repos. Écriture de tests unitaires (112 tests réussis, 0 erreur). |
