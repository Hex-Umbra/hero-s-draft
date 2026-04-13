# Bilan des Ajouts : Système de Mana, Points de Vie et Cooldowns Indépendants

Toutes les modifications demandées ont été effectuées pour complexifier le gameplay, améliorer la profondeur stratégique de chaque classe et ajouter la nouvelle mécanique de Mana.

## Ce qui a été implémenté

1. **La Statistique de Mana**
   - Implémentation d'une jauge de Mana visible sur la carte du Joueur en combat.
   - Les classes ont désormais chacune leurs limites de départ : le Mage (15), le Paladin (10), et le Berserker (5).

2. **Cooldowns Multiples et Indépendants**
   - Suppression de l'ancien `specialCooldown` générique, remplacé par une gestion pour chaque compétence dans le moteur de jeu. 
   - Désormais vous pouvez lancer votre deuxième attaque sans être bloqué par le temps de rechargement de la première !

3. **Le Prix des Compétences**
   - **Paladin** : Bouclier (3 Mana), Rage (5 Mana).
   - **Mage** : Nova AoE (4 Mana), Frappe de Foudre (8 Mana).
   - **Berserker** : Perce-Armure (3 Mana). Le coût de _Vampirisme_ ignore le Mana et ponctionne **10% des Points de vie actuels** du Berserker pour pouvoir être utilisé !

4. **Amélioration du Draft et Régénération**
   - À l'écran de draft/récompense de combat, le jeu propose une probabilité équivalente (25%) aux autres statistiques d'obtenir **+5 de Mana Max** ("Sagesse") ; cela donne d'ailleurs +5 Mana actuel également.
   - À chaque niveau complété, le joueur **récupère 50% de son Mana Maximal**.

5. **Système de l'Interface Utilisateur (HUD) Bloquant**
   - En combat, si un sort ne peut pas être lancé (que ce soit parce qu'il est en cours de rechargement ou juste parce que vous n'avez pas assez de Mana/PV), le bouton se grisera l'empêchant d'être cliqué, et affichant dynamiquement ce qu'il vous manque.

6. **Documentation Mise à Jour**
   - Le document `classes_documentation.md` inclut maintenant l'intégralité de ces modifications, montrant les coûts à côté de l'explication de chaque sort et ajoutant le _Mana_ au tableau des statistiques globales.

## Prochaines Étapes :
Vous pouvez tester le jeu localement. L'application devrait redémarrer via l'interface Flutter CLI ou manuellement s'il y a un petit délai pour charger le Hot Reload, pour vérifier l'équilibrage des valeurs dans l'interface de combat.
