# Propositions de Nouveaux Ennemis par Tier — Hero's Draft

**Date** : 27/07/2026
**Contexte** : Backlog de contenu identifié par ADR-070/ADR-072 (`decisionLog.md`) — le gating strict du déblocage de tier resserre la fenêtre "tier-1-only" (Slime, Gobelin) aux Actes 1-5, aggravant un manque de variété déjà signalé. Ce document liste des candidats pour étoffer le bestiaire, tier par tier.
**Roster actuel** (`assets/data/enemies/`) : Slime (tier 1), Gobelin (tier 1), Squelette (tier 2), Orc Furieux (tier 3). `maxTierAuthored = 3`.
**Statut** : Brainstorm — concepts et flavor uniquement, aucune stat chiffrée, aucun ennemi encore implémenté.

---

## Méthodologie

- **Progression thématique** : Tier 1 = vermine/mooks, Tier 2 = morts-vivants & hors-la-loi, Tier 3 = brutes & casters mineurs, Tier 4-5 = élémentaires/horreurs prospectifs.
- **Progression de complexité d'intent**, cohérente avec le roster actuel :
  - Tier 1 : intent unique répété (comme Slime, Gobelin).
  - Tier 2 : cycle à 2 intents (comme Squelette).
  - Tier 3 : cycle à 3 phases (comme Orc Furieux : attaque / buff / attaque).
  - Tier 4-5 : mécaniques avancées, au-delà du pattern à 3 phases actuel.
- **Statuts réutilisés** : `poison`, `burn`, `freeze`, `shock`, `vulnerable`, `weakness`, `strength` (tous déjà implémentés dans `EntityStats`/`CombatController`).
- Chaque enemy garde le style visuel/gameplay du bestiaire existant : pas de fioritures narratives complexes, un concept clair et un hook de gameplay identifiable en un coup d'œil.

---

## Tier 1 — Vermine & Mooks

*Complète Slime et Gobelin. Intent unique répété, faible HP, faible menace individuelle.*

| Nom | Concept |
|---|---|
| **Rat Géant** | Attaque rapide et répétitive, esthétique "nuée" grouillante. |
| **Corbeau Charognard** | Chaque coup lui restaure un peu de PV (vampirique léger). |
| **Araignée Venimeuse** | Applique du `poison` au lieu de dégâts directs. |
| **Bandit de Grand Chemin** | Attaque simple, vole un peu d'or en cours de combat (pression économique). |
| **Kobold Éclaireur** | Dégâts faibles, esquive occasionnelle (profil évasif). |

## Tier 2 — Morts-vivants & Hors-la-loi

*Complète Squelette. Cycle à 2 intents, introduction d'un statut ou d'une mécanique mineure.*

| Nom | Concept |
|---|---|
| **Zombie Enragé** | Morsure infectée : applique `poison` à chaque coup du cycle. |
| **Loup des Ombres** | Cycle rapide, chance de critique augmentée (chasse en meute). |
| **Voleur des Cryptes** | Un des deux coups retire de l'armure au lieu de toucher les PV. |
| **Golem d'Argile** | Cycle défense (gagne armure) / attaque lourde. |
| **Harpie** | Un des deux coups applique `vulnerable` (déchire les défenses). |

## Tier 3 — Brutes & Casters Mineurs

*Complète Orc Furieux. Cycle à 3 phases, mécanique unique par ennemi.*

| Nom | Concept |
|---|---|
| **Nécromancien Novice** | Attaque / buff (`strength`) / attaque — monte en puissance sur la durée du combat. |
| **Chevalier Déchu** | Attaque / gain d'armure / frappe perce-armure. |
| **Sorcière des Marais** | Alterne `poison` et `freeze` — spécialiste du statut plutôt que des dégâts bruts. |
| **Ogre Bourrin** | Attaque / attaque / frappe énorme (rage croissante) — gros HP, pattern simple. |
| **Gargouille Animée** | Défense / attaque / attaque — profil tanky. |

## Tier 4 — *(Prospectif)* Élémentaires & Menaces Arcanes

*Nécessite de relever `maxTierAuthored` au-delà de 3. Mécaniques avancées au-delà du cycle à 3 phases.*

| Nom | Concept |
|---|---|
| **Élémentaire de Feu** | Chaque coup applique/cumule `burn`. |
| **Élémentaire de Givre** | Chaque coup applique `freeze`. |
| **Chevalier Spectral** | Attaque garantie perce-armure (contourne le bouclier). |
| **Chaman Orc** | Soigne/buffe les autres ennemis du combat — premier ennemi de type "support". |
| **Aberration Difforme** | Un coup combo applique `vulnerable` + `weakness` simultanément. |

## Tier 5 — *(Prospectif)* Horreurs & Quasi-Boss

*Patterns multi-phases complexes, pensés comme mini-boss d'endless en fin de progression.*

| Nom | Concept |
|---|---|
| **Liche Mineure** | 4 phases : buff / attaque AoE / auto-soin / perce-armure. |
| **Béhémoth de Guerre** | HP énorme, attaque massive télégraphiée tous les 2 tours. |
| **Cavalier de la Mort** | Inflige une "marque" à dégâts différés (variante amplifiée de `burn`) + esquive occasionnelle. |
| **Chimère Trifrons** | 3 intents alternées, une par élément (`burn` / `freeze` / `shock`). |
| **Dragon Juvénile** | Seuil d'enragement sous 50% HP (buff dégâts soudain) — nouveau mécanisme d'"enrage". |

---

## Variantes d'Élite Adaptatives *(inspiré Risk of Rain 2)*

> [!NOTE]
> Terminologie : le jeu a déjà un **Nœud Élite** (type de combat, `MapNodeType.elite`, x1.5 HP/Dégâts). Pour éviter toute confusion, ce système est désigné ici **Variante d'Élite** — un modificateur appliqué à un ennemi individuel, indépendant du type de nœud dans lequel il apparaît.

### Vue d'ensemble
À chaque ennemi sélectionné par `EncounterSystem.generateEnemiesForLevel`, un jet indépendant (probabilité croissante par palier de difficulté) détermine s'il devient une **Variante d'Élite**. Peut se produire dans **n'importe quel combat** (normal, Nœud Élite, Boss) — s'additionne aux multiplicateurs de nœud existants (1.0 / 1.5 / 3.0) sans les remplacer. Un Nœud Élite contenant lui-même un ennemi tiré en Variante d'Élite est donc possible et assumé.

### Effet sur les stats et le tier
La Variante d'Élite augmente le budget de menace effectif de l'ennemi (un `tierBoost` dans le calcul de `CombatRating`) **comme si son tier était plus élevé, sans changer son `tier` réellement autorisé** pour la gate de déblocage (`getUnlockedTier`). Un Slime (tier 1) en Variante d'Élite reste éligible même avant le déblocage du tier 2 — il devient juste beaucoup plus dangereux pour son tier d'origine, plutôt que de contourner le gating de contenu.

### Roster d'affixes proposé (mécaniques riches, à la RoR2)

| Affixe | Accent Visuel | Mécanique |
|:---|:---|:---|
| **Ardent** | Halo orange/rouge | Applique `burn` cumulatif à chaque attaque ; ses dégâts augmentent progressivement au fil du combat (s'échauffe). |
| **Foudroyant** | Halo cyan électrique | Charge un orbe d'énergie à chaque attaque encaissée ; à pleine charge, libère une décharge de zone appliquant `shock`. |
| **Glacial** | Halo blanc-bleuté | Applique `freeze` à chaque attaque ; régénère de l'armure à chaque début de tour (carapace de givre). |
| **Vampirique** | Halo pourpre sombre | Se soigne d'un pourcentage des dégâts infligés à chaque attaque (vol de vie). |
| **Parfait** *(ultra-rare)* | Halo prismatique/arc-en-ciel | Combine une version atténuée des 4 effets ci-dessus ; poids de tirage extrêmement faible — miroir direct du Perfected de RoR2, pensé comme le "jackpot" de danger. |

### Modèle de données proposé
- Nouveau **`assets/data/elite_affixes.json`** → modèle `EliteAffixData` (`id`, `name_fr`/`name_en`, `accentColor`, `tierBoost`, `weight`, effets structurés : `onHit` [statusId, value, duration], `passive` [type, valeur], déclencheur conditionnel [seuil, effet] pour des cas comme Foudroyant).
- **Nouveau hook générique data-driven côté ennemi** : par analogie avec le système de triggers de reliques déjà existant (`RunController.applyRelics(trigger)`), un système de triggers côté ennemi (`onAttackLanded`, `onDamageTaken`, `onTurnStart`) permettant à un ennemi d'exécuter un effet déclaré en JSON. Aujourd'hui les intentions ennemies ne gèrent que `attack`/`defend`/`buff` (aucune n'applique de statut) — ce hook est une extension réelle de `EnemyIntent`/`CombatController`, réutilisable pour du contenu futur au-delà des seules Variantes d'Élite.

### Courbe de progression
Calée sur les paliers ADR-072 déjà existants (`EncounterSystem.getActBracket`, palier de 2 actes). Proposition : `getEliteAffixChance(act)` — chance de base faible au palier 0 (Actes 1-2), augmentant par palier, **plafonnée** à un maximum raisonnable (à calibrer, ex. 25-30%) pour ne jamais rendre chaque ennemi élite en fin de run endless.

### Rendu visuel
Réutilise le pattern déjà validé pour la rareté des cartes (`CardRarity.color`/`RelicRarity.color`, halo lumineux `radial glow`) : un halo/bordure colorée autour de l'`EnemyCard` selon l'affixe assigné. **Aucun nouvel asset image à produire** (contrairement aux Biomes) — c'est un accent de couleur/glow procédural, pas un sprite différent.

### Effort & risque
**Élevé — le plus gros chantier des ajouts de cette session.** Nécessite (1) un nouveau système de triggers côté ennemi (architecture nouvelle, quoique calquée sur le pattern des reliques), (2) un nouveau modèle de données + JSON, (3) une intégration dans le calcul de `CombatRating`/génération d'ennemis, (4) le rendu visuel du halo par affixe. Chaque affixe "riche" (Foudroyant en particulier, avec sa charge conditionnelle) est une mini-mécanique de combat à concevoir et tester séparément.

### Points ouverts
- Plafond exact de la chance d'élite en fin de courbe de progression.
- Faut-il exclure le **Boss de Cycle** (voir `27-07-2026_biomes_finale_sequence_historique_runs_Sonnet5.md`, §2) du tirage de Variante d'Élite pour éviter un cumul de difficulté écrasant ?
- Nombre d'affixes à livrer en V1 : les 4 affixes communes seules formeraient déjà un socle solide, Parfait pouvant attendre une itération 2.

---

## Prérequis mécaniques avant implémentation

- **Tiers 4-5** : relever `maxTierAuthored` (actuellement `3` dans `EncounterSystem`) et ajuster `getUnlockedTier`/la cadence de déblocage par acte (actuellement calée sur ADR-072 : tous les 5 actes, plafond 3).
- **Chaman Orc** (support, soigne/buffe des alliés) : `CombatController`/`EncounterSystem` ne gèrent aujourd'hui aucune interaction ennemi → ennemi ; c'est un nouveau type de mécanique à concevoir.
- **Dragon Juvénile** (seuil d'enrage) : `EntityStats`/`EnemyInstance` n'ont pas de notion de changement de comportement conditionné au HP restant ; à concevoir également.
- **Cavalier de la Mort** (dégâts différés type "marque") : à vérifier si réutilisable tel quel via le statut `burn` existant ou si un statut dédié est préférable.
- Tous les autres concepts (Tiers 1-3, et la majorité du Tier 4) sont réalisables avec les statuts et patterns d'intent déjà en place, sans nouvelle mécanique de combat.
- **Variantes d'Élite Adaptatives** : nouveau système de triggers côté ennemi (`onAttackLanded`/`onDamageTaken`/`onTurnStart`), nouveau modèle `EliteAffixData` + JSON, intégration dans `calculateCombatRating`/`generateEnemiesForLevel`, rendu de halo coloré sur `EnemyCard`. C'est le chantier le plus lourd des trois axes de ce document.

## Prochaines étapes possibles

1. Sélectionner un sous-ensemble prioritaire (par ex. les 5 candidats Tier 1, pour adresser directement le backlog ADR-070/072) — le plus léger et le plus urgent des trois axes.
2. Les **Variantes d'Élite Adaptatives** sont l'axe le plus ambitieux (nouveau système de triggers côté ennemi) : à traiter dans un brainstorm/spec dédié une fois le roster de base (Tiers 1-3) étoffé, plutôt qu'en premier.
3. Passer le sous-ensemble retenu par un brainstorm de design dédié (specs `docs/superpowers/specs/`) pour chiffrer les stats (HP, dégâts, `critChance`, pattern d'intents exact, et pour les élites : poids de tirage par affixe).
4. Créer un dossier `assets/data/enemies/<id>/` avec `enemy.json` (entrées bilingues `_fr`/`_en`) et `sprite.png`, une fois les stats validées, puis lancer `dart run tool/sync_assets.dart`.
