# Phase 22 : Nerf, Buff et Mécaniques de Cartes (Épuisement)

## 1. Analyse Approfondie du Problème

Certaines cartes du deck de base présentent des problèmes de design fondamentaux pour un jeu roguelike, particulièrement avec la refonte du mana.

**Conséquences directes en jeu :**
- **"Attaque Rapide" :** Coûtant 0 mana et permettant de piocher tout en faisant des dégâts, elle est "infiniment" rentable. Dans un système à 3 mana, une carte à 0 est inestimable. Si elle pioche, elle permet de cycler le deck gratuitement sans aucune réflexion, ce qui est mauvais pour le design (elle devient une carte "auto-pick" obligatoire).
- **Le problème du Soin répétable :** La "Potion de Soin" (qui est jouée comme une carte) coûte 2 Mana et rend 8 PV. Si elle remonte dans la main, un joueur peut choisir d'étirer artificiellement la durée d'un combat contre un ennemi faible (qui frappe pour 2 ou 3) pour se soigner à fond avant de tuer l'ennemi. Cela détruit la tension d'attrition typique des roguelikes (où la perte de PV est supposée être quasi-permanente).

## 2. Pistes de Solutions Détaillées

### Rééquilibrage de l'Attaque Rapide
- **Option A (Nerf du coût) :** Passer le coût à 1 Mana. La carte devient "Inflige 3 Dégâts, Pioche 1 Carte". C'est un cycle neutre correct.
- **Option B (Nerf de l'effet) :** Garder le coût à 0, mais retirer la pioche. La carte devient juste un petit burst de 3 dégâts gratuit.
- **Recommandation :** L'Option A est souvent plus saine. La pioche est une mécanique très puissante, elle doit avoir un coût associé.

### Implémentation du Mot-Clé "Épuisement" (Exhaust)
- **Principe :** Toute carte ayant l'effet "Épuisement" est retirée du combat après avoir été jouée une fois. Elle ne retourne pas dans la défausse et ne peut pas être repiochée lors de ce combat.
- **Application :** Les cartes de Soin (Potion), les gros buffs uniques, et potentiellement certaines grosses attaques très peu chères doivent avoir cette mécanique.
- **Impact :** Le joueur doit choisir le moment optimal pour utiliser sa Potion de Soin, sachant qu'il ne pourra le faire qu'une seule fois dans le combat. Finis les combats qui s'éternisent pour farmer du soin.

## 3. Plan d'Implémentation Étape par Étape

### Étape 1 : Implémentation de la propriété "Épuisement" (Exhaust)
- **Fichiers ciblés :** `lib/models/data/card.dart`, `assets/data/cards.json`.
- **Actions :**
  - Ajouter un booléen `isExhaust` (ou `isConsumable`) au modèle de données de la Carte. Le parser du JSON doit pouvoir lire ce champ (valeur par défaut : `false`).
  - Mettre à jour `cards.json` pour ajouter `"isExhaust": true` à la "Potion de Soin" et éventuellement d'autres cartes pertinentes.

### Étape 2 : Modification du cycle de vie des cartes dans Riverpod
- **Fichiers ciblés :** `lib/game/controllers/deck_controller.dart` ou `EffectResolver`.
- **Actions :**
  - Dans la fonction `playCard(Card card)`, ajouter une condition :
    ```dart
    if (card.isExhaust) {
      moveToExhaustPile(card); // Nouvelle liste ou simplement retirer la carte
    } else {
      moveToDiscardPile(card); // Comportement normal actuel
    }
    ```
  - S'assurer que le re-mélange du deck (quand la pioche est vide) n'inclut PAS les cartes épuisées.

### Étape 3 : Ajustements Numériques dans le JSON
- **Fichier ciblé :** `assets/data/cards.json`.
- **Actions :**
  - Modifier `Attaque Rapide` : passer son `"cost"` de 0 à 1, ou retirer l'effet `"draw"`.
  - Auditer le reste des cartes pour s'assurer qu'aucune autre carte à 0 ne génère de la pioche sans contrepartie sévère (ex: perdre de la vie).

### Étape 4 : Retour Visuel (UI/Juice)
- **Fichier ciblé :** `lib/ui/game_screen.dart` ou le widget de la carte animée.
- **Actions :**
  - Ajouter un mot-clé visuel sur les cartes concernées (ex: une petite icône de feu ou un texte "Usage unique").
  - Lors de l'animation de jeu de la carte, si elle a `isExhaust`, jouer une animation spéciale (ex: la carte brûle ou se dissipe en particules) au lieu de glisser vers la pile de défausse.

## 4. Critères de Validation
- [ ] Le modèle de carte accepte la propriété `isExhaust`.
- [ ] Jouer la Potion de Soin la retire de la main et elle ne retourne jamais dans le deck pour le reste du combat.
- [ ] La carte "Attaque Rapide" a été modifiée selon le nouveau paradigme de coût.
- [ ] Les modifications sont stables et les tests unitaires / `dart analyze` passent avec succès.
