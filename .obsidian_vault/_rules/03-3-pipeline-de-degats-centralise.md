### 3.3. ⚔️ Pipeline de Dégâts Centralisé

Le calcul de tous les dégâts physiques et magiques du jeu (cartes offensives du joueur et intentions d'attaque des ennemis, plus le combat simulé du tutoriel) est unifié sous un pipeline de calcul unique représenté par le service `DamagePipeline.calculate` (`lib/game/services/damage_pipeline.dart`).

Le calcul s'exécute de façon déterministe selon les étapes successives suivantes :

1. **Calcul des Dégâts Initiaux** : Combinaison des dégâts de base (de la carte ou de l'intention d'attaque) avec la force (`strength`) active de l'attaquant :
   $$\text{Dégâts Initiaux} = \text{Dégâts de base} + \text{Force}$$
2. **Faiblesse (Attaquant)** : Si l'attaquant possède l'altération d'état `weakness`, les dégâts sont réduits de **25 % par point, 2 points au plus**, puis arrondis — le barème proportionnel ([`_rules/04-00`](04-00-alterations-d-etat-statuts.md) §4.4).
3. **Jet de Coup Critique (Attaquant)** : Effectue un jet probabiliste basé sur la chance de coup critique effective (`effectiveCritChance`) de l'attaquant, **plus le bonus de critique de la carte jouée** (`critChanceBonus`, 0 par défaut : la rune *Précis* le remplit, 5 points par niveau ; les ennemis et le tutoriel passent 0 — [ADR-106](../_adr/ADR-106-fusion-egale-forge.md)). S'il réussit :
   - Les dégâts sont multipliés par le multiplicateur de critique de l'attaquant (`critMultiplier`, par défaut `1.5`).
   - Le drapeau d'état temporaire `lastActionWasCrit` est assigné à `true` sur les statistiques de l'attaquant (`EntityStats`), servant de source de vérité pour déclencher les tremblements de caméra renforcés, les flashs dorés et les animations de particules physiques sur la couche graphique Flame.
4. **Choc (Défenseur)** : Si le défenseur subit le statut `shock`, la valeur cumulée de ce débuff est directement ajoutée aux dégâts :
   $$\text{Dégâts} = \text{Dégâts} + \text{Valeur de Choc}$$
5. **Vulnérabilité (Défenseur)** : Si le défenseur possède l'altération `vulnerable`, tous les dégâts reçus sont amplifiés de **25 % par point, 4 points au plus**, puis arrondis (§4.4 de la même fiche).

Depuis le lot 1 de P-44 (vague 5), une carte à plusieurs coups passe chaque coup par ce pipeline, et l'absorption qui suit lit la rune *Perforant* (`takeDamage(armorPiercePercent:)`) — [`_rules/03-14`](03-14-couts-combines-croissance-et-multi-coups.md) §3.14.3.

Ce pipeline de calcul centralisé élimine toute duplication mathématique ou risque de divergence entre les dégâts infligés par le joueur et ceux portés par les ennemis.

**Intention d'Attaque Visuelle Ennemie** :
Le getter `effectiveIntent` sur `EnemyInstance` simule l'étape de Faiblesse et de Force (et du Gel s'il est présent) pour afficher à l'écran l'intention exacte de dégâts que subira le joueur au tour suivant, lui permettant d'anticiper la valeur précise de bouclier nécessaire.
