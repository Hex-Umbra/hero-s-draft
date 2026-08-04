## 🗺️ ADR-043 : Génération Dynamique du Goulot d'Étranglement Central (Dynamic Central Chokepoint Generation)

### Statut
✅ Accepté & Implémenté (v0.1.4)

### Contexte
L'algorithme de génération de carte procedural (`MapGeneratorService`) forçait un nœud unique de type Combat Élite au niveau 5 (chokepoint obligatoire). Cette valeur était codée en dur (`y == 5`), ce qui empêchait de modifier la hauteur globale de la carte (`floors`) pour des besoins de gameplay (ex: tutoriel court de 4 étages ou runs étendues de 15 étages).

### Décision
Calculer le goulot d'étranglement central de manière dynamique :
- Déterminer l'étage du milieu par la division entière de la hauteur totale : `middleFloor = floors ~/ 2`.
- Appliquer ce `middleFloor` dynamique dans `generateMap` pour forcer le chokepoint Élite unique.
- Adapter les fonctions de validation de quotas (`_balanceQuotas`) et d'anti-répétition (`_optimizeMapTypes` / `_hasThreeConsecutive`) pour exclure et protéger cet étage dynamique.

### Preuves dans le code
- `lib/services/map_generator_service.dart` : Remplacement de la constante `5` par `middleFloor` calculé via `floors ~/ 2` dans toutes les passes de traitement (génération, quotas, optimisation).

### Conséquences
- ✅ **Flexibilité Dimensionnelle** : Le moteur supporte désormais n'importe quelle taille de carte sans planter ni générer des topologies orphelines, tout en garantissant un affrontement Élite à mi-chemin.
