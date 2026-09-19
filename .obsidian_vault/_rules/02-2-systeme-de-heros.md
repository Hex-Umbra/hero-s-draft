### 2.2. Système de Héros

Trois classes de héros, une par dossier `assets/data/classes/<id>/` (`class.json` + `<id>.png` + `cards/`) :

| Héros | HP | Mana | Attaque | Crit. | Maîtrise | Puissance oriente vers | Passif de départ | Cartes de signature (`skills`) |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| **Paladin** | 100 | 3 | 5 | 0 | **1** | Attaque · Compétence · Altération | `regen_armor` | `holy_shield`, `smite` |
| **Berserker** | 80 | 3 | 15 | **10** | 0 | Attaque | `rage` | `reckless_strike`, `rage_form` |
| **Mage** | 60 | 3 | 10 | 0 | 0 | Compétence · Altération | `channeling` | `magic_missile`, `mana_surge` |

> [!IMPORTANT]
> **Chaque classe oriente sa Puissance** (`HeroData.mightTargets`, obligatoire dans `class.json`) —
> [ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md). Le Paladin est le
> généraliste ; le Berserker ne frappe qu'en direct ; le Mage frappe par ses Compétences et ses
> altérations. **Conséquence assumée** : aucune carte de dégâts du jeu n'étant de type Compétence
> (*Projectile Magique* compris), la Puissance du Mage ne renforce aujourd'hui que l'intensité de
> ses brûlures, gels, poisons et chocs — jusqu'aux Compétences offensives de P-42.

> [!IMPORTANT]
> **Le Berserker n'a plus jamais d'armure.** Son `class.json` déclare une `statRules` qui convertit
> **tout** gain d'armure — carte, rune, passif, relique, statut `armor_regen` — en Puissance pour
> **un tour**. *Mur de Fer* (10 armure, carte neutre présente dans tous les decks) lui donne donc 10
> de Puissance pour un tour. La règle vit sur `RunState.statRules`, redérivée de la classe au
> chargement et jamais sérialisée, et s'applique dans `StatGains.apply(stats, gain, rules)`.

> [!NOTE]
> **Colonnes Crit. et Maîtrise** : `HeroData.critChance` et `HeroData.mastery` (cette dernière
> renommée depuis `armorMastery` par [ADR-096](../_adr/ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md)).
> Le tutoriel **n'hérite pas** du `critChance` du Berserker, délibérément : ses dégâts doivent rester
> déterministes. Le lien classe → passif ne part pas de la classe : chaque passif déclare ses
> `classes` éligibles, lues par le point d'accès unique `availablePassivesFor()`
> (`lib/game/systems/passive_availability.dart`), qui trie par `(displayOrder, id)`.

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

**Neuf passifs, trois par classe**, rangés par `displayOrder`. Depuis le **lot C partie 2** de P-41,
le joueur **choisit le sien à l'écran de sélection de classe** : la carte déplie tous les passifs que
`availablePassivesFor()` rend pour la classe, et celui qu'il retient part avec la run. Le
`displayOrder` ne décide donc plus du passif de départ — il décide de l'ordre d'affichage et du
choix par défaut ([ADR-099](../_adr/ADR-099-choix-du-passif-et-conditionnement-des-recompenses.md)).

| Rang | ID | Classe | Trigger | EffectType | Valeurs | Mécanisme |
|:---:|:---|:---|:---|:---|:---|:---|
| 1 | `regen_armor` | Paladin | `endOfTurn` | `gain_armor` | 2 | +2 armure à chaque fin de tour |
| 2 | `fervor` | Paladin | `onDamageTaken` | `fervor` | 1, durée 2 | Quand l'armure encaisse des dégâts, +1 Puissance pendant 2 tours |
| 3 | `blessing` | Paladin | `startOfTurn` | `blessing` | 1 | Chaque tranche de 5 d'**armure survivante** devient 1 PV |
| 1 | `rage` | Berserker | `startOfTurn` | `rage` | 1, durée 1 | +1 Puissance pour le tour, +1 par tranche de 10 PV manquants |
| 2 | `bloodthirst` | Berserker | `onAttackPlayed` | `bloodthirst` | 1, durée 2 | Arme le Vol de vie 2 tours : 1 PV par carte de dégâts, +1 par quart de PV manquants |
| 3 | `frenzy` | Berserker | `onEnemyKilled` | `frenzy` | 2, durée 1, pioche 1 | Chaque ennemi abattu : +2 Puissance pour le tour et 1 carte piochée |
| 1 | `channeling` | Mage | `endOfTurn` | `channeling` | 1 | Chaque Mana non dépensé devient 1 armure |
| 2 | `mage_mark` | Mage | `onAttackPlayed` | `mage_mark` | 1, durée 2 | La **première** Attaque du tour rend sa cible Vulnérable 2 tours |
| 3 | `mana_flux` | Mage | `onSkillPlayed` | `mana_flux` | 1, seuil 3 | Toutes les 3 Compétences d'un combat, +1 Mana pour le tour |

> [!NOTE]
> Les valeurs ci-dessus sont des **valeurs d'équilibrage, pas de conception** : chaque fichier porte
> la sienne et les changer ne demande aucun code. La Maîtrise augmente le paramètre que le bloc
> `mastery` du passif désigne — `value`, `duration` ou `threshold`.
