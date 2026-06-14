import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../models/map_node.dart';
import 'game_screen.dart';
import 'shop_screen.dart';
import 'deck_screen.dart';
import 'rest_screen.dart';
import 'event_screen.dart';
import 'relic_exchange_screen.dart';
import 'draft_screen.dart';
import '../../models/card_instance.dart';
import '../../game/controllers/deck_controller.dart';
import '../widgets/map/map_connection_painter.dart';
import '../widgets/map/map_legend.dart';
import '../widgets/map/map_node_widget.dart';
import '../widgets/map/player_pawn.dart';
import '../widgets/map/dialogs/stats_dialog.dart';
import '../widgets/map/dialogs/relics_dialog.dart';
import '../widgets/map/dialogs/probabilities_dialog.dart';
import '../widgets/map/hero_mini_stats_panel.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/gold_indicator.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  int? _lastActCentered;

  late final AnimationController _dashController;

  // État de la surbrillance
  Set<String> _highlightedNodeIds = {};
  Set<(String, String)> _highlightedConnections = {};

  void _updateHighlight(
    String? hoveredNodeId,
    List<MapNode> nodes,
    String? currentNodeId,
  ) {
    if (hoveredNodeId == null) {
      if (_highlightedNodeIds.isNotEmpty ||
          _highlightedConnections.isNotEmpty) {
        setState(() {
          _highlightedNodeIds = {};
          _highlightedConnections = {};
        });
      }
      return;
    }

    // Si on survole le noeud actuel ou un noeud non atteignable, on ignore
    if (hoveredNodeId == currentNodeId) return;

    final Set<String> reachableNodes = {};
    final Set<(String, String)> reachableConnections = {};

    // Algorithme de recherche inverse : On part du noeud survolé et on remonte
    // vers le noeud actuel pour voir s'il y a un chemin.
    if (_findPathToCurrent(
      hoveredNodeId,
      currentNodeId,
      nodes,
      reachableNodes,
      reachableConnections,
    )) {
      setState(() {
        _highlightedNodeIds = reachableNodes;
        _highlightedConnections = reachableConnections;
      });
    }
  }

  bool _findPathToCurrent(
    String targetId,
    String? startId,
    List<MapNode> allNodes,
    Set<String> pathNodes,
    Set<(String, String)> pathConnections,
  ) {
    // Si on a atteint le point de départ (ou l'étage 0 si on n'a pas commencé)
    if (targetId == startId ||
        (startId == null && targetId.startsWith('node_0_'))) {
      pathNodes.add(targetId);
      return true;
    }

    // Trouver tous les parents (noeuds de l'étage précédent qui pointent vers targetId)
    bool foundPath = false;

    // Optimisation : seuls les noeuds de l'étage précédent peuvent être parents
    final targetFloor = int.parse(targetId.split('_')[1]);
    if (targetFloor == 0) return false;

    final parents = allNodes.where((n) {
      final nFloor = int.parse(n.id.split('_')[1]);
      return nFloor == targetFloor - 1 && n.connections.contains(targetId);
    });

    for (var parent in parents) {
      if (_findPathToCurrent(
        parent.id,
        startId,
        allNodes,
        pathNodes,
        pathConnections,
      )) {
        pathNodes.add(targetId);
        pathNodes.add(parent.id);
        pathConnections.add((parent.id, targetId));
        foundPath = true;
      }
    }

    return foundPath;
  }

  // État des tooltips
  String? _tooltipTitle;
  String? _tooltipDescription;
  bool _showTooltip = false;

  void _showNodeTooltip(String title, String description) {
    setState(() {
      _tooltipTitle = title;
      _tooltipDescription = description;
      _showTooltip = true;
    });
  }

  void _hideTooltip() {
    if (_showTooltip) {
      setState(() {
        _showTooltip = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _dashController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _transformationController.value =
        Matrix4.translationValues(-200.0, -1500.0, 0.0) *
        Matrix4.diagonal3Values(0.8, 0.8, 1.0);
  }

  @override
  void dispose() {
    _dashController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  bool _checkCanMerge(List<CardInstance> masterDeck) {
    final Map<String, int> counts = {};
    for (var card in masterDeck) {
      final key = '${card.data.id}_${card.rarity.name}';
      counts[key] = (counts[key] ?? 0) + 1;
      if (counts[key]! >= 3) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
    final inventoryState = ref.watch(inventoryProvider);
    final nodes = runState.mapNodes;
    final currentNodeId = runState.currentNodeId;
    final screenSize = MediaQuery.of(context).size;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force le re-centrage si on change d'acte ou si on n'a jamais centré
      if (_lastActCentered != runState.act ||
          (currentNodeId == null && _lastActCentered == null)) {
        MapNode? targetNode;
        if (currentNodeId != null) {
          targetNode = nodes.firstWhere(
            (n) => n.id == currentNodeId,
            orElse: () => nodes.first,
          );
        } else {
          // Pour un nouvel acte, on cible le milieu du premier étage
          targetNode = nodes.firstWhere(
            (n) => n.id.startsWith('node_0_'),
            orElse: () => nodes.first,
          );
        }

        double scale = 0.8;
        double actualX =
            (currentNodeId != null ? targetNode.position.x : 500.0) +
            1000; // padding left
        double actualY =
            targetNode.position.y +
            80.0 +
            1000; // padding top + visual Y offset

        double dx = (screenSize.width / 2) - (actualX * scale);
        double dy = (screenSize.height / 2) - (actualY * scale);

        if (mounted) {
          setState(() {
            _transformationController.value =
                Matrix4.translationValues(dx, dy, 0.0) *
                Matrix4.diagonal3Values(scale, scale, 1.0);
            _lastActCentered = runState.act;
          });
        }
      }
    });

    final deckState = ref.watch(deckProvider);
    final canMerge = _checkCanMerge(deckState.masterDeck);

    final l10n = AppLocalizations.of(context)!;

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.parchment,
      appBar: AppBar(
        title: Text(
          '${l10n.worldMap} - Acte ${runState.act}',
          style: const TextStyle(
            color: Color(0xFF4A3728),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 430,
        leading: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(50, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const DeckScreen()),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.style, color: Color(0xFF4A3728), size: 20),
                    if (deckState.masterDeck.isNotEmpty)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: canMerge
                                ? const Color(0xFFD32F2F)
                                : const Color(0xFF8B4513),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE8D5B5),
                              width: 1,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '${deckState.masterDeck.length}',
                            style: const TextStyle(
                              color: Color(0xFFE8D5B5),
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: Text(
                  canMerge ? 'DECK (!)' : l10n.myDeck.toUpperCase(),
                  style: TextStyle(
                    color: canMerge
                        ? Colors.redAccent
                        : const Color(0xFF4A3728),
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: const Color(0xFF4A3728).withAlpha(50),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(50, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => StatsDialog.show(context),
                icon: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF4A3728),
                  size: 20,
                ),
                label: Text(
                  l10n.stats.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF4A3728),
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: const Color(0xFF4A3728).withAlpha(50),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(50, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => RelicsDialog.show(context),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF4A3728),
                      size: 20,
                    ),
                    if (inventoryState.relics.isNotEmpty)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B4513),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE8D5B5),
                              width: 1,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '${inventoryState.relics.length}',
                            style: const TextStyle(
                              color: Color(0xFFE8D5B5),
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: Text(
                  l10n.relics.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF4A3728),
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: const Color(0xFF4A3728).withAlpha(50),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(50, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => ProbabilitiesDialog.show(context),
                icon: const Icon(
                  Icons.casino_outlined,
                  color: Color(0xFF4A3728),
                  size: 20,
                ),
                label: Text(
                  l10n.chances.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF4A3728),
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: const [
          GoldIndicator(isParchment: true),
        ],
      ),
      body: Stack(
        children: [
          Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                final matrix = _transformationController.value.clone();
                final translation = matrix.getTranslation();
                // vertical scrolling of map screen using mouse wheel
                final double newY =
                    translation.y - pointerSignal.scrollDelta.dy;
                matrix.setTranslationRaw(translation.x, newY, translation.z);
                _transformationController.value = matrix;
              }
            },
            child: InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(2000),
              minScale: 0.1,
              maxScale: 2.0,
              scaleEnabled: false,
              constrained: false,
              child: Container(
                width: 3000,
                height: 5000,
                padding: const EdgeInsets.symmetric(
                  horizontal: 1000,
                  vertical: 1000,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5DEB3), // Couleur Wheat
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFF5DEB3),
                      const Color(0xFFE8D5B5),
                      const Color(0xFFD2B48C),
                    ],
                    radius: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        size: const Size(1000, 3000),
                        painter: MapConnectionPainter(
                          nodes: nodes,
                          animation: _dashController,
                          highlightedConnections: _highlightedConnections,
                          isParchmentMode: true,
                        ),
                      ),
                    ),
                    ...nodes.map(
                      (node) => MapNodeWidget(
                        node: node,
                        isAvailable: _isNodeAvailable(
                          node,
                          nodes,
                          currentNodeId,
                        ),
                        isCurrent: node.id == currentNodeId,
                        onTap: () => _onNodeTap(context, ref, node),
                        onShowTooltip: _showNodeTooltip,
                        onHideTooltip: _hideTooltip,
                        onHoverEnter: () =>
                            _updateHighlight(node.id, nodes, currentNodeId),
                        onHoverExit: () =>
                            _updateHighlight(null, nodes, currentNodeId),
                      ),
                    ),
                    // Pion du Joueur Animé
                    if (currentNodeId != null)
                      PlayerPawn(
                        position: nodes
                            .firstWhere((n) => n.id == currentNodeId)
                            .position,
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Légende
          const Positioned(left: 20, bottom: 20, child: MapLegend()),
          // Tooltip Overlay
          if (_showTooltip)
            Positioned(
              left: 40,
              right: 40,
              top: 100,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4ECD8), // Fond papier
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF8B4513),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(100),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tooltipTitle ?? '',
                        style: const TextStyle(
                          color: Color(0xFF8B4513), // Brun sienne
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(color: Colors.black12),
                      Text(
                        _tooltipDescription ?? '',
                        style: const TextStyle(
                          color: Color(0xFF4A3728), // Brun sombre
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Aperçu des Stats du Joueur (Flottant en bas à droite)
          const Positioned(right: 20, bottom: 20, child: HeroMiniStatsPanel()),

          // Overlay de Level Up
          if (runState.pendingDrafts > 0)
            LevelUpOverlay(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DraftScreen(
                      onDraftComplete: () {
                        ref.read(runProvider.notifier).decrementPendingDrafts();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  bool _isNodeAvailable(
    MapNode node,
    List<MapNode> allNodes,
    String? currentNodeId,
  ) {
    final runState = ref.read(runProvider);
    if (runState.pendingDrafts > 0) return false;

    if (currentNodeId == null) {
      return node.id.startsWith('node_0_');
    }

    try {
      final currentNode = allNodes.firstWhere((n) => n.id == currentNodeId);

      // Si le nœud actuel n'est pas complété, on ne peut pas avancer.
      // Seul le nœud actuel lui-même est actif afin de pouvoir y ré-entrer.
      if (!currentNode.isCompleted) {
        return node.id == currentNodeId;
      }

      return currentNode.connections.contains(node.id);
    } catch (e) {
      // Cas de repli si le noeud actuel n'est plus dans la liste (ex: changement d'acte mal synchronisé)
      return node.id.startsWith('node_0_');
    }
  }

  void _onNodeTap(BuildContext context, WidgetRef ref, MapNode node) {
    if (ref.read(runProvider).pendingDrafts > 0) return;
    ref.read(runProvider.notifier).travelToNode(node.id);

    Widget destination;
    switch (node.type) {
      case MapNodeType.combat:
      case MapNodeType.elite:
      case MapNodeType.boss:
        destination = const GameScreen();
        break;
      case MapNodeType.shop:
        destination = const ShopScreen();
        break;
      case MapNodeType.rest:
        destination = const RestScreen();
        break;
      case MapNodeType.event:
        destination = const EventScreen();
        break;
      case MapNodeType.relicExchange:
        destination = RelicExchangeScreen(node: node);
        break;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => destination));
  }
}

class LevelUpOverlay extends StatefulWidget {
  final VoidCallback onTap;

  const LevelUpOverlay({super.key, required this.onTap});

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned.fill(
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.black.withValues(alpha: 0.85 * _opacityAnimation.value),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.amberAccent.withValues(alpha: 0.8),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '🎉 LEVEL UP ! 🎉',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.amber,
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Votre héros a gagné en puissance !',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'TOUCHEZ POUR OBTENIR VOS RÉCOMPENSES',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
