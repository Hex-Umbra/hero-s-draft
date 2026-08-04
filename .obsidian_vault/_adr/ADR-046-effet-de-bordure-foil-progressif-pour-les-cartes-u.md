## 🛠️ ADR-046 : Effet de Bordure Foil Progressif pour les Cartes Uniques (Progressive Unique Card Border Foil Effect)

### Statut
✅ Accepté & Implémenté (v0.2.02)

### Contexte
Les cartes de classe uniques dans *Hero's Draft* représentent des éléments précieux du deck du joueur. Pour valoriser visuellement l'accumulation d'améliorations de forge appliquées à ces cartes de classe uniques, nous souhaitions introduire un effet visuel dynamique (foil / polychromatique) qui s'enrichit et progresse au fur et à mesure que la carte reçoit des runes de forge.

### Décision
Modifier le composant de bordure polychromatique (`PolychromaticBorder`) et le widget `UiCard` pour injecter dynamiquement le nombre d'améliorations appliquées à la carte (`forgeUpgrades.length`) et adapter la palette de couleurs de l'effet de balayage arc-en-ciel :
1. **Passage de `upgradeCount`** : Modifier le widget `UiCard` pour qu'il calcule `upgradeCount = forgeUpgrades.length` et le passe au composant `PolychromaticBorder`.
2. **Acceptation de `upgradeCount`** : Ajouter la propriété `upgradeCount` (valeur par défaut `0`) dans `PolychromaticBorder` et son painter associé `_PolychromaticBorderPainter` pour assurer une rétrocompatibilité complète avec les composants existants.
3. **Calcul Dynamique des Couleurs** : Dans `_PolychromaticBorderPainter._getRarityShineColors`, lorsque la carte est `unique`, définir un pool de 10 couleurs distinctes ordonnées :
   - Couleur de base Unique (Gold / `#FFD700`)
   - Couleur Commune (`Colors.white70`)
   - Couleur Atypique (`Colors.greenAccent`)
   - Couleur Rare (`Colors.blueAccent`)
   - Couleur Épique (`Colors.purpleAccent`)
   - Couleur Légendaire (`Colors.orangeAccent`)
   - Rouge (`Colors.red`)
   - Jaune (`Colors.yellow`)
   - Cyan (`Colors.cyan`)
   - Rose (`Colors.pink`)
4. **Calcul de la Sélection** : Sélectionner dynamiquement un sous-ensemble de taille `(upgradeCount + 1).clamp(1, 10)` à partir de ce pool.
5. **Bouclage Seamless** : S'assurer que le premier élément sélectionné est répété à la fin du tableau pour garantir un fondu de gradient linéaire tournant parfaitement fluide.
6. **Mise à jour de `shouldRepaint`** : Ajouter la vérification `oldDelegate.upgradeCount != upgradeCount` pour forcer le repeint du CustomPainter lorsque le nombre d'améliorations change.

### Preuves dans le code
- `lib/ui/widgets/ui_card.dart` : Instancie `PolychromaticBorder` avec `upgradeCount: forgeUpgrades.length`.
- `lib/ui/widgets/ui_card/polychromatic_border.dart` : Intègre la logique de pool progressif de 10 couleurs, de clamp de sélection et de duplication de fin.
- `dart analyze` : Renvoie `No issues found!`.
- `flutter test` : Valide l'intégralité des 107 tests existants au vert.

### Conséquences
- ✅ **Feedback Visuel de Puissance** : Le joueur constate l'impact immédiat et la rareté de ses runes de forge à travers l'apparition progressive de nouvelles teintes chromatiques au survol de la carte (d'un simple halo doré à 0 upgrade vers un arc-en-ciel complet et vibrant à 5+ upgrades).
- ✅ **Modularité Intacte** : La logique esthétique reste isolée au sein de `PolychromaticBorder` sans alourdir le widget parent `UiCard`.
- ✅ **Rétrocompatibilité Totale** : La valeur par défaut de `upgradeCount = 0` permet l'utilisation du composant sur des cartes n'ayant pas d'améliorations ou n'exposant pas cette propriété sans provoquer d'erreurs d'initialisation.
