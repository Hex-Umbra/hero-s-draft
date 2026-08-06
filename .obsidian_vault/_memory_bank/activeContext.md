<!-- last-sync: 2026-08-06 | commit: e8904ba -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**P-02 est clos** — code livré et mergé, playtest de validation passé le 2026-08-06. Le
moteur de pioche est assaini et la règle de tour a quitté `game_screen.dart`. La base de
difficulté est donc stable : **P-16 (refonte des probabilités) peut s'ouvrir dessus**, en
calibrant sur l'état actuel et non sur des chiffres antérieurs au 2026-08-06.

Une réserve subsiste, sans lien avec P-02 : **les tiers A, B, C et E de `docs/ROADMAP.md`
n'ont toujours pas été re-vérifiés contre le code** — seuls les tiers S et D l'ont été
(2026-08-04). Les traiter comme non vérifiés.

Prochain chantier applicatif : suite du Jalon 1 « Socle » — P-04 puis P-03.

## 3 dernières livraisons

1. **Assainissement du système de pioche — P-02** (2026-08-06) — le remélange de la défausse
   devient automatique et n'intervient plus qu'une fois la pioche réellement vide (l'ancien
   seuil `< 5` détruisait la capacité à compter son deck) ; la pioche s'arrête net sur main
   pleine sans rien consommer ; `TurnPhaseManager` gagne `startPlayerCombat()` /
   `startPlayerTurn()`, de sorte que le tour 1 et le tour N+1 empruntent enfin le même code ;
   l'aléatoire devient injectable et six éléments de code mort disparaissent. Première
   relique touchant au deck (`scholars_satchel`). **+18 tests neufs, 2 réécrits** — la
   ROADMAP en annonçait 6. Voir
   [ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md).
2. **Refonte documentaire du memory bank** (2026-08-03, mergée via PR #23) — `decisionLog.md`
   (2704 lignes), `systemPatterns.md` (1478) et `productContext.md` (807) sont
   devenus des index adossés à des fiches adressables sous `../_adr/`,
   `../_patterns/` et `../_rules/` ; `progress.md` a été réécrit sur des métriques
   re-mesurées. Pour les tailles courantes, lire les fichiers — ce document ne les
   réénonce pas. Design : `docs/superpowers/specs/2026-08-03-documentation-overhaul-design.md`.
3. **Réactivité du bouton « Continuer » de `HomeScreen`** (2026-07-26) — le bouton
   pouvait afficher un état obsolète après un retour via `Navigator.popUntil`
   (pause, défaite) car `HomeScreen` ne se reconstruisait pas et son
   `FutureProvider` sur `SaveService.hasSave()` n'était jamais réévalué. Correctif :
   `await` sur `Navigator.push` puis `setState(() {})` au retour. Voir
   [ADR-073](../_adr/ADR-073-reactivite-du-bouton-continuer-de-homescreen-apres.md).

> [!NOTE]
> La livraison sortie de cette liste au 2026-08-06 (accélération de la cadence du scaling
> de difficulté, ADR-072) n'a **pas** été ré-archivée : son détail figure déjà verbatim dans
> `../_archive/2026-08-03-activeContext-journal.md` §2.1, et la décision dans
> [ADR-072](../_adr/ADR-072-resserrement-de-la-cadence-du-scaling-de-difficult.md).

## Prochaine étape

Voir `docs/ROADMAP.md` — Jalon 1 « Socle » : ~~P-01~~ ✅, ~~P-02~~ ✅, puis P-04 et P-03.
