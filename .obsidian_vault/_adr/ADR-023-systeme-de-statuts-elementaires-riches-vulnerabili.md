## ⚔️ ADR-023 : Système de Statuts Élémentaires Riches & Vulnérabilité Universelle

### Statut
✅ Accepté & Implémenté. **D1 (Brûlure), D2 (Gel) et D3 (Électrocution) amendées le 2026-11-17 par
[ADR-117](ADR-117-les-charges-elementaires.md)** (P-53, vague 7, livré sur la branche
`feat/v0.5.9-p53-charges-elementaires`, en attente du test, de la PR, de la fusion et du tag du
propriétaire) : les trois deviennent des charges élémentaires — le Feu, le Gel, la Foudre —, des
points qui rompent à un seuil. **D4 (Vulnérable) est inchangée** (son barème est celui
d'[ADR-111](ADR-111-profondeur-lot-1-couts-croissance-multi-coups-statuts-proportionnels.md) D4).

### Contexte
Les combats tactiques manquaient d'altérations d'état dynamiques et de synergies élémentaires. Les effets de statut initiaux étaient soit trop basiques, soit limités aux forces et armures. Pour offrir des opportunités de build plus poussées (jeux basés sur le temps, le burst ou le contrôle), il était nécessaire d'introduire des effets élémentaires riches et une gestion propre de la vulnérabilité affectant toutes les entités en jeu.

### Décision
1. **Brûlure (`burn`)** : Inflige des dégâts au début du tour de la cible. Le tick applique des dégâts physiques équivalents à l'intensité accumulée, puis décrémente l'intensité et la durée de 1.
2. **Gel (`freeze`)** : Réduit de 50% (arrondi) les dégâts de la prochaine attaque de la cible, puis consomme immédiatement la durée du gel.
3. **Électrocution (`shock`)** : Fonctionne comme un amplificateur de dégâts cumulatif flat. À chaque attaque directe subie par la cible, la valeur cumulée du statut est ajoutée aux dégâts infligés.
4. **Vulnérabilité (`vulnerable`)** : Multiplicateur universel de dégâts. Toute attaque directe subie par une entité sous vulnérabilité inflige 50% de dégâts supplémentaires. Cet effet est symétrique (affecte autant le Héros que les Ennemis).
5. **Découplage Logique** : Câbler la totalité de ces règles dans `CombatController` et `EffectResolver` de manière autonome, garantissant la testabilité unitaire sans nécessiter le moteur graphique Flame.

### Preuves dans le code
- `lib/game/services/effect_resolver.dart` : Prise en compte de la vulnérabilité et de l'électrocution (`shock`) dans le calcul dynamique des dégâts finaux d'une attaque.
- `lib/game/controllers/combat_controller.dart` : Ticks de brûlure résolus au début du tour et application des réductions de dégâts liées au gel.
- `test/unit/combat_controller_test.dart` et `test/unit/effect_resolver_test.dart` : Tests unitaires vérifiant la conformité des ticks et des réductions/amplifications.

### Conséquences
- ✅ **Diversité des builds** : Permet au joueur de construire des archétypes viables orientés Gel (contrôle défensif) ou Électrocution/Vulnérabilité (burst agressif).
- ✅ **Double tranchant** : L'universalité de la vulnérabilité force le joueur à surveiller ses propres débuffs sous peine de subir des attaques dévastatrices.
