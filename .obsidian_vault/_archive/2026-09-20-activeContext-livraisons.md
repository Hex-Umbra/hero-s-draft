# Archive — livraison sortie d'`activeContext.md` le 2026-09-20

Rotation FIFO du plafond de 3 livraisons, provoquée par l'entrée de **P-41 lot C, partie 2**
(PR #43). Texte conservé **verbatim**, tel qu'il figurait dans
`.obsidian_vault/_memory_bank/activeContext.md` avant la passe.

---

3. **P-41 lot B, partie 1 — la Puissance, une seule stat orientée par la classe**
   (2026-09-17, **fusionné dans `main` par la PR #40**, 6 commits,
   `f20c353` → `e9b193d`) — `attackPower`/`skillPower`/`alterationPower` (lot A) fusionnent en une
   seule `might` ; `HeroData.mightTargets` (`class.json`, obligatoire) déclare ce qu'elle renforce,
   copié dans `EntityStats.mightTargets` à la création du héros ; `PowerRules` lit cette copie sans
   changer la forme de ses huit appels. Le statut `strength` devient `might` (`gain_might`,
   `charge_might_turn`, `charge_might_combat`), `applyAttackBuff` (code mort) supprimé. Tous les
   textes joueur disent Puissance/Might ; le sous-titre de la fiche de stats liste ce qu'elle
   renforce (`Set<MightTarget>.shortLabel`). **Comportement de jeu inchangé** : les trois classes
   ciblent `attack`. **Aucune migration de sauvegarde** (spec §7.5) : `SaveMigrator` reste en
   version 2, son étape v1→v2 garde `attackPower` en format gelé, désormais ignoré à la lecture.
   938 tests (+15), `dart analyze` propre. Voir
   [ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md) (amende la décision 2 d'ADR-095).

---

## Réserves closes, sorties dans la même passe

Quatre réserves du focus courant décrivaient des situations **déjà résolues** : elles étaient
devenues de l'historique, pas des points de vigilance. Conservées verbatim.

- **Les trois décisions du propriétaire du 2026-09-15 sont intégrées à `main`** par la PR #37 :
  changements visibles ajoutés à la note `0.5.1` (`2d19d42`), cartes abîmées par l'ancienne fusion
  de légendaires réparées au chargement (`71d97cb`), corpus `docs/formation-heros-draft/` figé en
  instantané daté (`69fef58`). Plus aucune branche de P-40 n'est en attente.
- **Un dossier de classe `gambler` vide**, laissé par une écriture de l'éditeur, faisait rougir deux
  tests sur `main`. Supprimé le 2026-09-15 ; `entity_writer.dart` tient ce cas pour « sans conséquence ».
- **Les changements visibles de P-30 ont rejoint la note `0.5.1`** (`d8d9319`, décision du
  propriétaire le 2026-09-14) : bouton « Quitter », retours arrière, fin du badge « NEW »,
  illustration de classe. Rien sur le menu de debug ni l'éditeur, absents des builds publiés.
- **La modification d'entité par l'éditeur** est testée (`47f6731`, `25b2945`), sans passe dédiée consignée.
