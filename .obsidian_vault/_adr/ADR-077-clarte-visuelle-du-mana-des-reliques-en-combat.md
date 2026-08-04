## ⚡ ADR-077 : Clarté Visuelle du Mana des Reliques en Combat (v3.0.1)

> [!NOTE]
> Renumeroté de `ADR-069` en `ADR-077` le 2026-08-03 : le numero `ADR-069` etait porte par deux decisions distinctes. Voir `docs/superpowers/specs/2026-08-03-documentation-overhaul-design.md` §2.1.

### Statut
✅ Accepté & Implémenté (v3.0.1)

### Contexte
Dans *Hero's Draft*, certaines reliques (telles que le Cristal de Mana) octroient du mana supplémentaire temporaire en début de combat ou au début d'un tour. Auparavant, l'indicateur de mana (`ManaIndicator`) dans le HUD de combat limitait l'affichage du mana aux seuls points de mana maximum (`maxMana`) du héros. Si un joueur disposait de 4 manas avec un `maxMana` de 3, le quatrième cristal n'était pas dessiné, masquant ainsi visuellement une ressource cruciale. De plus, il n'existait aucune distinction graphique entre le mana de base et le mana additionnel issu des reliques, ce qui nuisait à la clarté tactique du jeu. Enfin, l'accumulation de points de mana risquait de provoquer des débordements d'interface (RenderFlex overflow) sur les écrans étroits.

### Décision
1. **Calcul Dynamique du Total d'Icônes** : Utiliser `max(currentMana, maxMana)` pour calculer le nombre total de diamants de mana à afficher, garantissant que tout point de mana temporaire au-dessus du maximum soit rendu à l'écran.
2. **Ajustement Automatique de Taille (Responsive HUD)** : Recalculer dynamiquement la taille de base des cristaux (`baseSize`) en fonction du nombre total d'icônes à afficher afin d'empêcher les débordements sur le panneau HUD.
3. **Séparation Visuelle Thématique** :
   - Pour les indices de mana de base (index < `maxMana`) : Afficher les cristaux standards (diamant plein, `cyanAccent` si actif, `white24` si inactif).
   - Pour les indices de mana supplémentaire (index >= `maxMana`) : Afficher un cristal de relique distinct sous forme de diamant vide à bordure cyan et fond noir. Ce rendu est réalisé avec un `Stack` contenant un `Icons.diamond` noir (pour masquer l'arrière-plan du HUD) et un `Icons.diamond_outlined` cyan (avec effet de lueur) en premier plan.
4. **Consommation Prioritaire** : Confirmer que la logique métier de Riverpod consomme le mana supplémentaire de relique de manière transparente et prioritaire lors du jeu de cartes, l'affichage se mettant à jour réactivement.

### Preuves dans le code
- [mana_indicator.dart](../../lib/ui/widgets/hud/mana_indicator.dart) :
  - Utilisation de `max(currentMana, maxMana)` pour déterminer la longueur de la liste d'icônes.
  - Calcul dynamique de `baseSize` (par exemple : `double baseSize = totalIcons > 5 ? (200 / totalIcons).clamp(16.0, 24.0) : 24.0;`).
  - Condition d'affichage :
    ```dart
    if (index >= maxMana) {
      // Rendu du diamant de relique (Stack avec Icons.diamond noir et Icons.diamond_outlined cyan)
    } else {
      // Rendu standard (Icons.diamond plein ou translucide)
    }
    ```

### Conséquences
- ✅ **Visibilité des ressources** : Le joueur visualise instantanément le mana supplémentaire octroyé par les reliques et son épuisement progressif.
- ✅ **Clarté tactique accrue** : Le contraste visuel fort (fond noir/vide contre cristal plein) permet de distinguer immédiatement les bonus temporaires de la réserve de base.
- ✅ **Robustesse de l'UI** : L'adaptation de la taille de base des icônes élimine tout risque de RenderFlex overflow ou de clipping sur les petits viewports.
- ✅ **Stabilité statique** : Code vérifié et validé avec 0 erreur par le linter Flutter.
