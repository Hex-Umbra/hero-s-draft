# Éditeur de contenu — habillage « éditeur » — Conception

Date : 2026-09-15
Statut : **Conception validée** — non implémenté
Validation : le propriétaire a validé la maquette « à 100 % », explorateur vertical compris, le 2026-09-15.
Maquette de référence : https://claude.ai/artifact/LxdzWS39yF6gajJwm6NNpb (trois états : créer une classe, modifier une carte, refus de validation)
Sources amont :
- `docs/superpowers/specs/2026-09-14-editeur-de-contenu-formulaire-infere-et-ressources-design.md` — le formulaire inféré et les ressources, dont cette spec ne change **aucune** règle
- `docs/superpowers/specs/2026-09-08-editeur-de-contenu-creation-guidee-design.md` — l'arbre Type → Action → Entité, dont cette spec ne change que la présentation

> **Ce que cette spec change, et ce qu'elle ne change pas.**
>
> Elle ne touche que `lib/ui/` et les tests de widgets. `EditorDocument`, `EntityDraft`,
> `EntityValidator`, `EntityWriter`, les imports et l'ordre `composer → substituer → valider → écrire`
> sont intacts. Aucune donnée de `assets/data/` n'est modifiée. L'outil n'existe qu'en `kDebugMode` :
> rien n'est visible du joueur, donc aucune note de version.

## 1. Constat

Le formulaire actuel (capture du propriétaire, 2026-09-15) est une pile de `TextField` Material à
soulignement, de libellés flottants et de rangées de boutons : il se lit comme un brouillon, pas comme
un éditeur. Les niveaux Type et Action occupent deux rangées, la liste des entités à modifier grandit
avec le contenu, les boutons « Valider » et « Écrire » sortent de l'écran dès que le formulaire défile,
et une faute ne dit pas quel champ elle vise.

## 2. Décisions

**D1 — Une barre d'outils.** Les sept types sont des onglets avec icône, soulignés quand ils sont
choisis. Créer / Modifier est un sélecteur segmenté à droite de la même barre, qui n'apparaît qu'une
fois un type choisi (inchangé). Les deux niveaux de l'arbre tiennent sur une ligne, qui passe à la
ligne quand la largeur manque.

**D2 — Un explorateur en mode Modifier.** Une colonne de 240 px à gauche remplace le niveau
« Entité » de l'arbre : les entités existantes, groupées par propriétaire (neutres d'abord, puis chaque
classe par ordre alphabétique), chaque groupe portant la pastille de couleur de sa classe et son
compteur. Un champ de filtre réduit la liste (sous-chaîne, sans casse). Choisir une entité la charge,
comme aujourd'hui.

**D3 — Un en-tête de fichier.** Une tuile à l'icône du type, teintée par la couleur du propriétaire
(carte de classe) ou par `themeColor` (classe) ; le titre `Créer · Classe` ; le chemin visé, l'identifiant
surligné ; un état — `Nouveau fichier` (création), `Relu du disque` (le formulaire montre le chemin
visé), `Non chargé` (modification sans relecture du chemin visé, que « Écrire » refusera).

**D4 — Des sections.** Identité, Textes, Mécanique, Ressources, Cartes de signature : chacune un
panneau titré. Les ressources quittent la mécanique pour leur propre section, requises d'abord.

**D5 — Une grille de propriétés.** La clé JSON réelle à gauche en police à chasse fixe, un point bleu
pour un champ obligatoire, le contrôle à droite ; la clé passe au-dessus quand la place manque. Une
suite d'au moins deux nombres se range en grille (trois colonnes au plus). Les textes FR et EN sont
côte à côte.

**D6 — Une mécanique lisible.** La bascule Formulaire / JSON est un segmenté dans l'en-tête de la
section. Une liste d'objets devient une pile de sous-panneaux numérotés, chacun avec un résumé et une
corbeille, et un bouton « Ajouter » en pointillés. Les options d'une clé `rarity` prennent les couleurs
de rareté du jeu (`AppColors.rarity*`).

**D7 — Une barre d'actions fixe.** Charger (Modifier seulement), Valider et Écrire restent visibles au
bas du formulaire, quel que soit le défilement, avec une ligne d'aide. L'issue du dernier geste devient
un bandeau : rouge pour les fautes et les échecs, vert pour une écriture, ambre pour le redémarrage à
chaud. Une faute qui nomme son champ (`ValidationFault.field`) : ce champ est bordé de rouge avec le
message dessous, et la ligne du bandeau y ramène au clic.

**D8 — Un panneau Référence.** Les valeurs déjà utilisées, à droite, en étiquettes avec un compteur par
clé ; une couleur hexadécimale porte sa pastille, un chemin se réduit au nom de son fichier. Il ne
s'affiche qu'à partir de 1100 px de large pour la zone de travail.

**D9 — Le contrat de choix.** Tout élément sélectionnable — onglet, segment, puce, entité de
l'explorateur — (a) peint son libellé sur un fond **opaque** porté par un `Container` de clé
`editeur-bouton-fond`, (b) y reste lisible à 4,5:1 au moins (texte et icônes), (c) expose
`Semantics(selected: …)`, et (d) marque sa sélection autrement que par la couleur : coche pour une puce
et une entité, soulignement pour un onglet, anneau pour un segment.

**D10 — Les jetons.** Tirés d'`AppColors` quand le jeu les porte, sans nouvelle police.

| Jeton | Valeur | Rôle |
|:---|:---|:---|
| fond | `ScreenScaffold` sombre (`#0D0D1A` + dégradé) | l'écran |
| `side` | `#10101F` | barre d'outils, explorateur, référence |
| `bar` | `#13132A` | barre de titre, barre d'actions |
| `panel` | `AppColors.surfaceDark` `#1A1A2E` | panneaux |
| `panelHead` | `#1E1E36` | en-têtes de panneau |
| `well` | `#0E0E1C` | puits de saisie |
| `chip` / `chipBorder` | `#16162A` / `#45456A` | puces au repos |
| `line` / `lineStrong` | `#26263E` / `AppColors.darkBorder` `#3F3F5F` | filets / bords de saisie |
| `keyText` / `soft` / `muted` / `faint` | `#AFC0C9` / `#C5D0D6` / `AppColors.textSecondary` / `#7A8E9A` | textes |
| `accent` / `accentInk` | `AppColors.neonBlue` `#00D4FF` / `#00141B` | sélection, focus, action principale |
| `debug` | `Colors.deepPurpleAccent` | badge DEBUG (celui du tiroir de debug) |
| sémantique | `AppColors.success` / `danger` / `warning` | écrit / faute / à faire |

Typographie : la police système de l'application ; `monospace` (repli `Consolas`, `Menlo`,
`Roboto Mono`) pour les clés, chemins et identifiants ; titres de panneau en capitales espacées
(11,5 px, 700, espacement 1,4), comme `PageHeader`.

**D11 — Les tests suivent la structure, pas l'inverse.** Les libellés visibles (`Créer`, `Modifier`,
`Charger`, `Valider`, `Écrire`, les sept types, `aucun`, `aucune`, `Importer…`, `Ajouter`) et les clés
`editeur-*` dont dépendent les tests sont conservés. Un test ne change que là où la structure qu'il
observait disparaît (niveaux de l'arbre, coche des types et modes, alignement de l'issue, couleur des
entités), et garde alors l'intention qu'il protégeait.

## 3. Écarts assumés par rapport à la maquette

| Maquette | Implémentation | Raison |
|:---|:---|:---|
| Titre de l'explorateur « Cartes » | « ENTITÉS » | « Carte » est déjà le libellé exact d'un onglet ; un doublon rendrait les onglets ambigus |
| « Importer un son… » | « Importer… » pour toute ressource | un seul libellé de geste, celui des tests |
| « + 5 autres » replie les sons | tous les sons affichés | replier est un comportement nouveau, sans besoin exprimé |
| éclair rouge sur le champ atteint | défilement seul | effet décoratif, sans information |
| le champ hexadécimal ressemble à une saisie | lecture seule, la roue reste le seul geste | la saisie hexadécimale serait un comportement nouveau |

## 4. Hors périmètre

La logique de l'éditeur, les données, les clés ARB, les notes de version, le reste du jeu.
