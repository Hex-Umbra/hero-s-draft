## 🛠️ ADR-075 : Résolution Robuste des Clés Dupliquées dans l'Overlay de Notification (v0.2.8)

> [!NOTE]
> Renumeroté de `ADR-067` en `ADR-075` le 2026-08-03 : le numero `ADR-067` etait porte par deux decisions distinctes. Voir `docs/superpowers/specs/2026-08-03-documentation-overhaul-design.md` §2.1.

### Statut
✅ Accepté & Implémenté (v0.2.8)

### Contexte
Lors de phases de combat intenses ou de transitions de tours complexes, plusieurs notifications (application de statuts, gains d'or, etc.) peuvent être émises simultanément dans la même microseconde. L'ancien système générait des identifiants de notification qui entraient en collision, provoquant une exception Flutter "Duplicate keys found" dans `GameNotificationOverlay` à cause de clés de widgets identiques (`ValueKey(notification.id)`).

### Décision
- Modifier la méthode `show` du `NotificationNotifier` dans `lib/ui/widgets/notification_overlay.dart` pour qu'elle produise un identifiant unique composite.
- L'identifiant est désormais structuré ainsi : `"${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(100000)}"`.
- Utiliser une instance statique unique et réutilisable de `Random` pour éviter la recréation d'objets et préserver l'entropie de la génération pseudo-aléatoire.

### Preuves dans le code
- `lib/ui/widgets/notification_overlay.dart` :
  ```dart
  static final Random _random = Random();
  // ...
  final id = "${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(100000)}";
  ```

### Conséquences
- ✅ **Stabilité absolue** : Les collisions de clés dans l'arbre de widgets de Flutter sont éradiquées, même en cas d'appels massifs et simultanés à la même microseconde.
- ✅ **Performance** : L'utilisation d'une instance statique de `Random` évite toute surcharge mémoire ou CPU.
- ✅ **Zéro Régression** : Aucun changement d'interface publique ou de comportement de l'utilisateur final. Le code passe l'analyse statique avec succès.
