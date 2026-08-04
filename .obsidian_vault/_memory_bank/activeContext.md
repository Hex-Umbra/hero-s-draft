<!-- last-sync: 2026-08-04 | commit: 52a18fb -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

La refonte du memory bank est mergée (PR #23). Dans sa foulée, le **Tier D de
`docs/ROADMAP.md` a été re-vérifié contre le code** le 2026-08-04 : six de ses huit
fiches énonçaient des faits périmés, dont deux chantiers livrés dès le 24/07. Le tier
a été réécrit et re-ordonné (P-26 en tête), et la même erreur a été corrigée dans le
tableau de sérialisation de `progress.md` §2. **Les tiers A, B, C et E n'ont pas encore
subi ce contrôle** — les traiter comme non vérifiés. Prochain chantier applicatif :
Jalon 1 « Socle » (P-02, P-04, P-03) — voir `docs/ROADMAP.md`.

## 3 dernières livraisons

1. **Refonte documentaire du memory bank** (2026-08-03, mergée via PR #23) — `decisionLog.md`
   (2704 lignes), `systemPatterns.md` (1478) et `productContext.md` (807) sont
   devenus des index adossés à des fiches adressables sous `../_adr/`,
   `../_patterns/` et `../_rules/` ; `progress.md` a été réécrit sur des métriques
   re-mesurées. Pour les tailles courantes, lire les fichiers — ce document ne les
   réénonce pas. Design : `docs/superpowers/specs/2026-08-03-documentation-overhaul-design.md`.
2. **Réactivité du bouton « Continuer » de `HomeScreen`** (2026-07-26) — le bouton
   pouvait afficher un état obsolète après un retour via `Navigator.popUntil`
   (pause, défaite) car `HomeScreen` ne se reconstruisait pas et son
   `FutureProvider` sur `SaveService.hasSave()` n'était jamais réévalué. Correctif :
   `await` sur `Navigator.push` puis `setState(() {})` au retour. Voir
   [ADR-073](../_adr/ADR-073-reactivite-du-bouton-continuer-de-homescreen-apres.md).
3. **Accélération de la cadence du scaling de difficulté** (2026-07-26) — suite à
   un retour de playtest (le joueur montait en puissance plus vite que les
   ennemis), le palier géométrique HP/Dégâts passe de 5 à 2 actes et le
   déblocage de tier de 10 à 5 actes, sans toucher aux bases numériques ni au
   plafond d'ennemis. Voir [ADR-072](../_adr/ADR-072-resserrement-de-la-cadence-du-scaling-de-difficult.md).

## Prochaine étape

Voir `docs/ROADMAP.md` — Jalon 1 « Socle » : P-01, P-02, P-04, P-03.
