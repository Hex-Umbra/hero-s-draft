### 2.2. Système de Héros

Trois classes de héros, une par dossier `assets/data/classes/<id>/` (`class.json` + `<id>.png` + `cards/`) :

| Héros | HP | Mana | Attaque | Luck | Maîtrise | Passif | Cartes de signature (`skills`) |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **Paladin** | 100 | 3 | 5 | 0 | 0 | `regen_armor` (gain armure fin de tour) | `holy_shield`, `smite` |
| **Berserker** | 80 | 3 | 15 | 0 | 0 | `berserker_armor` (armure ∝ HP manquants, début tour) | `reckless_strike`, `rage_form` |
| **Mage** | 60 | 3 | 10 | 0 | 0 | `spell_armor` (armure quand skill jouée) | `magic_missile`, `mana_surge` |

> [!NOTE]
> **Colonne Maîtrise** : `HeroData.mastery` (clé JSON `mastery`, renommée depuis `armorMastery`
> par [ADR-096](../_adr/ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md)) — aucune
> classe livrée ne la renseigne aujourd'hui. Le lien classe → passif ne part plus de la classe :
> chaque passif déclare lui-même ses `classes` éligibles, lues par le point d'accès unique
> `availablePassivesFor()` (`lib/game/systems/passive_availability.dart`).

> [!WARNING]
> Le champ `skills` de `class.json` est la liste des **cartes de classe de départ**, résolue
> par `HeroSkillsLink.getHeroCards()`. Il n'a **aucun rapport** avec le système de compétences
> héroïques, supprimé du jeu — [ADR-084](../_adr/ADR-084-suppression-de-la-chaine-de-competences-heroiques.md).
> Cette colonne a listé les six compétences mortes jusqu'au 2026-09-05 ; leurs valeurs sont
> archivées dans `../_archive/2026-09-05-competences-heroiques.md`. Détail des cartes —
> [`_rules/02-3`](02-3-catalogue-de-cartes.md).

**Identité visuelle portée par la donnée** — [ADR-090](../_adr/ADR-090-identite-visuelle-de-classe-portee-par-la-donnee.md) :

| Champ de `class.json` | Obligatoire | Rôle | Si absent |
|:---|:---:|:---|:---|
| `classCard` | oui | Carte de classe affichée en combat, `classes/<id>/<id>.png` | — (chargement refusé) |
| `themeColor` | non | Couleur d'accent `#RRGGBB` : paladin `#2196F3`, berserker `#F44336`, mage `#9C27B0` | Bleu |
| `iconPath` | non | Vraie icône de classe — aucune classe livrée n'en porte | Carte de classe recadrée |

> [!IMPORTANT]
> **Aucun écran ne déduit l'identité d'une classe de son `id`.** Sélection de classe, draft de
> départ et dialogue de stats lisent ces champs ; le dégradé des boutons se dérive de `themeColor`.
> Une classe ajoutée par un simple dossier s'affiche partout dans sa couleur et avec son image.

**Passifs** (répartis par `TraitSystem.dispatch`, un fichier par passif sous `assets/data/passives/`,
chacun réservé à sa classe par son propre champ `classes`) — détail du mécanisme et de la Maîtrise :
[`_patterns/03-3`](../_patterns/03-3-traitsystem-passifs-de-heros.md).

| ID | Trigger | EffectType | Valeur | Mécanisme |
|:---|:---|:---|:---|:---|
| `regen_armor` | `endOfTurn` | `gain_armor` | 2 | +2 armure (+Maîtrise) à chaque fin de tour |
| `berserker_armor` | `startOfTurn` | `berserker_armor` | 1 | +1 armure par tranche de 10 HP manquants, ×(1+Maîtrise) |
| `spell_armor` | `onCardPlayed` | `spell_armor` | 1 | +1 armure quand une carte Skill est jouée (+Maîtrise) |
