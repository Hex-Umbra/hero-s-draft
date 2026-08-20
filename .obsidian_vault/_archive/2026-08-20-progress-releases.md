# Archive — progress.md, historique des releases (2026-08-20)

Ligne sortie du tableau « Historique des releases (10 dernières) » de
`../_memory_bank/progress.md` par débordement du plafond FIFO, lors de la synchronisation
du 20 août 2026 (livraison de P-04, releases `0.4.8`). Conservée verbatim. **Ne pas éditer.**

| Version | Date | Titre | Description des changements clés |
|:---|:---|:---|:---|
| **v0.2.8** | 2026-06-24 | Résolution du Bug de Clés Dupliquées | Résolution de l'erreur "Duplicate keys found" dans l'overlay de notification en combinant le timestamp en microsecondes avec un suffixe pseudo-aléatoire généré par une instance statique unique de `Random`. Garantit des identifiants uniques stables pour toutes les notifications simultanées. |

Décision correspondante — [ADR-075](../_adr/ADR-075-resolution-robuste-des-cles-dupliquees-dans-l-over.md).
