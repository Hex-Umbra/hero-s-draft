### 5.12. Barre de Signatures — le `RenderBox` de la Bande et le Calque `OverlayPortal`

`lib/ui/widgets/hud/signature_bar.dart` — la colonne des signatures au milieu gauche de l'écran de
combat, en miroir du bouton de fin de tour. Livrée par le lot E4 de P-43
([ADR-109](../_adr/ADR-109-signatures-hors-du-deck.md)), reprise par la vague 5 (P-42 tranche 1,
partie 3, en attente du propriétaire — [ADR-114](../_adr/ADR-114-les-evolutions-de-signature.md)) :
la tuile perd son texte pour une bande d'icônes, gagne un badge et des puces, et déroule sa liste à
l'appui long. Règle de jeu : [`_rules/02-8`](../_rules/02-8-evolutions-de-signature.md) §2.8.4.

> [!IMPORTANT]
> **La barre est sans état de jeu** : `SignatureBar` est un `StatelessWidget` ; tout vient de
> l'appelant (`GameScreen`), qui relie les gestes au moteur. L'état d'une tuile est calculé par une
> fonction pure, `signatureTileStateOf` — inactive, en recharge, sans le mana, armée, disponible, la
> première qui s'applique l'emporte —, la seule partie de la barre qu'un test garde
> (`test/widget/signature_bar_test.dart`, gardé par le tri de D77). Le reste se vérifie au test
> manuel ([ADR-113](../_adr/ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md)).

#### 5.12.1. La bande : un `RenderBox` qui connaît sa transformation dès la mise en page

La colonne doit tenir entre la barre du haut et le panneau des statuts, centrée, réduite au besoin
jusqu'à 0,75 (A38). Un `Transform` ou un `FittedBox` ne donnait pas la transformation à la mise en
page, et le calque de la liste (§5.12.2) en a besoin pour se poser sur la tuile.

| Pièce | Rôle |
|:---|:---|
| `signatureBandPlacement({available, natural})` | Fonction pure : l'échelle (`band / natural`, bornée à [0,75, 1]) et le haut (à mi-hauteur, remonté s'il sortait par le bas, jamais au-dessus de `CombatTopBar.bandTop`) |
| `_SignatureBandLayout` / `_RenderSignatureBand` | `RenderBox` à un enfant : la colonne est mesurée à sa hauteur naturelle, largeur seule bornée ; `performLayout` calcule `_transform` (décalage de 20 px, haut, échelle) |
| `paint` | `context.pushTransform(_transform)` — la peinture lit la transformation calculée |
| `applyPaintTransform`, `hitTestChildren` | La même matrice : le toucher tombe sur la tuile peinte, et un descendant (le calque) connaît sa place à l'écran |

> [!NOTE]
> **L'échelle se lit sur la largeur transformée**, `transformRect(...).width / childSize.width` :
> `Matrix4.getMaxScaleOnAxis` lit aussi l'axe Z, laissé à 1 par la barre, et rendrait 1 sur une
> barre réduite (S20, corrigé avant la Task 9).

#### 5.12.2. La liste de l'appui long : un calque `OverlayPortal`

La liste complète d'une signature passe **par-dessus les tuiles voisines** sans déplacer la colonne
ni en changer l'échelle (PN12 (d), A42).

- **`OverlayPortal.overlayChildLayoutBuilder`**, un `OverlayPortalController` par tuile : le calque
  reçoit `OverlayChildLayoutInfo` — la taille de la tuile au repos et sa transformation de
  peinture —, et `_ExpandedTileLayout` (un `SingleChildLayoutDelegate`) y pose la tuile déployée à
  l'échelle et au haut de la tuile, à sa largeur, **jamais moins haute qu'elle** ; vers le bas si
  elle tient, sinon vers le haut, son bas au bas de la tuile.
- **Le calque ne capte rien** (`IgnorePointer`) : la tuile seule répond. `onLongPressStart`
  l'ouvre, `onLongPressEnd` et `onLongPressCancel` la ferment ; la fermeture est gardée
  (`if (_list.isShowing)`), un appui court ou un démontage appelant aussi `onLongPressCancel`.
- **L'appui long ne lit pas l'état** : la liste s'ouvre sur une tuile inactive (P-5 (a)) ; il ne
  joue, n'arme ni ne désarme rien. L'appui court garde son rôle.
- **Sous la liste, la tuile ne se soulève pas au survol et retombe d'un coup** (`Duration.zero`) :
  soulevée, ou en 100 ms, elle déborderait du calque posé à sa taille au repos (S21).

#### 5.12.3. Ce que la tuile lit

| Élément | Source |
|:---|:---|
| Bande d'icônes et liste | `SignatureInstance.effectLines` — sorte, valeur, durée, lues sur la vue évoluée ; **aucun widget ne recalcule une valeur** (A40) |
| Icône et couleur d'une sorte | `EffectIconTable` du registre, traduite par `effect_style.dart` ([`_patterns/05-13`](05-13-table-d-icones-d-effet.md)) |
| Phrase d'une ligne | `effect_line_texts.dart`, une clé ARB par sorte (13 clés) |
| Badge « Niv. n » | `SignatureInstance.level` ; `Colors.amberAccent` quand la tuile répond, `white38` sinon (PN13) |
| Puces d'évolution | `SignatureInstance.taken`, dans l'ordre de première prise ; l'icône d'une majeure dans son anneau ; le chiffre de niveau d'une mineure à sa droite, à la taille du badge (S20) |
| Coût, accessibilité | La vue évoluée et `CostRules.canPay` — la barre n'a plus de règle de mana propre |
