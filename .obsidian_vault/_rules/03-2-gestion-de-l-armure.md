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
Les gains d'armure de relique, de carte, de statut et d'intention ennemie (`RunController`,
`strategies.dart`, `status_effect_processor.dart`, `turn_phase_manager.dart`) n'ont jamais bénéficié
de la Maîtrise et continuent de n'en recevoir aucune. Depuis
[ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md), la rune *Endurci* ne fait plus de gain à
part : elle augmente l'effet d'armure de la carte, et ne s'offre qu'à une carte qui en porte un.

**Persistance et Cycle de Reset** :
- **Reset de Tour** : L'armure accumulée par le joueur est réinitialisée à `0` au début de son tour (au lancement de `startTurn()` dans `RunController`, avant l'application des reliques et effets de statut de début de tour). Cela évite l'accumulation infinie d'armure d'un tour à l'autre et garantit l'équilibrage des reliques ou effets générateurs d'armure.
- **Suppression d'Animation** : Lors de cette réinitialisation en début de tour, les animations visuelles de perte d'armure (popup textuel négatif comme "-X" et animation de secousse de bouclier) sont désactivées via un drapeau transitoire (`suppressArmorChangeAnimation` sur `HeroCard`) pour éviter d'indiquer à tort que le joueur a subi des dégâts.
- **Fin de Combat** : L'armure restante est également remise à 0 à la fin de chaque combat (`completeCurrentNode()`).
- **Maîtrise** : La Maîtrise (`effectiveMastery`), quant à elle, reste persistante tout au long de la partie ou du combat selon son origine.

**L'armure d'un ennemi** — à 0 à son apparition, gagnée pendant sa seule phase (intention Défense,
statut `armor_regen`), **remise à 0 par aucun tour** : seuls les coups l'entament. Aucun des quatre
ennemis du jeu n'en gagne aujourd'hui : leurs intentions, fixées dans leur fichier, ne sont
qu'attaques et Puissance (vérifié le 2026-11-22 sur `assets/data/enemies/`).

> [!NOTE]
> **Son voile est la jauge de l'armure seule, pas des PV** (B15, B16 — vague 1 du bestiaire, sur la
> branche `feat/v0.6.1-interface-des-ennemis`, [ADR-121](../_adr/ADR-121-l-interface-des-ennemis-en-combat.md)).
> Sur la barre de PV, le voile couvre `armure / plein` de la largeur, le plein étant le plus haut
> montant atteint depuis que l'armure est tombée à 0 (`ArmorVeil`, `lib/game/systems/armor_veil.dart`) :
> tout gain devient le nouveau plein, un coup qui entame le laisse, zéro l'efface. 6 d'armure
> couvrent la barre d'un petit ennemi comme 40 celle d'un boss. Le plein est un état d'affichage de
> `EnemyCard`, hors de toute règle et de toute sauvegarde. **Dormant aujourd'hui** : aucun ennemi du
> jeu ne gagne d'armure. Le montant s'écrit en cyan à côté des PV, dans la barre, et dans la fiche
> de l'ennemi (« Armure 4 », même à 0).
