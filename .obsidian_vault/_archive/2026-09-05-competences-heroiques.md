# Archive — Compétences Héroïques (système supprimé)

**Archivé le 2026-09-05.** Le système de compétences héroïques a été **supprimé du jeu** par
le bloc 1 de P-40 (commit `ced306e`, 2026-09-04) : il n'avait aucun point d'entrée. Personne
n'appelait `HerosDraftGame.executeSkill`, et aucun bouton de compétence n'existait dans
`lib/ui/`. Les 6 entrées de `skills.json` ne correspondaient d'ailleurs à aucun identifiant
réel — les classes pointaient vers des cartes, pas vers ce catalogue.

Sont partis ensemble : `assets/data/skills.json`, `SkillData`, `SkillState`,
`SkillController`, les deux `executeSkill`, le callback `onExecuteSkill`, les trois appels de
cooldown et le champ `skills` de la sauvegarde. Voir
[ADR-084](../_adr/ADR-084-suppression-de-la-chaine-de-competences-heroiques.md).

Les deux fiches ci-dessous sont conservées **telles quelles**, pour leur valeur historique.
Elles ne décrivent plus le jeu.

> [!WARNING]
> Ce fichier est en lecture seule. Rien ici ne décrit le code actuel.

---

## Fiche `_rules/05-00-competences-heroiques.md` (verbatim)

## 5. Compétences Héroïques (Skills)

**6 compétences** (2 par héros) dans `skills.json` :

| ID | Héros | Nom | Coût Mana | Type d'Effet | Valeur | Mécanisme |
|:---|:---|:---|:---|:---|:---|:---|
| `paladin_shield` | Paladin | Bouclier | 3 | `armor_buff` | 15 | Gain d'armure (+armorMastery) |
| `paladin_rage` | Paladin | Rage | 5 | `attack_buff` | 2 | Buff force (15% maxPv, durée 2) |
| `mage_nova` | Mage | Nova | 4 | `damage_aoe` | 20 | Dégâts à tous les ennemis |
| `mage_strike` | Mage | Frappe Foudre | 8 | `damage_targeted` | 150 | Dégâts massifs ciblés |
| `berserker_leech` | Berserker | Vampirisme | 0 | `lifesteal_buff` | 3 | Buff lifesteal (durée 3) |
| `berserker_pierce` | Berserker | Perce-Armure | 3 | `damage_pierce` | 15 | Dégâts perçants (ignore armure) |

**Cooldown** : Chaque compétence a un cooldown qui se décrémente de 1 par tour (`SkillController.tickCooldowns()`). Utilisable quand `cooldown <= 0`.

---

## Fiche `_patterns/02-7-skillcontroller.md` (verbatim)

### 2.7. `SkillController` (`skillProvider`)

**Provider** : `NotifierProvider<SkillController, SkillState>`

**État** : `skill1Cooldown`, `skill2Cooldown` (int).

**Responsabilités** : `tickCooldowns()` (décrémente de 1, min 0), `triggerSkill1(cd, {mana, hpPercent})` / `triggerSkill2()` — vérifie cooldown, consomme ressources via runProvider, active le cooldown. `resetCooldowns()`.

---

## Ce qui a survécu, et pourquoi

Deux homonymes ont été **délibérément conservés** ; ne pas les confondre avec ce système.

| Survivant | Où | Pourquoi |
|:---|:---|:---|
| `HeroData.skills` | `assets/data/classes/<id>/class.json` | Homonyme sans rapport : la liste des `id` des deux cartes de signature d'une classe, lue par le tutoriel et le draft de départ via `HeroSkillsLink.getHeroCards()` |
| `applyLifestealBuff` | `RunController` (façade) et `PlayerStatsManager` (implémentation) | Vit dans `RunController`, pas dans le système de compétences ; P-41 s'en sert. État exact des appelants : [ADR-084](../_adr/ADR-084-suppression-de-la-chaine-de-competences-heroiques.md), ce fichier n'ayant pas vocation à décrire le code actuel |
