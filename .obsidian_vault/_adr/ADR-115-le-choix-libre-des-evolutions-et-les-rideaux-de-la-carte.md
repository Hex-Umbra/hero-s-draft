---
description: Signature evolutions are no longer drawn — every evolution the tier admits is offered (D78, amends D19); both pending signatures are chosen together on one screen, one column per signature, tabs on phones (D79); the map curtain takes one shape per what waits — a class-colour band with rising arrows for a level up, a band for a minor, a gold medallion with rays for a major (D80 to D82); Mon Deck shows the run's evolved signatures; the class-selection Passives badge hides while a class has a single passive
---

# ADR-115 — Le Choix Libre des Évolutions, les Deux Signatures sur un Écran, les Rideaux de la Carte

### Statut

✅ Accepté — 2026-11-07 (brainstorm v3, décisions **D78** à **D82**, du 2026-11-06 au 2026-11-07,
toutes du propriétaire). **Amende** [ADR-114](ADR-114-les-evolutions-de-signature.md) **D3 et D4** :
plus de tirage, plus d'écran à trois rouleaux ; D1, D2, D5, D6 et D7 ne changent pas. Série de
corrections demandée par le propriétaire après la fin de la vague 5, **sur la même branche,
`feat/v0.5.7-p42-tranche-1-p44-lot-1`, et dans la même version** — en attente du test, de la PR,
de la fusion et du tag du propriétaire. Code `83c48810`..`9fb32fcf` ; note de version 0.5.7
corrigée sur place, avec l'accord du propriétaire, au commit `8a5d92b9`. Maquettes :
[choix des évolutions](../../docs/presentations/2026-11-06_choix_des_evolutions_maquettes.pptx),
[signatures hors combat](../../docs/presentations/2026-11-06_signatures_hors_combat_maquettes.pptx),
[rideaux](../../docs/presentations/2026-11-07_rideaux_des_evolutions_maquettes.pptx).

### Contexte

En jouant la vague 5, le propriétaire a trouvé l'écran d'évolution confus : il reprenait les
rouleaux du draft de niveau, si bien qu'au niveau 5 trois écrans identiques se suivaient. Le hasard
ne cachait presque rien — une majeure au niveau 10, une ou deux mineures aux niveaux 30 et 40. Le
rideau de la carte disait « LEVEL UP ! » quoi qu'il attende, en français en dur, et rien ne montrait
une signature évoluée hors du combat. Le masquage des passifs sans lot laissait un badge
« Passifs » et un dépliage qui ne dépliaient rien.

### Décision

**D1 — Plus de tirage** (D78). À chaque palier, le joueur choisit parmi **tout ce que le palier
admet** : `SignatureEvolutionRules.admissible`, inchangé — les mineures au palier mineur, les
majeures éligibles au palier majeur, plus toutes les mineures quand il en reste moins de trois
(Q6). `offer` disparaît. `board` range le pool pour l'écran, chaque évolution une seule fois : ce
qui se prend maintenant, l'autre rang et le niveau du héros qui l'ouvre, les majeures prises, les
majeures exclues avec celle qui les exclut (Q7).

**D2 — Les deux signatures sur un écran** (D79). `RunState.pendingEvolutions` remplace
`nextPendingEvolution` : les signatures dont une évolution attend, dans l'ordre de
`HeroData.skills`, se choisissent **ensemble**. Une colonne par signature — sa fiche, qui montre le
résultat, puis son pool —, un seul bouton actif quand chacune a son choix ; sur téléphone, un onglet
par signature ; sur une fenêtre basse, deux colonnes sans fiche. Rien n'étant tiré, le retour
ramène au rideau sans rien perdre. Sur un saut de plusieurs paliers, le rideau rouvre l'écran pour
le palier suivant.

**D3 — Le rideau dit ce qui attend** (D80, D81, D82). Sans cadre, à la couleur de la classe
(`ClassIdentity.colorOf`), dans le corps de la carte — la barre du haut reste accessible. **Niveau
gagné** : un bandeau sur des flèches tirées au hasard à chaque ouverture, qui montent et passent
derrière lui ; voile à 68 %, entrée en 0,8 s, titre ambré ; le bandeau est transparent sur ses
deux bords et plein au centre, ses bords gardant 60 % de l'opacité sous 600 px de large. **Évolution
mineure** : un bandeau plein au fondu court, une icône, voile à 50 %, entrée en 0,5 s puis
immobile. **Évolution majeure** : un médaillon doré à double anneau, des rayons qui tournent, voile
à 94 %, entrée en 1,4 s. Un draft de niveau passe avant une évolution ; si les signatures attendent
des rangs différents, le majeur l'emporte. Tous les textes passent aux ARB. L'entrée rejoue entre
deux drafts. Aucun son.

**D4 — Les signatures dans Mon Deck.** En tête de l'écran, une fiche par signature de la run, qui
lit la `SignatureInstance` : type, coût et recharge évolués, description évoluée, évolutions prises
avec leur niveau, et la prochaine par son rang et le niveau du héros
(`SignatureInstance.nextEvolutionHeroLevel`) — sans chiffre d'XP, une signature n'en a pas. Côte à
côte, empilées sous 600 px.

**D5 — Sans deuxième passif, ni badge ni dépliage.** À la sélection de classe, une classe qui n'a
qu'un passif le montre directement ; le badge et le dépliage reviennent seuls avec le deuxième
passif, en vague 6.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Le pool rangé, plus de tirage | `lib/game/systems/signature_evolution_rules.dart` (`board`, `SignatureEvolutionBoard`) |
| Les attentes ensemble | `RunState.pendingEvolutions`, `.hasPendingChoice` (`lib/game/controllers/run_controller.dart`) |
| L'écran des deux signatures | `lib/ui/screens/signature_evolution_screen.dart` ; `PageHeader` dont le titre rétrécit |
| Les rideaux | `lib/ui/widgets/map/level_up_overlay.dart` ; `lib/ui/widgets/map/curtains/` (`level_up_curtain.dart`, `minor_evolution_curtain.dart`, `major_evolution_curtain.dart`, `curtain_band.dart`, `curtain_step.dart`) ; `lib/ui/screens/map_screen.dart` |
| Mon Deck | `lib/ui/widgets/signature_run_card.dart` ; `lib/ui/screens/deck_screen.dart` |
| Le badge des passifs | `lib/ui/widgets/class_passive_list.dart` |

Règle de jeu : [`_rules/02-8`](../_rules/02-8-evolutions-de-signature.md). Pattern :
[`_patterns/03-8`](../_patterns/03-8-signatureevolutionrules-regles-pures-des-evolutions.md).

### Conséquences

- **Le rythme de puissance ne bouge pas** : les mêmes paliers, les mêmes règles d'admission ; seul
  le hasard disparaît. Une majeure peut désormais se viser dès le niveau 10.
- **Aucun test d'écran** ([ADR-113](ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md)) :
  `board` et `nextEvolutionHeroLevel` sont gardés par les tests de calcul ; l'écran, les rideaux et
  Mon Deck sont aux points M9, M10, M12 à M17, M35, M36 et M39 à M41 du
  [fichier de tests manuels](../../docs/superpowers/reports/2026-11-04-economie-et-catalogue-vague-5-tests-manuels.md).
  **Rien n'a été joué dans le vrai jeu par l'agent** : les rideaux ont été vus en images sur la
  vraie carte, à trois formats.
- **Au palier majeur à 900 × 600**, chaque colonne défile, la fiche étant au-dessus du pool —
  le prix accepté par D79.
- **Remarqué, non corrigé** : à 360 px de large, le compteur d'or de la barre de la carte chevauche
  « RELIQUES » et « CHANCES » dans le rendu de test, dont la police diffère — à confirmer sur un
  vrai téléphone.
