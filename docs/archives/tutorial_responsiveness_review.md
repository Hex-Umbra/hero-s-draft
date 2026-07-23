# Hero's Draft: Tutorial Responsiveness Review

This report presents a thorough audit of the user interface responsiveness within the tutorial system of **Hero's Draft** (located in `lib/tutorial/`). It addresses current rendering and overflow issues across mobile viewports (both portrait and landscape orientations), web, and desktop windows.

---

## 1. Executive Summary

The tutorial system in Hero's Draft is a core onboarding element containing 13 specialized illustration widgets and a main tutorial wrapper. However, the current layout relies on fixed-flex vertical splits, absolute coordinate mapping, hardcoded margins, and non-scrollable grids. 

This review identifies critical layout weaknesses and outlines a unified technical strategy using Flutter's layout toolkit—specifically `LayoutBuilder`, `OrientationBuilder`, `FittedBox`, `SingleChildScrollView`, and adaptive grid structures—to ensure the tutorial is 100% responsive and visually premium on all form factors.

---

## 2. General Responsiveness Strategy

To resolve the various layout constraints, we define four main responsiveness patterns to be applied throughout the tutorial code:

```mermaid
graph TD
    A[Layout Challenge] --> B{Challenge Type?}
    B -- "Fixed Coordinate Canvas" --> C[FittedBox Scaling Pattern]
    B -- "Dense Grid/Text Badges" --> D[Adaptive Layout / Wrapping Pattern]
    B -- "Limited Height Viewports" --> E[Scrollable Container Pattern]
    B -- "Portrait vs Landscape Split" --> F[LayoutBuilder Orientation Pattern]

    C --> C_Res[Wrap fixed-size canvas in FittedBox to scale details proportionally]
    D --> D_Res[Use Wrap or LayoutBuilder to adjust grid columns and scale font sizes]
    E --> E_Res[Inject SingleChildScrollView with flexible constraints to permit overflows to scroll]
    F --> F_Res[Switch between vertical Column (Portrait) and horizontal Row (Landscape)]
```

### Strategy Patterns

#### 1. The FittedBox "Canvas" Scaling Pattern
* **Use Case**: Highly detailed, absolute-positioned simulation layouts (e.g., Combat Overview, Map Connections, Card Merge animations).
* **Concept**: Instead of rebuilding complex positioning rules for every screen width/height, the entire illustration is defined inside a fixed-size `SizedBox` canvas (e.g., `360x240`) and wrapped in a `FittedBox` with `fit: BoxFit.scaleDown` or `BoxFit.contain`.
* **Benefit**: Guarantees zero text overflows, preserves exact layout relationships, and renders identical proportions on a 320px mobile viewport or a 4K desktop monitor.

#### 2. The Adaptive Layout / Wrapping Pattern
* **Use Case**: Grid views, rarity rows, status effect cards.
* **Concept**: Replacing rigid `Row` structures or static `GridView` layouts with `Wrap` widgets or `LayoutBuilder` columns.
* **Benefit**: Cells automatically wrap to the next line or scale column counts based on width constraints.

#### 3. The Scrollable Container Pattern
* **Use Case**: Multi-line status detail descriptions, horizontally fanned hands, grids.
* **Concept**: Replacing `NeverScrollableScrollPhysics` with `BouncingScrollPhysics` and adding `SingleChildScrollView` containers where height/width might shrink below the sum of the children.
* **Benefit**: Prevents vertical or horizontal clipping on extremely small viewports.

#### 4. The LayoutBuilder Orientation Pattern
* **Use Case**: Main `TutorialScreen` layout structure.
* **Concept**: Dynamically switching layout structure from vertical `Column` (portrait mobile) to horizontal `Row` (landscape mobile, web, desktop).
* **Benefit**: Uses horizontal aspect ratios naturally, avoiding the vertical squishing that ruins mobile landscape gameplay.

---

## 3. Tutorial Screen Layout Audit

### File: `lib/tutorial/tutorial_screen.dart`

#### Specific Issues Found
1. **Rigid Flex Splits**: The layout splits the screen vertically using a `Column` with `Expanded(flex: 6)` for the illustration and `Expanded(flex: 4)` for the description panel.
2. **Mobile Landscape Squishing**: In mobile landscape orientation (e.g., height ~360px), 60% of the height yields a mere 216px for the illustration and 144px for the text. Both containers are forced to render extremely wide and short, triggering severe overflows in every illustration widget.
3. **Underutilized Web/Desktop Width**: Stacking the illustration on top of the text panel on wide screens leaves giant margins on the left/right and forces vertical scrolling on descriptions that could easily fit side-by-side.

#### Actionable Recommendations
* Wrap the layout in a `LayoutBuilder` to detect screen dimensions.
* If the screen width is greater than the height (landscape) or width >= 600px:
  * Switch the layout from a vertical `Column` to a horizontal `Row`.
  * Divide space horizontally: Left 50% for illustration (`Expanded(flex: 5)`), Right 50% for the text description panel (`Expanded(flex: 5)`).
* If the screen is portrait:
  * Maintain the vertical `Column` layout, but enforce a minimum height for the illustration using constraints to prevent clipping on extremely short viewports.

---

## 4. Widget-by-Widget Detailed Review

| Widget Name / File | Specific Issues Found | Recommendations & Changes |
| :--- | :--- | :--- |
| **1. Welcome Widget**<br>`tutorial_welcome_widget.dart` | • Uses a vertical `Column` with fixed spacing (`SizedBox(height: 20/12)`).<br>• On small heights, the icon (size 80) and fonts (size 32) will cause vertical overflow. | • Wrap the outer `Column` in a `FittedBox(fit: BoxFit.scaleDown)` to gracefully shrink the banner on small heights. |
| **2. Map Widget**<br>`tutorial_map_widget.dart` | • Nodes are positioned with absolute, hardcoded pixel offsets (`Offset(160, 220)`, etc.) inside a Stack.<br>• The connections painter and background grid painter use these exact same coordinates.<br>• If the Stack width/height scales up or down, the nodes stay clumped in a 320x260 pixel box, leaving empty space or clipping. | • Wrap the entire map canvas `Stack` in a `SizedBox(width: 320, height: 260)` and enclose it in a `FittedBox(fit: BoxFit.contain)`. This scales the custom painters and absolute positioned nodes as a vector unit. |
| **3. Node Types Widget**<br>`tutorial_node_types_widget.dart` | • Grid uses `crossAxisCount: 3` and a fixed aspect ratio of `1.65`.<br>• On narrow portrait screens, cells become too narrow (under 90px), causing the description text (`fontSize: 9.5`) to wrap into characters or overflow.<br>• Uses `NeverScrollableScrollPhysics`, leading to vertical overflows if height is constrained. | • Wrap the `GridView` in a `LayoutBuilder` to dynamically adjust `crossAxisCount` (2 columns for narrow screens, 3 for medium, 4 for wide screens).<br>• Enable scrolling with `BouncingScrollPhysics` and wrap in a `SingleChildScrollView` to safeguard against low heights. |
| **4. Combat Overview**<br>`tutorial_combat_overview_widget.dart` | • An incredibly dense, compact mock battle interface featuring tiny fonts (`fontSize: 4.5` to `9.0`) and tiny fixed-size cards (`42x58`).<br>• Annotation bubbles have hardcoded top offsets (`top: 55`, `top: 115`). If the height changes, the arrows and descriptions align incorrectly.<br>• Horizontal layout is forced, leading to clipping on narrow screens. | • Wrap the main layout inside a `FittedBox` around a standard `SizedBox(width: 360, height: 260)`. This forces all micro-elements (fonts, cards, bubbles) to scale proportionally and prevents overlaps. |
| **5. Cards Widget**<br>`tutorial_cards_widget.dart` | • Displays a `Row` of cards, each occupying a fixed width of `90`. The hand size is 3, making a total width > 270px, which overflows on narrow screens.<br>• Inside `TutorialUiCard`, a constrained layout with fixed margins risks internal text/icon overlaps if scaled down. | • Wrap the card `Row` inside a `SingleChildScrollView` (horizontal) to allow scrolling on small viewports.<br>• Adjust `TutorialUiCard` internally with `Flexible` and `FittedBox` wrappers on text elements to prevent layout crashes. |
| **6. Play Card Widget**<br>`tutorial_play_card_widget.dart` | • Divides the illustration vertically with flex (5/2/4). On landscape mobile, this results in tiny height allocations, crashing the aspect-ratio cards.<br>• The hand row with 2 cards (width 90 each) plus margins can overflow horizontally. | • Wrap the entire interactive layout in a `FittedBox` with base dimensions `SizedBox(width: 360, height: 280)`. This scales the interactive slime, stats bar, and cards together. |
| **7. Armor Widget**<br>`tutorial_armor_widget.dart` | • Uses a dual-column comparison row. On narrow portrait screens, each side has ~140px width, causing label text and HP bar layouts to wrap and collide.<br>• The simulation columns have hardcoded spacings that overflow on short viewports. | • Wrap the comparison `Row` in a `FittedBox` (or dynamically switch to a vertical column stack on narrow screens using `MediaQuery`). |
| **8. Elements Widget**<br>`tutorial_elements_widget.dart` | • Uses a horizontal `ListView.builder` wrapped in a hardcoded `SizedBox(height: 200)`. If the illustration container height is < 200px (landscape mobile), it throws an immediate layout constraint error. | • Remove the hardcoded height; use `LayoutBuilder` constraints to set height, or wrap the list in a `FittedBox` so it shrinks to fit the parent height constraints. |
| **9. Enemy Intents Widget**<br>`tutorial_enemy_intents_widget.dart` | • Lays out 4 intents in a `Row` using `Expanded`. On narrow screens, columns are ~65px wide, causing French text like "Affaiblissement" to wrap awkwardly.<br>• The detail card height causes vertical overflows. | • Wrap the horizontal intents row in a horizontal scroll view, or use a `FittedBox` inside each intent bubble to scale text down to fit the column width. |
| **10. Merge Widget**<br>`tutorial_merge_widget.dart` | • Card merge animation uses fixed translate offsets (`85` pixels) inside a Stack, which overflows on narrow screens.<br>• Small height viewports cause the aspect-ratio cards to overflow vertically. | • Wrap the animation stack in a `FittedBox` around a standard size container (`SizedBox(width: 320, height: 240)`). This ensures the `85` pixel translation remains proportional to the card size. |
| **11. XP Widget**<br>`tutorial_xp_widget.dart` | • Column layout with level badge, XP bar, and action button. Uses fixed spacings (`SizedBox(height: 24)`).<br>• On short heights, the Column overflows. | • Wrap the Column in a `FittedBox(fit: BoxFit.scaleDown)` or a `SingleChildScrollView` to prevent vertical overflow. |
| **12. Draft Widget**<br>`tutorial_draft_widget.dart` | • Lays out 3 cards horizontally inside `Expanded` cells. On small screens, cards squeeze below readable widths, breaking text layout. | • Wrap the card selection list in a horizontal scroll view or a `FittedBox` to maintain card proportions. |
| **13. Relics Widget**<br>`tutorial_relics_widget.dart` | • Relic card has fixed width of `160`. The rarities legend contains a Row of 4 badges which wraps poorly.<br>• Column overflows on small heights. | • Use a `Wrap` instead of a `Row` for the rarities badges.<br>• Enclose the relic card stack in a `FittedBox` or dynamic layout. |

---

## 5. Actionable Implementation Plan

To implement these changes and guarantee 100% responsiveness, the following steps are proposed:

### Phase A: Core Layout Setup in `tutorial_screen.dart`
Refactor the main scaffolding to use `LayoutBuilder` and switch layout orientation based on aspect ratio:

```dart
// Conceptual snippet for tutorial_screen.dart build method:
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight && constraints.maxHeight < 500 || constraints.maxWidth >= 720;
          
          if (isLandscape) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PageView.builder(
                    // Left Column: Illustrations
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    // Right Column: Text descriptions + Buttons
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                // Top: Illustration (flex: 6)
                // Bottom: Text Panel (flex: 4)
              ],
            );
          }
        },
      ),
    ),
  );
}
```

### Phase B: Standardize Complex Illustration Scaling (The Fitted Canvas)
For widgets with absolute coordinate mapping, animations, or extremely dense interfaces (`Map`, `Combat Overview`, `Play Card`, `Merge`, `Armor`):
1. Wrap the entire contents of the widget's root build method in a `Center` widget.
2. Put a `FittedBox` as the direct child, with `fit: BoxFit.contain`.
3. Wrap the actual layout in a `SizedBox` with standard reference proportions (e.g. `width: 360, height: 250`).
4. This ensures that the widget layout operates inside a mock "virtual resolution" which scales perfectly onto any dynamic container size allocated by the `PageView`.

### Phase C: Safe Grids & Wrapping Elements
For text-heavy elements and grids (`Node Types`, `Intents`, `Relics`):
1. Replace rigid `NeverScrollableScrollPhysics` with scrolling support.
2. Introduce layout thresholds (using `LayoutBuilder` inside widgets) to adapt grid structures.
3. Replace `Row` with `Wrap` for the rarity legend in the Relics screen.
4. Replace rigid card layout rows in `Cards` and `Draft` screens with horizontally scrollable rows to prevent narrow viewport squishing.

---
*Report compiled on 2026-06-02 by flutter_game_designer.*
