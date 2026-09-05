### 2.2. Système de Héros

Trois classes de héros, une par dossier `assets/data/classes/<id>/` (`class.json` + `icon.png` + `cards/`) :

| Héros | HP | Mana | Attaque | Luck | Armor Mastery | Passif | Cartes de signature (`skills`) |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **Paladin** | 100 | 3 | 5 | 0 | 0 | `regen_armor` (gain armure fin de tour) | `holy_shield`, `smite` |
| **Berserker** | 80 | 3 | 15 | 0 | 0 | `berserker_armor` (armure ∝ HP manquants, début tour) | `reckless_strike`, `rage_form` |
| **Mage** | 60 | 3 | 10 | 0 | 0 | `spell_armor` (armure quand skill jouée) | `magic_missile`, `mana_surge` |

> [!WARNING]
> Le champ `skills` de `class.json` est la liste des **cartes de classe de départ**, résolue
> par `HeroSkillsLink.getHeroCards()`. Il n'a **aucun rapport** avec le système de compétences
> héroïques, supprimé du jeu — [ADR-084](../_adr/ADR-084-suppression-de-la-chaine-de-competences-heroiques.md).
> Cette colonne a listé les six compétences mortes jusqu'au 2026-09-05 ; leurs valeurs sont
> archivées dans `../_archive/2026-09-05-competences-heroiques.md`. Détail des cartes —
> [`_rules/02-3`](02-3-catalogue-de-cartes.md).

**Passifs** (gérés par `TraitSystem`, un fichier par passif sous `assets/data/passives/`) :
| ID | Trigger | EffectType | Valeur | Mécanisme |
|:---|:---|:---|:---|:---|
| `regen_armor` | `endOfTurn` | `gain_armor` | 2 | +2 armure (+armorMastery) à chaque fin de tour |
| `berserker_armor` | `startOfTurn` | `berserker_armor` | 1 | +1 armure par tranche de 10 HP manquants (+armorMastery) |
| `spell_armor` | `onCardPlayed` | `spell_armor` | 1 | +1 armure quand une carte Skill est jouée (+armorMastery) |
