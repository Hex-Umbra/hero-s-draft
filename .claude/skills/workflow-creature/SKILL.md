---
name: workflow-creature
description: Use when the owner launches /workflow-creature, or asks to create a new pixel-art creature, enemy or character sprite for Hero's Draft, to resume one from its brief, or to redo one of its steps (guide, generation, layers, rim).
argument-hint: "[la créature : nom, tier, biome, ou rien pour partir de zéro]"
---

# Conduire la production d'une créature

Tu conduis la production d'un sprite de créature en pixel art pour **Hero's Draft**, de la demande du propriétaire jusqu'au sprite livré.

La demande du propriétaire : **$ARGUMENTS**

**Ce skill ne décrit pas la méthode : il dit dans quel ordre avancer, où t'arrêter, et qui décide.** La méthode est dans `art_src/docs/workflow_creature.md`, les commandes dans `art_src/tools/README.md`. Tu ne recopies ni l'un ni l'autre : tu les lis, puis tu les suis.

## 1. Avant le premier message

1. **Lis en entier** `art_src/docs/workflow_creature.md`, puis les sections « Règles communes », « Prérequis » et « Les commandes » de `art_src/tools/README.md`. Les exemples de `art_src/docs/exemples/` ne se lisent que pour voir comment un cas précis a été résolu.
2. **Cherche un brief existant :** `art_src/creatures/**/*_brief.md`. S'il y en a un pour cette créature, tu reprends là où il s'arrête (§4). Sinon, tu pars de l'étape 1.
3. **N'invoque pas `superpowers:brainstorming`.** La session de brief de l'étape 1 en tient lieu.

**Le périmètre s'arrête au sprite.** Tu livres des fichiers dans `art_src/`. Tu ne crées ni l'ennemi jouable (`assets/data/enemies/`), ni son `sprite.png` : c'est une autre demande.

## 2. Les étapes et leurs portes

**Une porte, c'est un arrêt : tu envoies ce que tu as à montrer, puis tu attends la réponse du propriétaire.** Tu ne franchis jamais une porte sur ta propre lecture d'une image.

| Étape du workflow | Ce que tu fais seul | Ce que tu montres | Porte |
|:---|:---|:---|:---|
| 1. Brief | Tu écris `<nom>_brief.md` au fil des réponses | Le résumé de la créature après chaque bloc | **Une par bloc**, puis la validation du brief complet |
| 2. Guide | Tu écris `creature_<nom>_pose.py` et traces les guides | La pose et l'équipement superposés | **L'accord sur le guide** |
| 3. Design | Tu lances le tour annoncé, tu regardes chaque image, tu remplis le journal | La planche du tour, avec ce que tu y vois | **Le choix du propriétaire, à chaque tour** |
| 4. Anatomie | Tu comptes membres, mains et armes ; tu corriges sur une copie | Ton compte ; l'avant et l'après de chaque correction | **L'accord sur la figure corrigée**, s'il y a eu correction. Sinon tu continues |
| 5. Détourage | Tu détoures, tu contrôles `_detouree.png` toi-même, tu recommences si besoin | Rien, sauf un défaut que tu ne sais pas corriger | — |
| 6. Calques | Tu cherches les mots sur leur planche, tu écris `<nom>_calques.json`, tu contrôles la planche des calques | La planche des calques | **L'accord sur les calques**, et sur celui qui recevra le liseré |
| 7. Contrôle en situation | Tu fais la planche de contrôle | La planche, et les trois questions du workflow | **La validation du design** |
| 8. Liseré | Tu poses le liseré sur le sprite et sur l'aperçu | La planche avec le liseré | — |
| 9. Retouche | Rien : elle est au propriétaire | La liste de ce qui reste à reprendre à la main | — |

**Si le design n'est pas validé à l'étape 7,** tu reviens à l'étape que le propriétaire désigne. Trop grande devant son fond : c'est la réduction du workflow, pas une régénération.

## 3. Règles de conduite

**Le brief**
- **Un bloc par message, un arrêt par bloc.** Tu ne fusionnes jamais deux blocs, même courts. Le résumé du bloc que le propriétaire vient de remplir ouvre le message du bloc suivant : il le corrige en répondant.
- **Le prompt et le vocabulaire du tier se proposent avec le brief complet,** à sa validation.
- **Un bloc auquel la demande répond déjà se confirme, il ne se saute pas :** tu écris ce que tu en as compris, et tu demandes si c'est juste.
- **Une question qui ne s'applique pas se dit au propriétaire.** Un loup n'a ni arme ni bouclier : tu le dis au bloc 3, et tu demandes ce qui en tient lieu (griffes, cornes, rien).

**La génération**
- **Aucune génération avant le brief validé.** Pour une créature humanoïde, aucune avant l'accord sur le guide.
- **ComfyUI ne sert qu'à partir de l'étape 3,** puis pour les masques des étapes 5 et 6. Avant ta première commande `comfy_*` ou `creature_mots_layers.py` : `curl -s -m 5 http://127.0.0.1:8188/system_stats`. S'il ne répond pas, tu demandes au propriétaire de lancer Comfy Desktop. Tu ne le lances pas toi-même.
- **Tu annonces le nombre d'images avant chaque tour,** et tu ne changes qu'une chose à la fois.
- **Tu regardes chaque planche avant de la montrer** (outil Read), et tu dis ce que tu y vois : les défauts d'anatomie, le fond, l'équipement. Puis tu donnes le chemin de la planche en lien, et tu attends.
- **Après chaque tour, le journal du brief :** `python comfy_meta.py lire <image>` donne le prompt, les exclusions, la graine et les forces.
- **Dès que le propriétaire retient une image,** tu la copies dans le dossier de la créature, en `<nom>_figure_brute.png` et en `<nom>_figure.png`.

**Ce que tu ne décides pas**
- Le design, la graine retenue, la taille dans le cadre, la validation : au propriétaire.
- **Un réglage ou un vocabulaire que le workflow marque « à trouver » ou « provisoire » :** tu proposes, le propriétaire tranche, puis tu l'écris dans le workflow, à sa place.
- **Quand le workflow se tait,** tu ne devines pas : tu poses la question, puis tu écris la réponse dans `workflow_creature.md`. C'est ainsi qu'il s'améliore. Il se tait encore sur plusieurs points d'une créature non humanoïde : l'orientation par défaut, la taille dans un cadre en hauteur, l'ordre de ses calques, la variation et la réduction sans guides.

**Les outils**
- **Toutes les commandes se lancent depuis `art_src/tools/`.** Les fichiers de travail vont dans `.work/`, sous le préfixe `.work/<nom>`.
- **Un outil qui s'arrête avec un message a raison.** Tu lis le message et tu corriges la cause. Tu ne contournes ni un contrôle de grille, ni un mot qui ne désigne rien.
- **Un écart entre un outil et le workflow se signale au propriétaire,** avec la correction que tu proposes.

**Les fichiers**
- **Rien ne se supprime dans le dossier d'une créature :** une version remplacée va aux archives, selon la règle du README. `.work/` n'est pas concerné : c'est du jetable.
- **Tu ne commites que sur demande.** À la livraison, tu proposes les lots.

## 4. Le brief est l'état

Une autre session doit pouvoir reprendre la créature sans te lire. **À chaque porte franchie, tu mets le brief à jour :** sa ligne « État », le bloc touché, le journal des tours, puis la section « Après la génération ».

**Pour reprendre :** tu lis le brief, tu dis au propriétaire à quelle étape tu reprends et pourquoi, et tu attends son accord avant d'avancer.

## 5. La livraison

La créature est livrée à la fin de l'étape 8. Ton dernier message donne :
- les fichiers du dossier `art_src/creatures/<famille>/tier_<n>/`, selon le tableau du workflow, et le script de pose s'il y en a un ;
- ce qui reste à retoucher à la main dans Aseprite, calque par calque ;
- ce que cette créature a appris, et que tu as écrit dans le workflow ;
- les lots de commits que tu proposes.
