import 'dart:math';

/// L'indice du fond de fenêtre d'un ennemi parmi [count] (B87), tiré à la
/// création de la carte.
int pickWindowBackground({required int count, required Random random}) {
  assert(count > 0, 'il faut au moins un fond de fenetre');
  return random.nextInt(count);
}
