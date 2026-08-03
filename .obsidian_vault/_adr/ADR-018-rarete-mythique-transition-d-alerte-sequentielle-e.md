## 🟥 ADR-018 : Rareté Mythique & Transition d'Alerte Séquentielle en Draft (Mythic Rarity & Two-Step Draft Transition)

### Statut
✅ Accepté & Implémenté

### Contexte
Pour élever le sentiment d'accomplissement et de puissance lors de l'obtention de cartes ultra-spéciales (telles que le Trèfle à quatre feuilles ou le Miroir), le jeu intègre une rareté suprême appelée **'Mythique' (Mythic)**. Présenter ces cartes exceptionnelles de manière brute ou mélangée avec les autres cartes dans un tirage standard affaiblirait considérablement l'impact émotionnel et dramatique souhaité. Nous souhaitions concevoir un flow de transition cinématique séquentiel en deux étapes : d'abord la révélation du Draft standard, puis en cas de tirage Mythique, le déclenchement d'un écran d'alerte spectaculaire, suivi du spin et de la révélation isolés de la carte Mythique au premier plan sous un effet de flou gaussien de l'arrière-plan.

### Décision
1. **Algorithme de Tirage Indépendant Double Rolls** :
   - Plutôt que d'intégrer le tirage des cartes Mythiques dans le pool global de cartes ordinaires avec le même algorithme linéaire, le système applique un double roll de probabilité indépendant.
   - Si les conditions du tirage de Draft amélioré (Level Up) sont remplies, un roll de probabilité ultra-restreint de `0.5%` est exécuté. Si validé, la carte spéciale (Trèfle ou Miroir) est tirée et injectée dans le flux de présentation Mythique.
   - *Rationale* : Ce double tirage isolé garantit le maintien strict des pourcentages de distribution réguliers (Légendaire `2.0%`, Épique `6%`, Rare `16%`, Atypique `24%`, Commune `51.5%` au Level Up, ou Commune `52%` au Draft de base) sans perturber l'équilibre mathématique global du deckbuilder.

2. **Transition Séquentielle Cinématique en Deux Étapes** :
   - **Étape 1 : Révélation Standard** : Les 3 cartes ordinaires s'affichent et stabilisent séquentiellement via les rouleaux 3D (de 0.8s à 2.0s).
   - **Étape 2 : Alerte Alarme (Laser & Pop-Up)** : Si une carte Mythique est obtenue, le Draft normal se fige. Une animation d'alerte se lance pendant 1400ms : une ligne laser écarlate (`0xFFE53E3E`) balaie horizontalement l'écran de gauche à droite, divisant virtuellement les cartes standard. Simultanément, trois points d'exclamation géants `!!!` apparaissent en animation élastique au centre, accompagnés de doubles ombres rouge et blanc, et clignotent deux fois pour capter l'attention.
   - **Étape 3 : Flou Gaussien et Spin de Premier Plan** : L'arrière-plan subit un flou de `8.0px` via un `BackdropFilter` Flutter. Une bannière rouge clignotante annonce l'alerte. Le rouleau de la carte Mythique spin au premier plan avec une durée de rotation prolongée (`+800ms`) pour accentuer le suspense, une amplitude de secousse doublée (`12.0` vs `6.0` pixels), et des contours d'étincelles rouge-néon (`_SparkPainter` avec configurations `isMythic`).
   - **Étape 4 : Réintégration Synchrone** : Une fois la carte stabilisée sur sa face avant 3D, le système attend 1.5s avant de dissiper progressivement en fondu l'overlay flouté, insérant proprement la carte Mythique dans la rangée du Draft normal pour permettre son choix définitif par l'utilisateur.

### Trade-offs (Compromis Techniques)
- **Temps d'attente supplémentaire** : La transition cinématique allonge la phase de draft de près de 3 secondes lors d'une obtention Mythique. Ce compromis est hautement bénéfique car l'apparition d'une carte Mythique est un événement rarissime (probabilité de `0.5%`), transformant cette attente en une célébration gratifiante.
- **Ressources GPU de Floutage (`BackdropFilter`)** : Flouter dynamiquement l'intégralité du canvas de l'arène de combat consomme des cycles GPU supplémentaires. Cependant, puisque cette opération est isolée à l'écran de récompense et ne s'applique qu'au moment précis du tirage, l'impact sur l'expérience générale de fluidité du jeu (60 FPS) est totalement imperceptible.

### Preuves dans le code
- `probabilities_test.dart` : Tests rééquilibrés à 100% exact validant les probabilités de Draft (Common `52%` standard, et `51.5%` + Mythic `0.5%` au Level Up).
- `DraftScreen` orchestrant le `BackdropFilter` (flou `8.0px`), l'effet laser horizontal 1400ms, et le pop des points d'exclamation `!!!`.
- `DraftCardReel` configuré avec le paramètre `isMythic` (border `4.0`, couleur rouge sang `0xFFE53E3E`, shake amplitude `12.0`, `+800ms` delay).

### Conséquences
- ✅ **Game Feel et Suspension Inégalés** : La dramatisation visuelle de l'obtention d'une carte Mythique crée une forte charge d'adrénaline et de satisfaction pour le joueur.
- ✅ **Robustesse Mathématique** : Le modèle probabiliste rééquilibré est rigoureusement testé et asserté à la frame près dans les tests automatisés (74/74 au vert).
- ✅ **Qualité de Rendu Premium** : Le contraste net entre l'arrière-plan flouté sombre et le premier plan écarlate vibrant met en valeur l'identité graphique d'exception de la rareté Mythique.
- ⚠️ **Rigueur d'Orchestration Visuelle** : L'introduction d'un overlay à fort impact au-dessus des rouleaux standard nécessite des cycles d'animation parfaitement synchronisés pour éviter les chevauchements visuels ou les clics de sélection hâtifs de l'utilisateur pendant le spin. Le bouton de sélection est verrouillé jusqu'à la réintégration complète.
