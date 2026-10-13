# Comptes rendus de vague, et tests manuels

Un compte rendu et un fichier de tests manuels par vague d'un chantier livré par vagues, écrits sur la branche de la vague : `<AAAA-MM-JJ>-<chantier>-vague-<N>-compte-rendu.md` et `<AAAA-MM-JJ>-<chantier>-vague-<N>-tests-manuels.md`. Le chantier est dans le nom ; la date est celle où le compte rendu s'ouvre, à la fin du premier plan. Ce que chacun contient est fixé par le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), §3.8, et par [ADR-108](../../../.obsidian_vault/_adr/ADR-108-methode-par-vagues-calibree-plans-de-decisions-sans-simulation.md) D6 ; ce README porte les formes et les définitions, écrites une fois. Le récit non technique est ailleurs : [`docs/suivi_vagues_chantier/`](../../suivi_vagues_chantier/).

## Le compte rendu — 150 lignes au plus, corrections comprises

| § | Contenu | Plafond |
|:---|:---|---:|
| 0 | **Pour le propriétaire** : quoi tester d'abord, par risque ; les arbitrages que le joueur verra ; ceux faits sans lui ; les risques connus ; trois commandes | 30 l. |
| 1 | La branche et ses chiffres, en une table : version, commits, tests `base → total`, `dart analyze`, versions de Superpowers et de Claude Code | 10 l. |
| 2 | Les arbitrages, **une ligne chacun** : question, classe, choix, filtre ; puis les décisions de SDD, une ligne chacune, plan après plan | — |
| 3 | Les tests manuels : le renvoi au fichier voisin, et `K ✅ · L ❌ · M non testés` une fois le test fait | 3 l. |
| 4 | Trouvé périmé, et pour la file | 10 l. |
| 5 | Les leçons : chacune avec l'amendement de méthode qu'elle propose, ou « rien » | 5 |
| 6 | Les statistiques de la session : la table ci-dessous, et rien d'autre | 20 l. |
| — | `## Corrections du <JJ/MM/AAAA>` : ce qui a été corrigé, puis la table des statistiques de cette session | par session |

Les options écartées d'un arbitrage ne sont pas ici : elles sont dans le fichier de vérifications de la spec (`…-design-verifications.md`). Les comptes rendus des vagues 1 à 3 précèdent ce plafond et gardent leur forme.

### La table des statistiques

```markdown
**Mesuré le <JJ/MM/AAAA à HH:MM>**, avant le commit de §3.8 — sessions : <n> · arrêts : <n> · durée : <bout en bout>, dont <travail> · tours de spec : <n> · tours de plan : <n>
Prix lus le <JJ/MM> sur https://platform.claude.com/docs/en/about-claude/pricing · 1 € = <taux> $ (BCE, <date>) · suppléments : aucun (`server_tool_use`, `speed`, `inference_geo` vérifiés)

| | Spec | Plans | Implémentation | Fin de vague | Orchestrateur(s) | **Total** |
|:---|---:|---:|---:|---:|---:|---:|
| Temps actif | | | | | | |
| Agents — Opus / Sonnet | | | | | | |
| Appels au modèle | | | | | | |
| Jetons traités, dont hors cache | | | | | | |
| Sortie (minimum) | | | | | | |
| Coût API — $ / € | | | | | | |
```

### Les définitions, les mêmes à chaque vague

- **Les sources** : les transcriptions de Claude Code, sous `~/.claude/projects/<dossier du projet>/` — `<id de session>.jsonl` pour l'orchestrateur (l'id de session est le nom de son dossier scratchpad), et sous `<id de session>/subagents/` un `.jsonl` et un `.meta.json` par sous-agent, reprises par message comprises, workflows compris (`subagents/workflows/`). Un message de l'assistant s'écrit sur plusieurs lignes : son `usage` se compte **une fois par identifiant de message**, au maximum de ses lignes. Le script de mesure s'écrit dans le scratchpad, il n'entre pas dans le dépôt. Les transcriptions n'enregistrent pas toujours la sortie finale d'un message : **la sortie est un minimum**, et le coût de sortie avec elle.
- **Le temps** : le début (première ligne de la session), la fin (dernier message de l'orchestrateur avant la mesure), la durée de bout en bout et de travail, et celle de chaque étape d'après les heures des commits de la branche, en heure locale ; le temps actif, de l'orchestrateur et cumulé des sous-agents, est la somme des écarts de moins de dix minutes entre lignes successives.
- **Les agents** : le total, orchestrateurs compris, par étape et par modèle ; les reprises par message ; le nombre d'appels au modèle.
- **Les jetons** : par étape — entrée hors cache, écriture en cache, lecture du cache, sortie, total traité ; la table ne montre que le total traité, la part hors cache et la sortie.
- **Le coût au tarif de l'API** : chaque catégorie multipliée par son prix, modèle par modèle ; les écritures en cache au prix de leur durée, que `cache_creation` ventile (`ephemeral_5m_input_tokens`, `ephemeral_1h_input_tokens`) ; la réflexion comptée dans la sortie. Les prix se lisent le jour même, en dollars, et se convertissent au dernier taux de référence de la BCE (`https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml`). C'est le coût qu'aurait la session facturée à l'API, pas la facture de l'abonnement.
- **Les étapes** : *spec* — rédaction, vérifications, corrections ; *plans* — idem ; *implémentation* — SDD, revues comprises ; *fin de vague* — convergence s'il y en a, skills, documents.

## Les tests manuels

```markdown
# Vague <N> — `<version>` — tests manuels

**Branche** : `<branche>` · **Compte rendu** : [<fichier>](<fichier>)
**Testé le** : <JJ/MM/AAAA>, sur `<sha>`, sur <plateforme>
**Résultat** : <K> ✅ · <L> ❌ · <M> non testés

## À tester d'abord
<!-- les tests, du plus risqué au moins risqué : une ligne chacun, avec son numéro -->

## T1 — <ce qui est testé, en clair>
- **Atteindre la situation** : <en jouant, ou par les onglets existants du menu de debug — lesquels, quelles valeurs>
- **Faire** : <les étapes>
- **Attendu** : <ce que l'écran doit montrer, chiffres compris>
- **Ne doit pas changer** : <ce qui reste identique>
- **Résultat** : ✅ · ❌ · non testé — <ce qui a été vu, si ❌>

## Ce qui doit rester inchangé
<!-- une ligne par chose -->

## Défauts trouvés
| # | Test | Ce qui a été vu | Gravité ressentie | Corrigé par |
|:---:|:---|:---|:---|:---|
```

Un agent l'écrit à la fin de la vague (orchestration §4.7) ; le propriétaire remplit les résultats et la table des défauts, et commite sur la branche. Le nombre de ❌ est la mesure de qualité de la vague, et remplit la colonne « Défauts » du compte rendu suivant.
