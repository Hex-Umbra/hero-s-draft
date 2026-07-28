# Cadre d'Ennemi Procédural (Bordure + Icônes Vectorielles, sans PNG)

**Date** : 28/07/2026
**Contexte** : Alternative à `28-07-2026_cadre_ennemi_modulaire_par_tier_Sonnet5.md` (cadre en PNG par tier). Cette approche explore un rendu **100% procédural** (Canvas), sans produire aucun asset image de cadre, en reprenant deux patterns déjà en place dans le projet : `PolychromaticBorder` (bordure adaptative à la taille du widget) et `EffectIcon` (icônes vectorielles dessinées à la main).
**Statut** : Brainstorm — conception fonctionnelle validée par échange, **rien encore implémenté**.
**Décision de contexte assumée** : le jeu est en phase alpha ; un écart avec l'identité visuelle actuelle des 4 ennemis (portraits illustrés à cadre organique) est explicitement accepté au profit d'une identité "UI systémique", cohérente avec le halo de rareté des cartes déjà en place.

---

## 1. Principe

`EnemyCard` (100×140 en combat) enveloppe le sprite de la créature d'un overlay Canvas qui dessine :
- Une **bordure** dont la couleur/épaisseur est pilotée par le **Tier** de l'ennemi.
- **4 icônes vectorielles aux coins**, pilotées par l'**affinité élémentaire** de l'ennemi (Physique / Feu / Givre / Foudre / Poison).
- Une **légère animation continue** (scintillement/pulsation douce), cohérente avec le reste du rendu Flame déjà "vivant" (flottement de texte, particules).

Aucun asset PNG à produire ou régénérer — tout est dessiné au runtime, à la taille réelle du sprite.

## 2. Pourquoi procédural plutôt que PNG (rappel du compromis)

Élimine le problème d'alignement `windowRect` identifié comme risque principal du doc PNG précédent : la bordure épouse automatiquement la taille réelle du sprite quel que soit son ratio, exactement comme `PolychromaticBorder` le fait déjà pour `UiCard` (`CustomPainter` dessinant sur `Offset.zero & size`, où `size` vient du widget enfant enveloppé). Coût de production art proche de zéro. Contrepartie assumée : rendu plus "élément d'interface systémique" que "portrait de bestiaire peint" — accepté explicitement (phase alpha).

## 3. Précédents concrets réutilisés

| Pattern existant | Fichier | Ce qu'on en reprend |
|:---|:---|:---|
| Bordure adaptative à la taille du widget | `lib/ui/widgets/ui_card/polychromatic_border.dart` | `CustomPainter` sur `Offset.zero & size`, `RRect.fromRectAndRadius`, couleur pilotée par un paramètre (`rarityColor` → `tierColor`) |
| Icônes vectorielles dessinées à la main | `lib/game/components/effect_icon.dart` | Formes déjà codées pour `burn`/`fire`, `freeze`/`cold`/`ice`, `shock`/`lightning`, `poison`/`debuff` — **directement réutilisables** pour Feu/Givre/Foudre/Poison. Seule l'icône "Physique" (ex. épées croisées) reste à dessiner, dans le même style vectoriel. |

## 4. Modèle de données

- Nouveau champ **`elementalAffinity`** sur `EnemyData` (`physical` / `fire` / `frost` / `lightning` / `poison`) — détermine l'icône de coin. Absent = `physical` par défaut, rétrocompatible avec les 4 ennemis actuels et les 25 candidats de `27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md`.
- Nouvelle extension **`EnemyTier.color`** (ou getter statique équivalent, même esprit que `CardRarity.color`/`RelicRarity.color`) mappant chaque tier 1-5 à une couleur/épaisseur de trait de bordure.
- Le champ **`accentColor`** de `EliteAffixData` (déjà défini dans la section Variantes d'Élite du doc des tiers) **override** la couleur de tier quand l'ennemi porte une Variante d'Élite — aucune redéfinition de données nécessaire, ce document ne fait que consommer ce qui existe déjà sur le papier.

## 5. Composant de rendu proposé

- Nouveau composant Flame (ex. `EnemyTierFrame`), dans l'esprit de `CardRenderer`/`EffectIcon` : une surcharge `render(Canvas canvas)` directement sur le `PositionComponent`, plutôt qu'un `CustomPainter` Flutter pur (`EnemyCard` étant déjà un composant Flame, pas un widget Flutter).
- 4 icônes positionnées aux coins, taille fixe (~16-20px à l'échelle 100×140 du combat) pour rester lisibles — nettement plus petit que les portraits actuels (1696×2528), donc à valider visuellement sur prototype avant de figer la taille définitive.
- Les formes vectorielles de `EffectIcon` (`_drawVector`) devraient être extraites en fonctions statiques partagées plutôt que dupliquées, pour éviter la duplication de code entre les popups d'effet de combat et ce nouveau cadre.

## 6. Animation

- **Décision validée : toujours légèrement animé**, pas seulement au survol (contrairement à `PolychromaticBorder` sur les menus) ni réservé aux Variantes d'Élite — cohérent avec le reste du rendu Flame en combat (particules, flottement de texte, cartes).
- **Deux paliers d'intensité proposés** : scintillement subtil en continu pour un ennemi normal (tier seul) ; pulsation plus marquée/rapide en cas de Variante d'Élite (même mécanisme, amplitude et fréquence supérieures) — signal visuel clair de danger accru sans système de rendu séparé.

## 7. Effort & risque

- **Code : petit-moyen.** Un nouveau composant de rendu Canvas, extraction des formes vectorielles existantes d'`EffectIcon` en fonctions réutilisables, deux nouveaux champs de données (`elementalAffinity`, mapping couleur par tier). **Aucun nouvel asset à produire.**
- **Risque principal : performance.** Une animation continue sur jusqu'à 5 `EnemyCard` actifs simultanément (+ la réserve `pendingEnemies` qui remonte au fil des éliminations) ajoute un coût de re-render par frame pour chacun. L'audit d'animations précédent (`25-07-2026_animations_juice_analysis_Opus5.md`) a déjà identifié des points chauds de performance ailleurs dans le rendu Flame (spawn de particules non throttlé, ~18 `MaskFilter.blur`/frame pendant le ciblage) — cet effet doit être conçu avec cette contrainte en tête dès le départ, pas corrigé après coup. Un profilage rapide sur prototype est requis avant de généraliser.
- **Risque secondaire : lisibilité à petite taille.** 100×140px en combat est nettement plus petit que les portraits actuels — les 4 icônes de coin doivent rester identifiables à cette échelle.

## 8. Relation avec les autres brainstorms

- **Alternative**, pas complément, à `28-07-2026_cadre_ennemi_modulaire_par_tier_Sonnet5.md` (cadre PNG par tier) — les deux documents restent côte à côte comme deux options explorées ; à trancher au moment de la priorisation plutôt que dans ce document.
- Consomme directement le champ `accentColor` déjà défini pour les Variantes d'Élite dans `27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md`, section "Variantes d'Élite Adaptatives" — aucune redéfinition nécessaire.

## 9. Points ouverts

- Les 4 ennemis legacy (Slime/Gobelin/Squelette/Orc) : contrairement à l'option PNG, cette approche ne nécessite aucune régénération d'asset de cadre — faut-il donc en profiter pour les faire migrer aussi (juste détourer leur créature une fois), plutôt que de les laisser en legacy ?
- Faut-il un 5ème emplacement (blason central, en plus des 4 coins) réservé à un usage futur (ex. indicateur visuel du Boss de Cycle de la Finale de Séquence) ?
- Confirmer le budget de performance réel via un prototype avant de généraliser l'animation continue à tous les ennemis simultanément.

## 10. Prochaines étapes possibles

1. Prototype rapide sur un seul ennemi (ex. Gobelin) pour valider lisibilité des icônes à 100×140px et coût de performance réel avant d'investir plus loin.
2. Trancher entre cette approche et le cadre PNG (`28-07-2026_cadre_ennemi_modulaire_par_tier_Sonnet5.md`) une fois le prototype vu en jeu.
3. Étendre `assets/data/enemies.json` avec `elementalAffinity` pour le roster actuel et les 25 candidats du doc de tiers, une fois l'approche retenue.
