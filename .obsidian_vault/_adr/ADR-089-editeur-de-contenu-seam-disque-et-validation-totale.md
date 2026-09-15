### Statut

✅ **Livré le 2026-09-09**, chantier P-30 (menu de debug), lot 2, et sa suite « création guidée »,
branche `feat/menu-debug-lot-2`. Repose sur [ADR-085](ADR-085-regle-de-partage-catalogue-configuration.md)
et [ADR-086](ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md) : sans un fichier par
entité, un outil d'écriture aurait dû réécrire des catalogues entiers. **Amendé par
[ADR-092](ADR-092-formulaire-infere-du-document-et-ressources-liees.md) le 2026-09-14** : la saisie
non convertible devient une faute (Conséquences ci-dessous), un import explicite peut écraser une
image (E9), et l'écriture peut toucher `audio.json`. E6 tient inchangé.

### Contexte

Le lot 1 ne touche qu'à la mémoire vive ; un bug y coûte une session. L'éditeur de contenu écrit
dans `assets/data/` : un bug y entre dans le dépôt et devient le jeu de tout le monde. Ses
artefacts doivent donc passer **les mêmes gardes** qu'un fichier écrit à la main
(`real_bundle_load`, `referential_integrity`, `entity_id_convention`, `sync_assets`).

Trois contraintes : le jeu a un build **web**, sans `dart:io` ; le répertoire courant dépend de la
façon dont l'application a été lancée ; et un fichier invalide ne casse pas que lui — il fait
échouer le chargement de **toute** sa catégorie.

### Décision

**E1 — Créer et modifier ; ni supprimer ni renommer.** Supprimer une carte de signature ou un
passif référencé casse l'intégrité ; renommer orphelinerait l'ancien fichier.

**E3 — Les énumérations se vérifient contre les enums Dart réels** (`CardType.values`…), jamais
contre une liste recopiée qui se périmerait au premier ajout.

**E4/E5 — La racine est déduite de `Platform.resolvedExecutable`** (remontée jusqu'à trouver
`pubspec.yaml` **et** `assets/data` — un `pubspec.yaml` seul existe aussi dans le cache de paquets), **puis passée
en paramètre** à la couche d'écriture — le même joint que `bundle` pour `GameDataLoader`.

**Seam `dart:io`** — l'interface `ContentFileSystem` isole toute opération disque ; une seule
implémentation importe `dart:io`, sélectionnée par import conditionnel. Sur web, l'écran refuse de
s'ouvrir.

**E6 — Rien n'est écrit avant que toute la validation passe.** Et **« Valider » juge le document
que « Écrire » écrira** (commit `7158d5e`) : les deux boutons passent par le même jugement, champs
vides déjà complétés.

**D7 — La complétion des champs vides précède la validation**, sinon le contrôle bilingue refuse
exactement ce que la complétion fournit (`[À REMPLIR] <id>`).

**E7 — Une carte de classe écrit deux fichiers, ou aucun** : le fichier de carte et le `skills` de
`class.json`. `writeAll` partage une pile de rollback sur tous les brouillons d'un geste — une
classe entière et ses cartes de signature s'écrivent en une transaction.

**E8 — L'unicité se vérifie sur le disque et dans le registre** : chacun rattrape l'angle mort de
l'autre. La bijection `skills` ↔ `cards/` se lit sur le **disque**, le registre ignorant les cartes
fraîchement écrites.

**E9 — L'image est un placeholder copié, jamais écrasé** (`assets/placeholders/images/`).

**E10 — L'outil n'existe qu'en `kDebugMode`**, comme le lot 1.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Seam et racine | `lib/services/content_editor/content_file_system*.dart`, `platform_file_system.dart`, `project_root.dart` |
| Table des 7 catégories | `lib/services/content_editor/entity_descriptor.dart` — `kEntityDescriptors` |
| Validation (9 contrôles, arrêt au premier échec) | `lib/services/content_editor/entity_validator.dart` |
| Complétion | `lib/services/content_editor/placeholder_filler.dart` |
| Écriture transactionnelle | `lib/services/content_editor/entity_writer.dart` — `writeAll` |
| Recette de classe | `lib/services/content_editor/class_recipe.dart` |
| Écran | `lib/ui/screens/content_editor_screen.dart`, widgets sous `lib/ui/widgets/content_editor/` |
| Tests | `test/unit/content_editor/` (9 fichiers), `test/widget/content_editor_screen_test.dart`, `test/widget/content_editor/` |

### Conséquences

- **Le rollback ne défait ni les dossiers créés ni les images placeholder** ; un échec de
  `sync_assets` en fin d'écriture est signalé sans défaire les fichiers.
- **Le geste suffisant après une création est établi à la main le 2026-09-14** (spec lot 2 §6.3) :
  un redémarrage à chaud charge une classe, un ennemi, une carte ou une relique neuve,
  `pubspec.yaml` modifié compris. Le message conseillant de relancer `flutter run` est retiré
  (`WriteReport.createdEntity` remplace `relaunchAdvised`, commit `35e4a9f`). Choisir une entité en
  mode Modifier la relit désormais (commit `71f52b3`) : la boîte montrait jusque-là le gabarit.
- La garde « gabarit ⊇ modèle » est une **table de clés maintenue à la main**
  (`entity_descriptor_test.dart`) : elle ne voit pas une clé nouvelle lue par un `fromJson`.
- Une saisie non convertible est remplacée par la valeur du gabarit **avant** validation : le
  validateur ne voit jamais l'entrée fautive.
- `flutter_colorpicker` entre en `dependencies` pour un outil de debug.
- Libellés en français écrits en dur, sans ARB, comme le lot 1.
- Specs : `docs/superpowers/specs/2026-09-06-menu-debug-lot-2-editeur-de-contenu-design.md`,
  `docs/superpowers/specs/2026-09-08-editeur-de-contenu-creation-guidee-design.md`.
