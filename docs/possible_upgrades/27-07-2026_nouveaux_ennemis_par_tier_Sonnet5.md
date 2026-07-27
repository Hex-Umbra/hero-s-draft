# Propositions de Nouveaux Ennemis par Tier — Hero's Draft

**Date** : 27/07/2026
**Contexte** : Backlog de contenu identifié par ADR-070/ADR-072 (`decisionLog.md`) — le gating strict du déblocage de tier resserre la fenêtre "tier-1-only" (Slime, Gobelin) aux Actes 1-5, aggravant un manque de variété déjà signalé. Ce document liste des candidats pour étoffer le bestiaire, tier par tier.
**Roster actuel** (`assets/data/enemies.json`) : Slime (tier 1), Gobelin (tier 1), Squelette (tier 2), Orc Furieux (tier 3). `maxTierAuthored = 3`.
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

## Prérequis mécaniques avant implémentation

- **Tiers 4-5** : relever `maxTierAuthored` (actuellement `3` dans `EncounterSystem`) et ajuster `getUnlockedTier`/la cadence de déblocage par acte (actuellement calée sur ADR-072 : tous les 5 actes, plafond 3).
- **Chaman Orc** (support, soigne/buffe des alliés) : `CombatController`/`EncounterSystem` ne gèrent aujourd'hui aucune interaction ennemi → ennemi ; c'est un nouveau type de mécanique à concevoir.
- **Dragon Juvénile** (seuil d'enrage) : `EntityStats`/`EnemyInstance` n'ont pas de notion de changement de comportement conditionné au HP restant ; à concevoir également.
- **Cavalier de la Mort** (dégâts différés type "marque") : à vérifier si réutilisable tel quel via le statut `burn` existant ou si un statut dédié est préférable.
- Tous les autres concepts (Tiers 1-3, et la majorité du Tier 4) sont réalisables avec les statuts et patterns d'intent déjà en place, sans nouvelle mécanique de combat.

## Prochaines étapes possibles

1. Sélectionner un sous-ensemble prioritaire (par ex. les 5 candidats Tier 1, pour adresser directement le backlog ADR-070/072).
2. Passer par un brainstorm de design dédié (specs `docs/superpowers/specs/`) pour chiffrer les stats (HP, dégâts, `critChance`, pattern d'intents exact) d'un lot retenu.
3. Rédiger les entrées bilingues (`_fr`/`_en`) dans `assets/data/enemies.json` une fois les stats validées.
