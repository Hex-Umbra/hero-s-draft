# Vague 5 : tri des tests d'ecran (D77)

Branche `feat/v0.5.7-p42-tranche-1-p44-lot-1`, 04/11/2026.

## La regle

D77 (brainstorm v3, section 1) : un jeu se teste a la main. Les tests automatiques gardent seulement ce qu'un agent, qui ne joue pas, ne verrait pas autrement : les calculs, les donnees (chargement, integrite referentielle, conventions d'id, `sync_assets`), les controleurs et la sauvegarde. Un test qui ne fige que de l'affichage (mise en page, position, taille, opacite, couleur, duree d'animation, presence d'un widget, texte affiche) est supprime. Un test qui garde une regle de jeu ou de donnees que nul autre test ne garde est conserve.

Critere pratique, test par test : « si ce test devenait rouge, le proprietaire le verrait-il tout de suite en jouant a l'ecran concerne ? » Oui : supprime. Non (un chiffre faux de quelques %, un cas rare, une donnee corrompue, une sauvegarde perdue, une regle d'etat) : garde.

Methode : le tri est fait test par test. Pour chaque test d'ecran dont le nom laissait croire a une regle, on a cherche si un test unitaire la garde deja ; si oui, le test d'ecran est supprime, la regle reste gardee ailleurs (la colonne de droite nomme ce test). Aucun test n'a ete reecrit : les regles sans autre garde sont conservees telles quelles.

## Comptes

Mesures par `flutter test` (compte des tests executes, boucles comprises) :

| | avant | apres |
|:---|---:|---:|
| Suite entiere | 1916 | 1510 |
| dont `test/widget/` + `test/tutorial/` + `test/encounter_system_test.dart` + les 4 fichiers `test/unit/` d'affichage supprimes | 556 | 150 |

406 tests supprimes. Fichiers de test supprimes entiers : 50, plus l'aide `test/widget/content_editor/contrast.dart`, devenue sans lecteur. Fichiers allegés : 9. Fichiers inchanges dans le perimetre : 6 (+ les 8 fichiers `test/unit/` de libelles, en fin de tableau). `dart analyze` : `No issues found!`. `flutter test` : `All tests passed!`.

Colonnes : tests avant, gardes, supprimes (comptes d'execution), puis ce que gardent les tests gardes (la regle), ou « affichage seul » pour un fichier entierement supprime.

## Le tableau

| fichier | tests avant | gardes | supprimes | ce que gardent les tests gardes (la regle) |
|:---|---:|---:|---:|:---|
| `test/encounter_system_test.dart` | 25 | 25 | 0 | calculs : budget, plafonds d'ennemis par acte, paliers de tier, multiplicateurs de PV et de degats, reserve de vagues ; intact |
| `test/tutorial/tutorial_engine_test.dart` | 52 | 52 | 0 | moteur du tutoriel : vrais calculs de degats et d'armure, identite de classe, choix du passif, XP, fusion, semis des etapes, fin de tour ; intact |
| `test/tutorial/tutorial_fixtures_test.dart` | 15 | 15 | 0 | donnees : les fixtures du tutoriel existent, proprietes dont la pedagogie depend, echec franc sur id absent ; intact |
| `test/tutorial/tutorial_isolation_test.dart` | 2 | 2 | 0 | isolation du moteur (aucun import Riverpod hors du pont) ; intact |
| `test/tutorial/tutorial_prose_test.dart` | 12 | 8 | 4 | gardes : les placeholders de la prose sont remplis depuis le catalogue (noms, ordre declare, virgules et conjonction, anglais, paliers de la courbe d'XP, texte sans placeholder inchange). Supprimes : quatre tests de prose figee (deck de depart 2 + 3, signatures mot pour mot, Fusion, Gel) |
| `test/tutorial/tutorial_screen_bold_text_test.dart` | 3 | 0 | 3 | affichage seul (decoupage du gras) |
| `test/unit/card_text_renderer_layout_test.dart` | 2 | 0 | 2 | affichage seul (centrage du bloc central de la carte) |
| `test/unit/floating_text_test.dart` | 1 | 0 | 1 | affichage seul (opacite du texte flottant) |
| `test/unit/heros_draft_game_targeting_test.dart` | 7 | 0 | 7 | entrees Flame (ciblage au toucher) : le proprietaire le voit des qu'il joue |
| `test/unit/might_icon_test.dart` | 3 | 0 | 3 | affichage seul (icone de Puissance, lecture du source) |
| `test/widget/boss_card_draft_screen_test.dart` | 3 | 0 | 3 | affichage seul (5 cartes, compteur, confirmation) |
| `test/widget/card_dictionary_order_test.dart` | 3 | 3 | 0 | regle d'ordre : groupes independants de l'ordre du catalogue, cartes par rarete puis cout puis id, reliques par id ; intact |
| `test/widget/card_dictionary_screen_test.dart` | 5 | 0 | 5 | affichage seul (onglets, groupes, libelles) |
| `test/widget/class_identity_test.dart` | 11 | 0 | 11 | affichage seul (couleur, degrade, pastille et image de classe) |
| `test/widget/class_selection_screen_test.dart` | 66 | 0 | 66 | affichage seul (cartes de classe, depli des passifs, mise en page) ; l'acces aux passifs est garde par passive_availability_test |
| `test/widget/combat_top_bar_test.dart` | 5 | 0 | 5 | affichage seul (icone de son, indicateur d'acte) |
| `test/widget/content_editor/asset_field_test.dart` | 6 | 0 | 6 | affichage seul (champ de ressource) |
| `test/widget/content_editor/choice_button_test.dart` | 4 | 0 | 4 | affichage seul (lisibilite des puces) |
| `test/widget/content_editor/choice_surface_test.dart` | 4 | 0 | 4 | affichage seul (Material sous le fond) |
| `test/widget/content_editor/color_field_test.dart` | 4 | 2 | 2 | conversions couleur <-> JSON (#RRGGBB, alpha ignore, valeur refusee). Supprimes : contraste du texte et champ couleur |
| `test/widget/content_editor/document_form_test.dart` | 20 | 9 | 11 | ce que le formulaire fait au document : entier ou faute, liste non liste corrigee, cle inconnue gardee, Ajouter clone le modele, references cochees dans l'ordre du catalogue et cle retiree quand vide, paire bilingue non textuelle conservee, ni id ni prose ni skills en champs, ressource hors mecanique. Supprimes : mise en page, rangees, couleurs, ancres, bordures |
| `test/widget/content_editor/editor_action_bar_test.dart` | 7 | 0 | 7 | affichage seul (bandeau d'issue, barre d'actions) |
| `test/widget/content_editor/editor_primitives_test.dart` | 10 | 0 | 10 | affichage seul (rangees de propriete, boutons, ancres) |
| `test/widget/content_editor/editor_segmented_test.dart` | 3 | 0 | 3 | affichage seul (segments) |
| `test/widget/content_editor/editor_toolbar_test.dart` | 5 | 1 | 4 | libelle calcule : shortRoot reduit le depot a ses deux derniers dossiers. Supprimes : onglets, soulignement, barre |
| `test/widget/content_editor/entity_explorer_test.dart` | 5 | 0 | 5 | affichage seul (explorateur d'entites) |
| `test/widget/content_editor/reference_panel_test.dart` | 3 | 0 | 3 | affichage seul (panneau de references) |
| `test/widget/content_editor_screen_test.dart` | 56 | 27 | 29 | ce que l'editeur ecrit ou refuse d'ecrire sur disque : brouillon fautif refuse sans rien ecrire, creation relique et classe (signatures, passif de depart, sans son ni image), doublons de signatures, Valider juge le document que Ecrire ecrira, saisie non entiere, vue brute intacte, effet ajoute, son choisi et retire, mode Modifier (Charger, Ecrire refuse sans charge, cle inconnue gardee), tous les imports (son, image, icone, fichier ignore apres changement, faute non repetee). Supprimes : navigation, lisibilite, couleurs, alignement, relecture du disque, compteurs de signatures |
| `test/widget/debug_drawer_test.dart` | 8 | 1 | 7 | regle : la derniere cible de Puissance ne peut pas etre retiree (etat que HeroData.fromJson refuserait de relire). Supprimes : contenu et ouverture du tiroir |
| `test/widget/deck_screen_test.dart` | 11 | 0 | 11 | affichage et flux de fusion ; fusion, rang et plafond gardes par deck_controller_test, decoupled_forge_test, forge_rune_rules_test |
| `test/widget/draft_card_reel_test.dart` | 3 | 0 | 3 | affichage seul (rouleau) |
| `test/widget/draft_screen_test.dart` | 8 | 0 | 8 | affichage et flux du draft (Transcendance, Maitrise) ; regles gardees par level_up_reward_*_test et draft_choice_labels_test |
| `test/widget/enemy_intents_panel_overflow_test.dart` | 6 | 0 | 6 | affichage seul (debordement) |
| `test/widget/event_screen_test.dart` | 10 | 0 | 10 | affichage et flux ; conditions et effets des evenements gardes par event_controller_test |
| `test/widget/forge_fusion_screen_test.dart` | 8 | 0 | 8 | affichage et flux du Puits ; regles gardees par forge_rune_rules_test et run_controller_test (exchangeRune) |
| `test/widget/forge_upgrade_dialog_test.dart` | 3 | 0 | 3 | affichage seul (lignes de runes, boutons) |
| `test/widget/game_dialog_test.dart` | 3 | 0 | 3 | affichage seul (mise en page 320 px) |
| `test/widget/home_screen_menu_test.dart` | 6 | 0 | 6 | affichage seul (menu, QUITTER par plateforme, retours) |
| `test/widget/home_screen_save_test.dart` | 5 | 1 | 4 | sauvegarde : une partie ecrite par une version plus recente est expliquee et conservee, pas effacee. Supprimes : visibilite de CONTINUER, confirmation Nouvelle Partie |
| `test/widget/hud_and_targeting_badge_test.dart` | 11 | 0 | 11 | affichage seul (badges de ciblage, dimensions du HUD) |
| `test/widget/mana_indicator_test.dart` | 1 | 0 | 1 | affichage seul |
| `test/widget/map_screen_test.dart` | 6 | 0 | 6 | affichage seul (noeuds, pause, barre d'XP) |
| `test/widget/player_health_bar_test.dart` | 1 | 0 | 1 | affichage seul |
| `test/widget/probabilities_dialog_test.dart` | 5 | 0 | 5 | affichage seul (texte des chances ; le calcul est garde par probabilities_test) |
| `test/widget/relic_exchange_screen_test.dart` | 4 | 0 | 4 | affichage et flux ; l'echange est garde par relic_exchange_test |
| `test/widget/rest_card_selection_screen_test.dart` | 6 | 0 | 6 | affichage seul (cartes grisees, motifs) ; eligibilite des runes gardee par rune_eligibility_test |
| `test/widget/rest_screen_test.dart` | 11 | 2 | 9 | calcul : SE REPOSER rend 30 % des PV max (arrondi), borne aux PV max. Supprimes : boutons, Affuter, Oublier, retour systeme |
| `test/widget/settings_screen_test.dart` | 3 | 0 | 3 | affichage seul ; reglages gardes par audio_settings_test |
| `test/widget/sharpen_rune_dialog_test.dart` | 10 | 0 | 10 | affichage ; cout et plafond de l'affutage gardes par forge_rune_rules_test et run_controller_test |
| `test/widget/shop_screen_test.dart` | 4 | 0 | 4 | affichage et flux ; prix, relance, Miroir, copie du deck, etal retenu gardes par shop_controller_test |
| `test/widget/signature_bar_test.dart` | 17 | 1 | 16 | regle : priorite des etats d'une tuile de signature (inactive, recharge, mana, armee, disponible). Supprimes : 16 tests de tuile (mise en page, survol, gestes) |
| `test/widget/signature_tile_test.dart` | 5 | 0 | 5 | affichage seul (tuile) |
| `test/widget/starter_deck_draft_order_test.dart` | 1 | 1 | 0 | regle d'ordre : le pool du draft de depart suit rarete, cout, id, pas la declaration ; intact |
| `test/widget/starter_deck_draft_screen_test.dart` | 6 | 0 | 6 | affichage et flux ; pool garde par card_offer_filter_test, ordre garde par starter_deck_draft_order_test |
| `test/widget/stats_dialog_test.dart` | 2 | 0 | 2 | affichage seul (texte de Maitrise) ; libelles gardes par draft_choice_labels_test |
| `test/widget/status_effects_panel_overflow_test.dart` | 6 | 0 | 6 | affichage seul (debordement, lignes) |
| `test/widget/tutorial_armor_step_test.dart` | 6 | 0 | 6 | affichage ; regles gardees par tutorial_engine_test (armure, conversion, statuts remis a zero) |
| `test/widget/tutorial_class_step_test.dart` | 6 | 0 | 6 | affichage ; choix de classe et de passif gardes par tutorial_engine_test |
| `test/widget/tutorial_elements_widget_test.dart` | 2 | 0 | 2 | affichage seul (bareme en texte) |
| `test/widget/tutorial_merge_transition_test.dart` | 1 | 0 | 1 | affichage seul (pas d'exception au passage d'etape) |
| `test/widget/tutorial_merge_widget_test.dart` | 2 | 0 | 2 | affichage seul |
| `test/widget/tutorial_play_card_step_test.dart` | 2 | 0 | 2 | affichage seul |
| `test/widget/tutorial_starter_draft_test.dart` | 6 | 0 | 6 | affichage ; deck de depart garde par tutorial_engine_test |
| `test/widget/ui_card_rune_sockets_test.dart` | 4 | 0 | 4 | affichage seul (prises de runes) |
| `test/widget/ui_card_values_test.dart` | 15 | 0 | 15 | affichage ; valeurs par rarete et runes gardees par effective_card_test et card_text_renderer_test |
| `test/unit/card_rule_texts_test.dart` | 4 | 4 | 0 | libelle choisi par regle (ratio, coups, couts) ; intact |
| `test/unit/card_text_renderer_test.dart` | 3 | 3 | 0 | total affiche = total calcule (valeur x coups, scaleWith, infobulle) ; intact |
| `test/unit/draft_choice_labels_test.dart` | 7 | 7 | 0 | quel texte selon la valeur tiree, le passif actif, perPoint, le repli ; intact |
| `test/unit/flame_image_prefix_test.dart` | 3 | 3 | 0 | chargement : prefixe vide, cache non global, 8 images sous des cles egales a leur chemin ; intact (donnees) |
| `test/unit/hero_display_order_test.dart` | 2 | 2 | 0 | ordre d affichage des classes (regle) ; intact |
| `test/unit/might_targets_label_test.dart` | 2 | 2 | 0 | ordre des cibles de Puissance quel que soit le Set ; intact |
| `test/unit/might_targets_long_label_test.dart` | 5 | 5 | 0 | jointure selon le nombre de cibles (pas de joint, et, virgule puis et) ; intact |
| `test/unit/stat_rule_label_test.dart` | 5 | 5 | 0 | pluriel de la duree, texte propre au mana, taux et exemple a 0,5 ; intact |

Les autres fichiers de `test/unit/` ont ete parcourus par leur nom et par une recherche de `testWidgets`, `pumpWidget`, des imports `ui/` et `game/components` : aucun autre test d'affichage n'y figure (les imports `ui/` de `draft_choice_labels_test`, `card_text_renderer_test`, `notification_notifier_test` et `referential_integrity_test` servent des fonctions pures ou un controleur).

## Cas limites

Le classement a hesite sur ces tests ; le verificateur peut partir d'ici.

1. **Tout `class_selection_screen_test.dart` supprime**, y compris trois tests qui lisent « seule la classe que le passif declare le propose », « un passif sans carte de lot n'est pas propose (O5) » et « le passif retenu est celui que l'ecran pousse ». Raison : la regle d'acces est dans `availablePassivesFor`, gardee par `passive_availability_test`; l'ecran qui pousse le passif choisi est visible a la premiere partie. Doute residuel : le cablage « l'ecran pousse le premier du point d'acces » n'est plus garde.
2. **`deck_screen_test.dart` supprime**, dont « Transcendance » (trois rares a Econome 1 fusionnent en epique a Econome 2 sous le plafond releve) et « le rang atteint » (trois Concentrations peu communes n'offrent que Veloce). `mergeCards` est garde par `deck_controller_test` et `decoupled_forge_test`, le plafond effectif par `forge_rune_rules_test`; seul le cablage `capBonus: runeCapBonus` de l'ecran n'est plus garde.
3. **`draft_screen_test.dart` supprime**, dont « une rune a son plafond fait sortir Transcendance » (7 rouleaux au lieu de 6). L'exigence est gardee par `level_up_reward_requirement_test`; le cablage de l'ecran ne l'est plus.
4. **`event_screen_test.dart` supprime**, y compris les tests du « retour systeme » (le retour resout le noeud une seule fois et pousse un seul cran de sauvegarde, `checkpointProvider == 1`). Un noeud non resolu se voit sur la carte; le compteur de points de sauvegarde n'est plus garde cote ecran (`checkpoint_autosave_test` garde le declencheur). Meme raisonnement pour `forge_fusion_screen_test` et `rest_screen_test` (retour systeme).
5. **`rest_screen_test.dart` : gardes les deux tests de soin** (30 % des PV max arrondi, borne aux PV max) parce que le calcul `(maxHp * 0.3).round()` vit dans l'ecran (`rest_screen.dart`) et qu'aucun test unitaire ne le garde. Reecrire en test unitaire exigerait de sortir le calcul de `lib/` : hors perimetre. Leurs assertions sur la notification restent, par commodite.
6. **`home_screen_save_test.dart` : garde « Continuer explique une sauvegarde plus recente et la conserve »** (une sauvegarde perdue ne se voit pas). Supprime « CONTINUER apparait apres un retour de JOUER » (regression d'affichage).
7. **`debug_drawer_test.dart` : garde « la derniere cible de Puissance ne peut pas etre retiree »**, regle d'etat de l'outil de debug qui evite une run que `HeroData.fromJson` refuse de relire. C'est un outil de developpement, peu visible en jeu normal.
8. **`content_editor_screen_test.dart` (27 gardes sur 56) et `document_form_test.dart` (9 sur 20)** : l'editeur de contenu est un outil de developpement sans controleur, son ecran *est* sa logique. Gardes : tout ce qui verifie le fichier ecrit (ou non ecrit) et le document produit. Supprimes : navigation, lisibilite, couleurs, alignement. Cas les plus discutables : « changer de type vide le champ identifiant » et « cliquer une entite au niveau 2 remplit le champ identifiant » (supprimes : etat d'ecran visible), « taper dans le champ identifiant ne relit pas le disque » et « changer de categorie relit le disque » (supprimes : comportement d'ecran, pas donnee), « choisir une entite au niveau 2 la charge » (supprime; « choisir une signature la charge depuis son dossier » est garde), « une cible absente est signalee, sans vider le formulaire » (supprime : message d'ecran).
9. **`color_field_test.dart`, `editor_toolbar_test.dart` (`shortRoot`)** : fonctions pures de conversion et de libelle, gardees; le contraste 4,5:1 du texte choisi est supprime (lisibilite, un affichage).
10. **`signature_bar_test.dart` : garde seulement la priorite des etats** (fonction pure `signatureTileStateOf`). Les tests de gestes (toucher une tuile en recharge n'appelle rien, mana insuffisant ne joue rien, une tuile disponible sans cible se joue aussitot) sont de l'interaction visible des le premier combat : supprimes.
11. **`card_dictionary_order_test.dart` et `starter_deck_draft_order_test.dart` gardes** : ce sont des tests d'ecran, mais ils verifient un ordre de departage (rarete, cout, id) qu'on ne remarque pas en jouant et qui ne tient pas a la declaration. Reecrire en test unitaire exigerait que le tri soit une fonction publique de `lib/`.
12. **`class_identity_test.dart` (widget) supprime en entier**, y compris « l'image affichee est l'icone quand elle existe, la carte sinon » et « le decodage est borne a la taille de rendu » : choix d'image et couleur, visibles a l'ecran de selection; la borne de decodage est une optimisation memoire, non un chiffre de jeu. `test/unit/class_identity_test.dart` est intact.
13. **`tutorial_screen_bold_text_test.dart` supprime** : `parseBoldSegments` est une fonction pure de decoupage, mais son seul resultat est le gras affiche (la consigne range « la prose et le gras affiches » dans l'affichage).
14. **`tutorial_prose_test.dart` : quatre tests de prose supprimes** (« 2 du lot et 3 neutres », signatures « mot pour mot », « la Fusion ne dit plus... », « le Gel ne se chiffre plus... »). Les huit tests de substitution des placeholders depuis le catalogue sont gardes (ils calculent le texte a partir des donnees).
15. **`heros_draft_game_targeting_test.dart` supprime** : machine d'etats du ciblage Flame, testee sans ecran; classee entree utilisateur visible des le premier combat. C'est le cas le plus proche de la limite, car le test ne verifie pas un rendu.
16. **`flame_image_prefix_test.dart` garde en entier** : malgre son nom, il garde le chargement des images sous le prefixe vide (donnees, perte silencieuse a la compilation), pas un rendu. De meme `card_text_renderer_test.dart` (total affiche = total calcule).
17. **`probabilities_dialog_test.dart` et `stats_dialog_test.dart` supprimes** : leurs assertions portent sur du texte rendu; les calculs sont gardes par `probabilities_test` et `draft_choice_labels_test`. La phrase « la parenthese nomme les mythiques de la donnee » n'est plus gardee cote dialogue.
18. **Aucune reecriture en test unitaire n'a ete faite** : chaque test conserve l'a ete tel quel, aucune regle n'etait sans garde ailleurs a un cout court et sur.

## Code de lib devenu sans lecteur de test

Aucun code de `lib/` n'est devenu utilise par un test supprime seul : les deux `@visibleForTesting` de `lib/services/audio/audio_providers.dart` et celui de `lib/services/game_data_service.dart` ont toujours des lecteurs hors des fichiers supprimes. Restent sans test, mais utilises en production : `parseBoldSegments` (tutoriel), l'opacite de `FloatingText`, `HerosDraftGame.handlePlayerTargeting`, `shortRoot` conserve. Rien n'a ete modifie dans `lib/` ni `assets/`.
