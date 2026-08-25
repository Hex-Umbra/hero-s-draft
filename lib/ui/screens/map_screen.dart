import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../models/map_node.dart';
import 'game_screen.dart';
import 'shop_screen.dart';
import 'rest_screen.dart';
import 'event_screen.dart';
import 'relic_exchange_screen.dart';
import 'forge_fusion_screen.dart';
import 'draft_screen.dart';
import '../../models/card_instance.dart';
import '../../game/controllers/deck_controller.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/map/map_connection_painter.dart';
import '../widgets/map/map_legend.dart';
import '../widgets/map/map_node_widget.dart';
import '../widgets/map/player_pawn.dart';
import '../widgets/map/hero_mini_stats_panel.dart';
import '../widgets/map/level_up_overlay.dart';
import '../widgets/map/map_toolbar.dart';
import '../widgets/map/map_tooltip_overlay.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/gold_indicator.dart';
import '../widgets/hud/dialogs/pause_dialog.dart';
import '../../game/services/map_path_highlighter.dart';

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
    if (MapPathHighlighter.findPathToCurrent(
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

  void _showPauseMenu() {
    PauseDialog.show(
      context,
      onResume: () => Navigator.of(context).pop(),
      onExit: () => Navigator.of(context).popUntil((route) => route.isFirst),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final runState = ref.watch(runProvider);
    final inventoryState = ref.watch(inventoryProvider);
    final nodes = runState.mapNodes;
    final currentNodeId = runState.currentNodeId;
    final screenSize = MediaQuery.of(context).size;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCameraIfNeeded(runState, nodes, currentNodeId, screenSize);
    });

    final deckState = ref.watch(deckProvider);
    final canMerge = _checkCanMerge(deckState.masterDeck);

    final l10n = AppLocalizations.of(context)!;

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.parchment,
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showPauseMenu();
        }
      },
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
        leading: MapToolbar(
          canMerge: canMerge,
          deckCount: deckState.masterDeck.length,
          relicsCount: inventoryState.relics.length,
        ),
        actions: [
          const GoldIndicator(isParchment: true),
          IconButton(
            icon: const Icon(
              Icons.pause_circle_outline,
              color: Color(0xFF4A3728),
            ),
            onPressed: _showPauseMenu,
          ),
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
            MapTooltipOverlay(
              title: _tooltipTitle,
              description: _tooltipDescription,
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

  void _centerCameraIfNeeded(
    RunState runState,
    List<MapNode> nodes,
    String? currentNodeId,
    Size screenSize,
  ) {
    // Force le re-centrage si on change d'acte ou si on n'a jamais centré
    if (_lastActCentered == runState.act &&
        !(currentNodeId == null && _lastActCentered == null)) {
      return;
    }

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
    double actualY = targetNode.position.y + 80.0 + 1000; // padding top + visual Y offset

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
      case MapNodeType.forgeFusion:
        destination = const ForgeFusionScreen();
        break;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => destination));
  }
}
