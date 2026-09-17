### 3.2. 🛡️ Gestion de l'Armure

**Absorption des dégâts** (`EntityStats.takeDamage(amount)`) :
```dart
if (armure >= amount) {
  armure -= amount;          // Armure absorbe tout
} else {
  int remaining = amount - armure;
  armure = 0;                // Armure brisée
  currentPv = (currentPv - remaining).clamp(0, maxPv);
}
```

**Maîtrise (`EntityStats.mastery`, renommée depuis `armorMastery`)** : Statistique cumulative et
permanente, dont l'effet n'est plus câblé sur l'armure — chaque passif déclare dans son fichier ce
qu'un point de Maîtrise lui apporte (bloc `mastery`, [ADR-096](../_adr/ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md)).
Depuis P-49, **`StatGains.apply`** n'a plus de règle spéciale pour `GainSource.passive` : la
Maîtrise n'est plus ajoutée au moment du gain, mais **avant**, par `TraitSystem.dispatch`, qui
applique `PassiveData.withMastery(heroStats.effectiveMastery)` au passif actif avant d'appeler la
stratégie de son `effectType` — la stratégie calcule donc directement le bon montant. `effectiveMastery`
(getter dynamique sur `EntityStats`) combine toujours la base `mastery` et les bonus temporaires de
combat issus du statut `'mastery'` (ex. Croc Kunaï, [`_rules/03-5`](03-5-systeme-de-reliques.md)).
Les gains d'armure de relique, de carte, de rune, de statut et d'intention ennemie (`RunController`,
`EffectResolver`, `strategies.dart`, `status_effect_processor.dart`, `turn_phase_manager.dart`) n'ont
jamais bénéficié de la Maîtrise et continuent de n'en recevoir aucune.

**Persistance et Cycle de Reset** :
- **Reset de Tour** : L'armure accumulée par le joueur est réinitialisée à `0` au début de son tour (au lancement de `startTurn()` dans `RunController`, avant l'application des reliques et effets de statut de début de tour). Cela évite l'accumulation infinie d'armure d'un tour à l'autre et garantit l'équilibrage des reliques ou effets générateurs d'armure.
- **Suppression d'Animation** : Lors de cette réinitialisation en début de tour, les animations visuelles de perte d'armure (popup textuel négatif comme "-X" et animation de secousse de bouclier) sont désactivées via un drapeau transitoire (`suppressArmorChangeAnimation` sur `HeroCard`) pour éviter d'indiquer à tort que le joueur a subi des dégâts.
- **Fin de Combat** : L'armure restante est également remise à 0 à la fin de chaque combat (`completeCurrentNode()`).
- **Maîtrise** : La Maîtrise (`effectiveMastery`), quant à elle, reste persistante tout au long de la partie ou du combat selon son origine.
