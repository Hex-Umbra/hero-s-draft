## 🎯 ADR-027 : Système de Coup Critique et Rééquilibrage du Scaling Ennemi (Critical Hit System & Enemy Scaling Tuning)

### Statut
✅ Accepté & Implémenté

### Contexte
Le gameplay de combat de *Hero's Draft* manquait d'une composante d'incertitude positive (chance/opportunités tactiques) pour le joueur ainsi que d'une gestion plus fine et équilibrée de la difficulté progressive. Les multiplicateurs de caractéristiques de niveau des ennemis d'origine (+12% HP/lvl, +8% ATK/lvl) rendaient le late game exponentiellement punitif, tandis que l'absence de coups critiques réduisait la variété des builds possibles (comme des archétypes basés sur la chance). De plus, l'affichage HUD n'était pas dimensionné pour intégrer ces nouvelles statistiques de combat.

### Décision
1. **Rework du Scaling Ennemi** :
   - Réduire le coefficient de niveau de PV des ennemis de `0.12` à `0.06` et le coefficient d'acte de `0.40` à `0.20` dans `CombatController.initializeCombat`.
   - Réduire le coefficient de niveau des dégâts des ennemis de `0.08` à `0.04` et le coefficient d'acte de `0.30` à `0.15`.
   - Ces modifications aplatissent la courbe de difficulté pour la rendre plus fluide tout en préservant le défi stratégique.
2. **Architecture du Coup Critique** :
   - Ajouter les propriétés `critChance` (taux en %, défaut 0) et `critMultiplier` (multiplicateur de dégâts, défaut x1.5) au modèle d'attributs de combat `EntityStats`.
   - Intégrer la notion de chance de critique effective (`effectiveCritChance`) qui additionne les statistiques permanentes et les altérations de statut temporaires de critique.
   - Enregistrer des chances de critique de base dans `enemies.json` pour tous les types d'ennemis (Slime: 5%, Gobelin: 10%, Squelette: 10%, Orc Furieux: 15%).
3. **Application du Pipeline de Critique** :
   - Dégâts physiques/magiques des cartes du joueur (`EffectResolver._calculateDamage`) : Effectuer un jet aléatoire (0-99) face aux chances effectives et multiplier les dégâts par `critMultiplier` en cas de réussite.
   - Soins des cartes du joueur (`EffectResolver.resolveCard`) : Jet critique appliquant le multiplicateur aux PV soignés.
   - Dégâts des intentions ennemies (`CombatController.resolveEnemyIntent`) : Jet critique appliquant le multiplicateur aux dégâts d'attaque infligés au héros.
   - Compétences actives de classe du héros (`HerosDraftGame.executeSkill`) : Jet critique sur les compétences ciblées, de zone (AoE), ou perçantes.
4. **Intégration du Draft de Level Up et i18n** :
   - Étendre le pool de récompenses de montée de niveau pour proposer les choix :
     - **Précision** (augmente `critChance` de +1% à +5% selon la rareté du draft).
     - **Férocité** (augmente `critMultiplier` de +0.10 à +0.50 via `critDamageAcc` selon la rareté du draft).
   - Localiser proprement ces choix dans `app_en.arb` et `app_fr.arb` (`draftChoicePrecisionTitle`, `draftChoicePrecisionDesc`, `draftChoiceFerocityTitle`, `draftChoiceFerocityDesc`).
5. **Ajout de Reliques Orientées Critique** :
   - Ajouter deux nouvelles reliques dans `relics.json` exploitant l'effet `gain_crit` :
     - *Focus Lens* (`critical_lens`, Rare, trigger: `startOfCombat`) : confère un buff temporaire de $+15\%$ de critique en combat.
     - *Lucky Charm* (`lucky_charm`, Uncommon, trigger: `startOfRun`) : confère un bonus permanent de $+10\%$ de critique pour toute la run.
6. **Redesign de la Grille des Statistiques (StatsDialog)** :
   - Réorganiser l'affichage du dialogue de statistiques `StatsDialog` (lors du clic sur le profil du héros sur la carte) en une grille compacte et structurée en 2x2.
   - Les quatre zones affichent de manière alignée : Attaque / Armure en haut, et Précision (Chance Critique) / Férocité (Multiplicateur) en bas.

### Preuves dans le code
- Modifications de `EntityStats.dart` pour stocker `critChance` et `critMultiplier`.
- Formules de scaling révisées dans `CombatController.initializeCombat`.
- Logique de lancer aléatoire et d'amplification dans `EffectResolver._calculateDamage`, `EffectResolver.resolveCard` (soin), `CombatController.resolveEnemyIntent` (attaque ennemie), et `HerosDraftGame.executeSkill` (compétences).
- Nouvelles clés de traduction dans `app_en.arb`/`app_fr.arb` et sélection correspondante dans `DraftScreen`.
- Fichier `relics.json` mis à jour avec `critical_lens` et `lucky_charm` et traitement associé dans `RunController.applyRelicEffect`.
- Layout grid 2x2 dans `lib/ui/widgets/map/dialogs/stats_dialog.dart`.
- Passage réussi de tous les 100 tests unitaires et widget-tests de la suite automatisée.

### Conséquences
- ✅ **Builds Variés et Synergies** : Ouvre la voie à des builds basés sur la Chance (Luck) et les Critiques en sélectionnant des reliques critiques et en choisissant Précision/Férocité lors des montées de niveau.
- ✅ **Rythme de Difficulté Lissé** : Évite le pic de dégâts et de PV insurmontables pour les héros à l'Acte 2 ou Acte 3, rendant la progression plus agréable.
- ✅ **HUD Mieux Organisé** : Le dialogue de statistiques affiche clairement les attributs offensifs de critique sans encombrer l'écran principal.
- ⚠️ **Part de Hasard Accrue** : Les combats peuvent basculer sur un coup critique chanceux du joueur (ou malchanceux de l'ennemi), ce qui augmente la tension mais peut légèrement frustrer en cas de coup critique subi inattendu.
- ✅ **Vérification Intègre & Cohérence** : Tous les 100 tests automatisés passent avec succès, et le linter est vierge sous `dart analyze`. Les descriptions de l'interface et les comportements du code sont en parfaite adéquation.
