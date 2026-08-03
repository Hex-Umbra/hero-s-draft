## 🔄 ADR-034 : Rencontre d'Échange de Reliques (Relic Exchange Shrine Node)

### Statut
✅ Accepté & Implémenté

### Contexte
Pour diversifier les nœuds d'intérêt sur la carte stratégique en fin de partie et offrir au joueur une opportunité de raffiner ses synergies de reliques, il manquait un mécanisme d'échange ou de sur-classement ("upcycling"). L'objectif était d'implémenter un nœud de type autel mystique à partir de l'Acte 5, permettant de sacrifier 3 reliques d'une rareté donnée pour acquérir 1 relique de rareté supérieure proposée de façon déterministe. De plus, il fallait s'assurer que si des reliques de type permanent (comme celles augmentant la Force, la Chance ou les PV max) étaient sacrifiées, leurs effets permanents sur la fiche de personnage du héros soient correctement annulés et retirés avant d'attribuer la nouvelle relique.

### Décision
1. **Topologie et Règles de Génération** :
   - Définir le type de nœud `MapNodeType.relicExchange` (emoji `🔄`).
   - Restreindre son apparition à partir de l'**Acte 5**.
   - Garantir sa présence à **100%** pour tout acte divisible par 5 (Acte 5, 10, etc.). Pour les autres actes ($\ge 5$), appliquer une probabilité d'apparition de **10%**.
   - Limiter à un seul nœud d'échange par acte, positionné sur un étage intermédiaire aléatoire (étages 2, 3, 4, 6 ou 7) pour ne pas perturber les haltes obligatoires (repos, élites, boss, nœud de départ).
2. **Offre Déterministe via Seeded Random** :
   - Éviter d'enregistrer l'offre du nœud en base de données de session en instanciant un générateur de nombres aléatoires déterministe basé sur l'identifiant du nœud et l'acte : `final seed = (node.id.hashCode ^ act).abs(); final random = Random(seed);`.
   - Exclure la rareté `Common` du choix de relique offerte et pondérer les chances : Uncommon (40%), Rare (35%), Epic (20%), et Legendary (5%).
3. **Transaction 3-pour-1 et Nettoyage de RunState** :
   - Implémenter la transaction dans `RunController.exchangeRelics` :
     - Retirer les 3 reliques sélectionnées de l'inventaire via `InventoryController.removeRelics`.
     - Inverser et déduire les bonus statistiques permanents accumulés (modificateurs permanents de run via trigger `startOfRun` : Attaque/Force, Chance, Mana maximum, PV maximum) pour chacune des reliques sacrifiées.
     - Ajouter la nouvelle relique via `InventoryController.addRelic` et appliquer immédiatement ses effets permanents si son trigger est `startOfRun`.
4. **Interface Utilisateur Dédiée (`RelicExchangeScreen`)** :
   - Créer un écran thématique d'autel en parchemin affichant la relique offerte, les pré-requis de sacrifice ($R-1$), et les reliques possédées éligibles.
   - Permettre la sélection tactile de 3 reliques (glow doré) avec bouton d'échange sécurisé et possibilité de quitter librement.

### Preuves dans le code
- `lib/services/map_generator_service.dart` : Intégration du nœud `relicExchange` (emoji `🔄`) sous des contraintes d'étage et d'Acte strictes.
- `lib/game/controllers/run_controller.dart` : Méthode `exchangeRelics(sacrificed, gained)` et méthode interne d'inversion des modificateurs de statistiques `removeRelicEffect(relic)`.
- `lib/game/controllers/inventory_controller.dart` : Méthode `removeRelics(List<String> ids)` filtrant et retirant les instances d'inventaire.
- `lib/ui/screens/relic_exchange_screen.dart` : Écran utilisateur avec PageView, grid interactive, sélections glow et confirmation sécurisée.
- `test/unit/relic_exchange_test.dart` : Tests de couverture de la topologie de la carte selon l'acte et de la logique de transaction/inversion.

### Conséquences
- ✅ **Gestion Saine de la Rareté** : Le joueur peut liquider ses reliques de moindre importance pour viser des pièces maîtresses (Épiques ou Légendaires).
- ✅ **Intégrité Mathématique de la Fiche de Personnage** : Pas d'accumulation infinie d'effets statistiques via des boucles infinies d'échange de reliques de run (Force/Mana/PV max bien déduits).
- ✅ **Architecture Déterminée et Légère** : Pas besoin de sauvegarder l'état de l'offre du nœud d'échange grâce à la seed déterministe par nœud/acte.
- ✅ Couverture de Tests : 3 nouveaux tests unitaires rédigés et validés à 100% verts, portant la suite à **103 tests** (100% verts).
