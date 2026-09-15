# Archive — livraison sortie de `activeContext.md` le 2026-09-15, seconde rotation du jour

Rotation FIFO. La livraison **P-40 bloc 2 — cartes et forge** (2026-09-15) entre dans
`activeContext.md` ; celle ci-dessous en sort, conservée **verbatim**, numérotation comprise. La
première rotation du jour est archivée dans `2026-09-15-activeContext-livraisons.md`.

> [!WARNING]
> Lecture seule. Ces textes décrivent l'état du projet à la date où ils ont été écrits.

---

3. **Menu d'accueil et retours arrière** (2026-09-14, commits `97f1553`, `b47f2e3`, `ce60b39`) — menu joueur aligné à
   gauche, menu de debug dans sa colonne à droite, bouton **« Quitter »** qui passe par le moteur
   selon la plateforme (masqué sur web et iOS). Sélection de classe et draft de départ gagnent un
   retour, demandé pour le build Windows ; le draft post-boss, qui partage la mise en page, n'en
   reçoit délibérément pas. Le badge « NEW » du tutoriel part, et avec lui
   `TutorialProgressService`, dont il était le seul lecteur. Même passe : `systemPatterns.md`
   passe à **150 lignes** de plafond et perd ses en-têtes de sections à fiche unique, arbitrage
   du propriétaire en attente depuis le 2026-09-05. Dernier geste : plus aucun écran ne code
   l'identité de classe en dur ([ADR-090](../_adr/ADR-090-identite-visuelle-de-classe-portee-par-la-donnee.md) D14).
