import 'package:flutter/material.dart';

/// La coque commune du contrat de choix (spec D9), partagee par `ChoiceButton`,
/// `EditorSegmented`, l'onglet de type et l'entite de l'explorateur : un fond
/// opaque de cle `editeur-bouton-fond`, un `Semantics` qui se dit choisi, et
/// un `InkWell` dont l'encre se voit au survol et au focus.
///
/// Sans le `Material` transparent pose ici entre le fond et l'`InkWell`,
/// l'encre du survol et du focus peint sur le `Material` du `Scaffold`, sous
/// le fond opaque — donc jamais visible. `EditorButton` faisait deja ainsi ;
/// cette coque evite de le reecrire a chaque element selectionnable.
class ChoiceSurface extends StatelessWidget {
  const ChoiceSurface({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.decoration,
    required this.padding,
    required this.child,
    this.borderRadius,
    this.tapKey,
    this.height,
  });

  final bool isSelected;
  final VoidCallback onTap;

  /// Le fond de la cle `editeur-bouton-fond` : couleur, bordure, soulignement
  /// selon l'appelant — cette coque ne le change pas.
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final Widget child;

  /// Le rayon de la tache d'encre — le meme que celui, eventuel, du fond dans
  /// [decoration].
  final BorderRadius? borderRadius;

  /// Posee sur la zone touchable, pas sur le fond : certains appelants la
  /// cherchent pour designer un segment precis.
  final Key? tapKey;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      child: Container(
        key: const Key('editeur-bouton-fond'),
        height: height,
        decoration: decoration,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: tapKey,
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
