# Cadre d'Ennemi Modulaire (Ornement Séparé par Tier + Accent d'Élite)

**Date** : 28/07/2026
**Contexte** : Suite à la préparation de la génération d'images pour le roster de `27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md` — le cadre orné actuellement baked-in dans chaque asset (`enemy_goblin.png`, `enemy_orc.png`, `enemy_skeleton.png`, `enemy_slime.png`) est le genre de détail qu'un modèle d'image redessine légèrement différemment à chaque génération (largeur de bordure, précision des gravures). Ce document explore le fait de séparer la créature du cadre pour garantir une cohérence parfaite.
**Statut** : Brainstorm — conception fonctionnelle validée par échange, aucun asset produit, **rien encore implémenté**.
**Lien avec les autres brainstorms** : Conçu en même temps que la section "Variantes d'Élite Adaptatives" de `27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md` — ce document **consolide** le concept de halo de couleur autour de la créature en un accent de couleur appliqué directement sur l'ornement du cadre (voir §4).

---

## 1. Constat de départ

`lib/game/components/entities/enemy_card.dart:66-113` charge l'image entière du `spritePath` et l'affiche en `BoxFit.contain`, sans recadrage : le cadre orné fait partie intégrante de chaque asset actuel, ce qui veut dire que chaque nouvelle génération d'image doit reproduire fidèlement le même cadre en plus de la créature — un point de friction et d'incohérence potentielle à chaque génération.

## 2. Principe proposé

Séparer le pipeline en deux couches indépendantes :
1. **La créature** — générée seule, détourée, fond transparent, sans décor/environnement.
2. **Le cadre** — un ornement réutilisable, **un par Tier** (5 au total), appliqué dynamiquement au rendu par le jeu plutôt que régénéré à chaque ennemi.

L'image générée pour chaque nouvel ennemi devient donc uniquement la créature détourée — beaucoup plus simple et rapide à produire en volume (25 ennemis du roster précédent) qu'une "carte complète" à chaque fois.

## 3. Décisions validées

- **Le cadre varie par Tier uniquement** pour sa forme/style de base — pas de taxonomie "type" narrative séparée (bête/mort-vivant/élémentaire...). 5 variantes de cadre correspondant aux 5 tiers, vraisemblablement de plus en plus ouvragées/dangereuses à mesure que le tier augmente (échelle visuelle de menace, comme la progression de rareté des cartes).
- **Fond de la fenêtre du cadre** : un fond propre au cadre (parchemin ou sombre uni), pas de transparence totale vers la scène de combat en arrière-plan — rendu prévisible quel que soit le fond de combat/biome en cours (voir `27-07-2026_biomes_finale_sequence_historique_runs_Sonnet5.md`).
- **Assets legacy (Slime/Gobelin/Squelette/Orc)** : restent en cadre-baked-in complet, rendus tels quels. Seul le nouveau contenu utilise le pipeline en couches — deux chemins de rendu coexistent dans `EnemyCard` (dette technique mineure assumée, pas de reprise du passé dans ce chantier).

## 4. Fusion avec les Variantes d'Élite (accent de couleur)

Décision clé : **l'accent de couleur ne forme pas un halo séparé autour de la créature** (comme envisagé initialement dans le doc des tiers) — il s'applique **directement sur l'ornement du cadre lui-même**. Un seul système de coloration au lieu de deux couches superposées :

- Cadre de Tier de base (forme/gravures) + teinte dynamique selon l'Affixe d'Élite éventuellement roulé sur l'instance d'ennemi (`Ardent` = orange, `Foudroyant` = cyan électrique, `Glacial` = blanc-bleuté, `Vampirique` = pourpre sombre, `Parfait` = prismatique).
- Réutilise directement le champ `accentColor` déjà proposé sur `EliteAffixData` (`elite_affixes.json`) dans le doc précédent — zéro nouveau champ de données à inventer pour cette partie.
- **Action de suivi suggérée** (non faite dans ce document) : mettre à jour la section "Rendu visuel" des Variantes d'Élite dans `27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md` pour remplacer la mention de "halo lumineux autour de l'EnemyCard" par un renvoi vers ce document.

## 5. Modèle de données proposé

- Nouveau **`assets/data/enemy_frames.json`** → modèle `EnemyFrameData` :
  - `tier` (1 à 5)
  - `frameAsset` (chemin PNG du cadre, avec une fenêtre/trou transparent au centre)
  - `windowRect` (rectangle en pixels définissant précisément où positionner la créature détourée à l'intérieur du cadre — nécessaire pour un compositing automatique cohérent)
  - `windowBackgroundColor` (fond uni affiché derrière la créature, dans la fenêtre)
- **`EnemyData`** : le nouveau contenu pointe son `spritePath` vers une créature détourée (fond transparent, sans cadre) ; les 4 ennemis legacy gardent leur `spritePath` actuel (image complète) inchangé. Distinction au rendu via une convention à trancher (ex. champ `usesLegacyFullArt: bool`, ou dossier dédié `assets/images/enemies_legacy/` vs `assets/images/enemies/`).

## 6. Rendu Flame (`EnemyCard`)

Pour un ennemi du nouveau pipeline, `EnemyCard.onLoad()` composerait 3 couches dans l'ordre :
1. Fond de fenêtre du cadre correspondant au tier de l'ennemi.
2. Créature détourée, positionnée/mise à l'échelle selon le `windowRect` du cadre.
3. Cadre par-dessus (les bords/ornements recouvrent légèrement les contours de la créature, comme sur les 4 assets actuels où le cadre "mange" un peu l'illustration) — teinté dynamiquement si l'`EnemyInstance` porte une Variante d'Élite.

Pour un ennemi legacy, le chemin de rendu actuel (image complète, tel quel) reste inchangé.

## 7. Effort & risque

- **Code : modéré.** Nouveau modèle + JSON, nouveau chemin de compositing à 3 couches dans `EnemyCard`, coexistence de deux chemins de rendu (legacy vs nouveau), teinte dynamique du cadre (`ColorEffect`/color-blend sur le sprite du cadre — technique déjà utilisée ailleurs dans le projet pour les flashs d'impact).
- **Art : réduit par rapport à une génération "carte complète" par ennemi.** 5 cadres de tier à produire une seule fois, au lieu d'un cadre à redessiner (avec le risque d'incohérence) à chaque nouvel ennemi généré. Gain net important pour le roster de 25 ennemis déjà brainstormé.
- **Risque principal** : aligner précisément le détourage de chaque créature générée avec la `windowRect` du cadre (position/échelle) — nécessite une convention de cadrage stricte au moment de la génération (créature centrée, occupant un pourcentage fixe de la hauteur du canevas source) pour que le compositing tombe juste sans retouche manuelle systématique.

## 8. Points ouverts

- Retouche manuelle (GIMP/Photoshop) de chaque créature générée pour la recadrer/centrer précisément dans la fenêtre du cadre, ou standardisation suffisante du prompt de génération (composition, échelle, cadrage) pour que ça tombe juste automatiquement ?
- Les 5 cadres de tier eux-mêmes : générés par IA (même outil que les créatures) ou dessinés/vectorisés à la main pour garantir une précision pixel-perfect de la fenêtre découpée (probablement préférable vu la fréquence de réutilisation) ?
- Migration éventuelle des 4 assets legacy vers le nouveau pipeline dans une itération future, une fois celui-ci validé sur du contenu neuf ?

## 9. Prochaines étapes possibles

1. Valider ce brainstorm en le confrontant à une première génération réelle (créature détourée + cadre de test) avant d'écrire la moindre ligne de code.
2. Une fois validé, spec dédiée pour le compositing exact dans `EnemyCard` et le format précis de `enemy_frames.json`.
3. Mettre à jour la section "Rendu visuel" des Variantes d'Élite dans `27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md` pour refléter la fusion décrite en §4.
