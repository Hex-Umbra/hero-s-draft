## 🗺️ ADR-060 : Décomposition modulaire de la génération procédurale de la carte (v0.2.3)

### Statut
✅ Accepté & Implémenté (v0.2.3)

### Contexte
L'algorithme de génération procédurale de la carte strategique dans `MapGeneratorService` était monolithique et complexe. Il prenait en charge à la fois la création brute des nœuds, le câblage Directed Acyclic Graph (DAG), la vérification des quotas, l'application de l'algorithme anti-répétition de chemin, et le placement des événements spéciaux. Cela rendait le code difficile à lire, tester et faire évoluer.

### Décision
Découper la logique de `MapGeneratorService` en 4 sous-services spécialisés et isolés situés sous `lib/services/map/` :
1. `MapNodeGenerator` : Instancie les nœuds et définit leurs types par défaut selon l'étage.
2. `MapConnectionBuilder` : Établit les connexions géométriques sous forme de Directed Acyclic Graph (DAG) entre étages.
3. `MapValidator` : Valide et ajuste les quotas minimum/maximum de nœuds par type et applique la règle anti-répétition de chemin.
4. `MapContentPlacer` : Applique les règles de placement d'événements spécifiques (échange de reliques).

Faire de `MapGeneratorService` un simple orchestrateur sans logique algorithmique interne.

### Preuves dans le code
- [map_generator_service.dart](../../lib/services/map_generator_service.dart) orchestrant simplement les appels aux 4 sous-services.
- Le sous-répertoire `lib/services/map/` contenant les 4 fichiers des services extraits.

### Conséquences
- ✅ **Respect de la Responsabilité Unique (SRP)** : Les responsabilités sont isolées dans des fichiers distincts faciles à comprendre.
- ✅ **Testabilité Accrue** : Il est désormais plus aisé d'écrire des tests spécifiques pour la validation ou le placement sans instancier toute la chaîne de génération.
