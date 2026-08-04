<!-- last-sync: 2026-08-03 | commit: bfa4592 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

La branche `docs/memory-bank-overhaul` termine la refonte du memory bank : les
monolithes `decisionLog.md`, `systemPatterns.md` et `productContext.md` sont déjà
compactés vers des index courts adossés à des fiches individuelles (`../_adr/`,
`../_patterns/`, `../_rules/`), et `activeContext.md` devient à son tour une
fenêtre glissante sur 3 livraisons plutôt qu'un journal qui s'accumule sans fin.
La roadmap priorisée du 31/07 est désormais destinée à devenir `docs/ROADMAP.md`.
Prochain chantier applicatif une fois la doc stabilisée : Jalon 1 « Socle »
(P-01, P-02, P-04, P-03) — voir `docs/ROADMAP.md`.

## 3 dernières livraisons

1. **Refonte documentaire du memory bank** (2026-08-03, en cours) — `decisionLog.md`
   (2704 → 101 lignes + 77 fiches ADR), `systemPatterns.md` (1478 → 115 lignes +
   39 fiches), `productContext.md` (807 → 90 lignes + 26 fiches) ; `progress.md`
   ramené à 208 lignes. Design : `docs/superpowers/specs/2026-08-03-documentation-overhaul-design.md`.
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

Voir `docs/ROADMAP.md` — Jalon 1 « Socle » : P-02, P-04, P-03.
