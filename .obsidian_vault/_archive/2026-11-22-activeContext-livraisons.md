# Rotation de `activeContext.md` — 2026-11-22

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-11-22**,
poussée par l'entrée de la **vague 1 du bestiaire** (P-05, l'interface des ennemis), livrée sur la
branche `feat/v0.6.1-interface-des-ennemis`.
FIFO strict à 3 : la 4ᵉ livraison sort. Recopiée **telle quelle** — chiffres, dates et affirmations
intouchés ; ses liens `../_adr/` se résolvent depuis ce dossier comme depuis le sien.

## La livraison sortie

3. **Vague 7 — P-53 : les charges élémentaires, le Gel, le Feu et la Foudre** (2026-11-15 →
   2026-11-17, branche `feat/v0.5.9-p53-charges-elementaires`, 30 commits `b50eca31` → `d15bcd04`
   sur `main` à `535f9ded` — **fusionnée dans `main` le 2026-11-18 par la PR #55, merge
   `5d894785`, taguée `v0.5.9`, CI/CD verte**) — **les éléments rompent.** **Le
   cadre en donnée** : un fichier par charge sous `charges/` — la onzième source et la onzième
   catégorie de l'éditeur —, qui déclare seuils, montée, surcharge, déclin, moment et sorte de
   rupture, validé au chargement (un seuil de Feu sous 3 est refusé) ; quatre sortes de rupture
   seules en Dart, une piste par porteur hors sauvegarde, `ChargeRules` seule écriture des règles.
   **Le Gel** (seuils 3, 6 en boss, 5 pour le héros, +1 à chaque gel) ôte toute son action à
   l'ennemi ; le héros gelé frappe moitié moins à son tour suivant, sans le perdre. **Le Feu**
   s'accumule sans limite et, au tour du porteur, chaque tranche de 3 explose sur ses voisins — 12
   et 1 Feu chacun —, **une chaîne vague par vague** que le contrôleur joue et que Flame anime.
   **La Foudre** ajoute +1 par point à chaque coup, +2 une fois chargée, jusqu'à la fin de la phase.
   Le Gel **quitte le barème proportionnel** ; le pipeline reçoit le catalogue ; l'intention d'un
   ennemi n'est plus réduite. **Les dix contenus relus** : *Embrasement* 3 Feu, *Congelant* 1 Gel
   par niveau, les autres inchangés ; la Brûlure devient le Feu, l'Électrocution la Foudre. **À
   l'écran** : « ❄ 2/3 », « 🔥 5 », « ⚡ Chargé », l'intention barrée d'un ennemi gelé, le panneau du
   héros, le tutoriel, une section « Charges » au debug ; en partie 2, **la gangue, l'onde et le
   halo**, et le bonus « +N » de chaque coup de Foudre. **Trois arrêts sur des questions P**, chacun
   levé par le propriétaire sur maquettes : P-a à P-e (15/11), Q-P1 (16/11), Q-P2 (17/11) ; spec
   prête au quatrième tour. Note de version écrite (`d15bcd04`). **1772 tests** (+90 sur la base de
   **1682**, celle de la porte d'entrée), `dart analyze` propre (**vérifié le 2026-11-17**) —
   [ADR-117](../_adr/ADR-117-les-charges-elementaires.md), qui amende ADR-023 et ADR-111 et clôt
   ADR-110.
