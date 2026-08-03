## 🛡️ ADR-049 : Correction de la Relique Croc Kunaï (v0.1.7)

### Statut
✅ Accepté & Implémenté (v0.1.7)

### Contexte
1. La relique Croc Kunaï (qui octroie +1 Maîtrise d'Armure toutes les 3 attaques jouées dans un tour) présentait un bug critique : son application altérait directement et définitivement la statistique `armorMastery` permanente du héros dans `RunState`. Cela entraînait une persistance anormale du bonus à l'issue du combat, faussant la courbe de puissance de l'armure pour le reste de la run.
2. Il manquait un mécanisme propre pour appliquer et agréger des bonus temporaires ou combat-longs de Maîtrise d'Armure sans modifier les attributs fondamentaux de la run.

### Décision
1. **Altération sous forme de StatusEffect** : Modifier le déclenchement de l'effet dans `RunController.applyRelicEffect` pour la clé `'charge_armor_mastery_combat'`. Au lieu de modifier la statistique permanente, le reset de la charge Kunaï applique désormais un `StatusEffect` avec l'identifiant `'armor_mastery'`, un type `StatusType.buff`, une valeur correspondant à `relic.value` (généralement 1) et une durée de 99 tours (couvrant l'intégralité du combat).
2. **Getter dynamique d'Armor Mastery** : Introduire une propriété calculée (getter) `effectiveArmorMastery` dans le modèle `EntityStats`. Ce getter parcourt la liste des statuts actifs, somme les valeurs des statuts ayant l'ID `'armor_mastery'`, et ajoute ce cumul à la valeur de base `armorMastery`.
3. **Substitution des calculs d'Armure** : Remplacer l'accès direct à la statistique brute `armorMastery` par le nouveau getter `effectiveArmorMastery` dans `RunController.addArmor()` et dans le système de passifs `TraitSystem` lors de la résolution de l'armure.

### Preuves dans le code
- `lib/models/entity_stats.dart` : Ajout du getter dynamique `effectiveArmorMastery` parcourant la liste `statuses`.
- `lib/game/controllers/run_controller.dart` : Remplacement de l'altération de stat brute par l'appel à `addStatus` d'un effet `'armor_mastery'` de 99 tours, et utilisation de `effectiveArmorMastery` pour le calcul de gain d'armure.
- `lib/game/systems/trait_system.dart` : Utilisation de `effectiveArmorMastery` dans les calculs de gains d'armure basés sur les passifs de classe (Berserker, Mage, Paladin).

### Conséquences
- ✅ **Intégrité de la Progression** : Le bonus de Maîtrise d'Armure octroyé par le Croc Kunaï est correctement confiné à la durée du combat actuel. Les statistiques du héros redeviennent nominales dès le combat résolu.
- ✅ **Structure Générique de Buffs** : Le pattern de statut d'armure temporaire est réutilisable pour d'autres reliques ou compétences futures.
- ✅ **Robustesse** : La validation des 107 tests du projet passe sans régression.
