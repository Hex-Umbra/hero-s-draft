## 🛠️ ADR-047 : Résolution des Armures de Forge sur Attaque et Persistance/Visualisation du Gel (v0.1.6)

### Statut
✅ Accepté & Implémenté (v0.1.6)

### Contexte
1. L'amélioration d'armure de la forge (`hardened`), lorsqu'elle est appliquée à des cartes d'attaque (qui ne possèdent pas d'effet d'armure natif dans leurs `CardEffect`), ne produisait aucun bouclier en combat car la logique de résolution n'augmentait l'armure du héros que si la carte contenait déjà un effet d'armure natif.
2. Le statut de gel (`freeze`), destiné à diviser par deux les dégâts de la prochaine attaque de l'ennemi, expirait prématurément au début du tour de l'ennemi lors du déclenchement de `tickStatuses()`, avant que celui-ci ne puisse exécuter son action d'attaque.
3. L'affichage des intentions d'attaque de l'ennemi ne reflétait pas visuellement la réduction de 50% des dégâts lorsque celui-ci était gelé, créant une incohérence entre les dégâts affichés dans le HUD et les dégâts réellement subis par le héros à l'impact.

### Décision
1. **Application Directe d'Armure** : Modifier `EffectResolver.resolveCard` pour vérifier si la carte jouée possède de l'armure additionnelle issue de la forge (`extraArmor > 0`) et ne contient aucun effet d'armure natif. Si c'est le cas, appliquer directement cette `extraArmor` aux statistiques d'armure du héros via `runController.setHeroStats()`.
2. **Exemption du Gel au Début du Tour** : Modifier `tickStatuses()` dans `EntityStats` pour ignorer le statut `freeze`, lui évitant ainsi d'être décrémenté et dissipé au début du tour ennemi.
3. **Calcul Visuel de l'Intention Gelée** : Mettre à jour le getter `effectiveIntent` dans `EnemyInstance` pour diviser par deux (avec arrondi au plus proche) la valeur des dégâts de l'intention offensive lorsque l'ennemi possède le statut `freeze`.
4. **Consommation de l'Effet post-attaque** : Ajuster `resolveEnemyIntent` dans `CombatController` pour décrémenter de 1 la durée du statut de gel après la résolution de l'attaque de l'ennemi (puisqu'il a consommé son action offensive sous gel) tout en veillant à ne pas appliquer à nouveau la réduction de 50% (l'intention ayant déjà été pré-réduite par `effectiveIntent`).

### Preuves dans le code
- `lib/game/services/effect_resolver.dart` : Résolution directe d'armure si `extraArmor > 0` et absence d'effet d'armure.
- `lib/models/entity_stats.dart` : Ignorance du statut `freeze` dans la méthode `tickStatuses()`.
- `lib/models/enemy_instance.dart` : Division par deux de l'intention de dégâts d'attaque dans `effectiveIntent` si l'ennemi est gelé.
- `lib/game/controllers/combat_controller.dart` : Retrait de la double réduction dans `resolveEnemyIntent` et décrémentation de la durée du gel après l'action de l'ennemi.

### Conséquences
- ✅ **Comportement Fiable de la Forge** : Les joueurs peuvent désormais forger des cartes d'attaque avec de l'armure et bénéficier correctement de cette protection en combat.
- ✅ **Tactique du Gel Préservée** : Le gel réduit de manière effective la prochaine action offensive de l'ennemi au lieu d'expirer dans le vide au début de son tour.
- ✅ **Lisibilité de l'Intention** : La signalétique des intentions affiche en temps réel les dégâts exacts que le joueur subira (tenant compte du gel), améliorant la prise de décision stratégique.
- ✅ **Tests & Qualité** : Les 107 tests du projet s'exécutent avec succès et l'analyse statique de compilation est vierge.
