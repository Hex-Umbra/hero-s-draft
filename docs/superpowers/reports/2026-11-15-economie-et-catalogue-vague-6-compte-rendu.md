# Vague 6 — `0.5.8` — la tranche 2 — compte rendu

**Branche** : `feat/v0.5.8-p42-tranche-2` · **Spec** : aucune (R31, à l'essai) · **Plan** : [tranche 2](../plans/2026-11-15-p42-tranche-2.md) ([vérifications](../plans/2026-11-15-p42-tranche-2-verifications.md)) · **Maquettes** : [la réserve de mana](../../presentations/2026-11-15_reserve_de_mana_maquettes.pptx) · **Forme** : [README](README.md).

*Ouvert à la fin du plan (§3.5), fermé à la §3.8.*

## 0. Pour le propriétaire

*À écrire en §3.8.*

## 1. La branche et ses chiffres

| Version | Commits | Tests | `dart analyze` | Code (`lib/`, `test/`, `assets/`) | Superpowers | Claude Code |
|:---|---:|:---|:---|:---|:---|:---|
| `0.5.8` | 8 de code (`866fefd7..ec438c28`), après 2 de documentation | 1620 → **1682** | `No issues found!` | 59 fichiers, +1595 / −141 | 7.0.0, `bb92a77` | 2.1.319 |

## 2. Les arbitrages

Une ligne chacun ; les options écartées sont dans le [fichier de vérifications](../plans/2026-11-15-p42-tranche-2-verifications.md).

| # | Question | Classe | Choix | Filtre |
|:---|:---|:---:|:---|:---:|
| A14 | La réserve à l'écran | P | C et D ensemble : flèches et légende cyan sous les cristaux ; message de fin de tour « n Mana en réserve » bordé de cyan ; Mage sous *Canalisation* seulement (propriétaire, 15/11, sur maquettes) | — |
| A7 · A8 · A9 · A13 | Les cartes qui complètent les lots, la courbe de Voile, les textes de *Canalisation* | délégué | Croisé + *Fléau béni*, *Charge du croisé* ; Vampire + *Traque*, *Frénésie sanglante* à 1 mana ; Voile + *Cataclysme*, *Bouclier d'éther*, courbe 1-2-3-3-3 (rédacteur `game_designer`, prompt du 15/11) | P1, P2, 7 |
| Q8 · O3 | Cartes-pont ; composition de la tranche | P · T | Aucune (vague 5) ; Croisé, Vampire, Voile gardés, rien dans la vague 5 ne les contredit | — · 7 |
| A1-A4 | La réserve sur `RunState`, jamais sauvegardée ; un calcul `ManaReserve.preview` ; tout mana non dépensé, hors `StatGains` ; rien sans *Canalisation* | T | plan §2 | 1, 4, 5, 6, 8 |
| A5 · A6 | `mana_regen` sur `might_regen`, icône du mana ; D44 sur *Méditation* par `excludesEffects` `status:<id>` | T | plan §2 | 1, 4, 6 |
| A10 · A11 · A12 | `feeds` de *Canalisation* `["power", "skill"]` ; le démasquage par la donnée, le Mage démarre sur *Canalisation* ; le tutoriel ne simule pas la réserve, message « Mana restant » | T | plan §2 | 1, 7 |
| A14 bis · A15 | Les lectures de C et D (n, « (plafond) » au-delà du plafond, la barre qui descend de 14 px) ; *Persistant* accepté sur *Lacération* | T | plan §2 | 6, 7, 8 |
| T1.1 | Le Mage du tutoriel sous *Canalisation* (rendu P par le vérificateur) | T | Reclassé T : le tutoriel ne simule aucun passif, et en `0.5.6` déjà son Mage démarrait sur *Canalisation* avec ce message | 7 |
| T1.2 | Au tour ennemi, la légende lit la réserve écrite, sans « (plafond) » | T | La réponse C vaut pour le tour du joueur ; *Essence spirituelle* ne fausse plus le n | 6, 8 |

**Décisions de SDD** (registre recopié avant sa suppression ; revue d'ensemble sur `6d3afeaf..ffb55edb`, « prête », une passe de correction `ec438c28`) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S1 | Task 1, tri des mineurs visibles : `mana_regen` ajouté aux listes `isPlayerEffect` (face compacte, texte Flame) ; `effect_line_texts.dart` (signatures seules) et `status_indicator.dart` (carte ennemie seule, A5) laissés | T | Une phrase absente le jour où une signature posera le statut |
| S2 | Task 2, tâche à risque : revue sur le modèle le plus capable, cinq mutations du plan rouges, deux des siennes vertes — le plafond codé à 3, la réserve passée par `StatGains` — ; trois tests ajoutés, 1638 → 1641, totaux du plan décalés de 3 | T | — |
| S3 | Task 3, tri visible : sans réserve, le message « Mana restant » des autres classes rendu par le `Text` d'avant (le propriétaire le veut inchangé) ; la marge sous le bouton à grand facteur de texte et la taille des flèches aux tests manuels | T | Une retouche de taille après le test |
| S4 | Task 4, tri visible : « +2 par carte jouée ce tour » gardé sans « ou signature », convention des textes `scaleWith` de la vague 5 | T | Une phrase à reprendre après le test |
| S5 | Task 5 jouée par l'orchestrateur (amendement) : analyse propre, 1681 verts, greps conformes | T | — |
| S6 | Revue d'ensemble, trois mineurs corrigés : au tutoriel, la main de l'étape « Jouer des cartes » tient dans le mana (*Bouclier d'éther* à 3 avec une attaque la dépassait, un test) ; la légende quitte le combat fini ; un commentaire de test rendu faux par D30. Gardé : le vocabulaire `status:<id>` écrit en trois endroits, de forme identique | T | Une factorisation plus tard |

## 3. Les tests manuels

*À écrire en §3.8.*

## 4. Trouvé périmé, et pour la file

- `effect_line_texts.dart` n'a pas de phrase pour `mana_regen` : à écrire le jour où une signature posera le statut (S1).
- `'status:${statusId}'` s'écrit dans `forge_rune_rules.dart`, `passive_feeds.dart` et `EffectKind.of`, qui se dit pourtant « la seule écriture du vocabulaire » : à factoriser à la quatrième lectrice.
- Au tutoriel, quand aucun couple attaque + Armure du deck ne tient dans le mana, la main d'avant est gardée : un deck de départ très atypique laisserait l'étape en deux tours.
- La garde `if (preview == null) return;` de `ManaReservePassive` est inatteignable (prévue par le plan, elle rétrécit le type).
- Deux rangées de cristaux (seize ou plus) feraient déborder le HUD de 88 px sous *Canalisation* : irréaliste aujourd'hui.

## 5. Les leçons

*À écrire en §3.8.*

## 6. Les statistiques de la session

*À mesurer juste avant le commit de §3.8.*
