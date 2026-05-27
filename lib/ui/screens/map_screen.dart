import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/run_controller.dart';
import '../../models/map_node.dart';
import 'game_screen.dart';
import 'shop_screen.dart';
import 'deck_screen.dart';
import 'rest_screen.dart';
import 'event_screen.dart';
import '../../models/card_instance.dart';
import '../../game/controllers/deck_controller.dart';
import '../widgets/blur_wrapper.dart';
import '../widgets/map/map_connection_painter.dart';
import '../widgets/map/map_legend.dart';
import '../widgets/map/map_node_widget.dart';
import '../widgets/map/player_pawn.dart';
import '../widgets/map/dialogs/stats_dialog.dart';
import '../widgets/map/dialogs/relics_dialog.dart';
import '../widgets/map/dialogs/probabilities_dialog.dart';
import '../widgets/map/hero_mini_stats_panel.dart';

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
      String? hoveredNodeId, List<MapNode> nodes, String? currentNodeId) {
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
    if (_findPathToCurrent(hoveredNodeId, currentNodeId, nodes, reachableNodes,
        reachableConnections)) {
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
          parent.id, startId, allNodes, pathNodes, pathConnections)) {
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
      final key = '${card.data.id}_${card.level}';
      counts[key] = (counts[key] ?? 0) + 1;
      if (counts[key]! >= 3) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
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
        double actualY = targetNode.position.y +
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

    return Scaffold(
      backgroundColor: const Color(0xFFE8D5B5), // Fond parchemin clair
      appBar: AppBar(
        title: Text(
          '${l10n.worldMap} - Acte ${runState.act}',
          style: const TextStyle(
            color: Color(0xFF4A3728),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            const Color(0xFFD2B48C).withAlpha(200), // Tan translucide
        elevation: 2,
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
                  Navigator.of(
                    context,
                  ).push(
                      MaterialPageRoute(builder: (context) => const DeckScreen()));
                },
                icon: Stack(
                  children: [
                    const Icon(Icons.style, color: Color(0xFF4A3728), size: 20),
                    if (canMerge)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 8,
                            minHeight: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                label: Text(
                  canMerge ? 'DECK (!)' : l10n.myDeck.toUpperCase(),
                  style: TextStyle(
                    color: canMerge ? Colors.redAccent : const Color(0xFF4A3728),
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
              Container(
                  width: 1,
                  height: 20,
                  color: const Color(0xFF4A3728).withAlpha(50)),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(50, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => StatsDialog.show(context),
                icon: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFF4A3728), size: 20),
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
                  color: const Color(0xFF4A3728).withAlpha(50)),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(50, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => RelicsDialog.show(context),
                icon: const Icon(Icons.inventory_2_outlined,
                    color: Color(0xFF4A3728), size: 20),
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
                  color: const Color(0xFF4A3728).withAlpha(50)),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(50, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => ProbabilitiesDialog.show(context),
                icon: const Icon(Icons.casino_outlined,
                    color: Color(0xFF4A3728), size: 20),
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
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Color(0xFF8B4513),
                  size: 24,
                ),
                const SizedBox(width: 4),
                Text(
                  '${runState.gold}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
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
                        isAvailable:
                            _isNodeAvailable(node, nodes, currentNodeId),
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
          const Positioned(
            left: 20,
            bottom: 20,
            child: MapLegend(),
          ),
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
          const Positioned(
            right: 20,
            bottom: 20,
            child: HeroMiniStatsPanel(),
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
    if (node.type == MapNodeType.shop ||
        node.type == MapNodeType.rest ||
        node.type == MapNodeType.event) {
      _showNodeOverlay(context, node);
    } else {
      ref.read(runProvider.notifier).travelToNode(node.id);

      Widget destination;
      switch (node.type) {
        case MapNodeType.combat:
        case MapNodeType.elite:
        case MapNodeType.boss:
          destination = const GameScreen();
          break;
        default:
          destination = const GameScreen();
      }

      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => destination));
    }
  }

  void _showNodeOverlay(BuildContext context, MapNode node) {
    ref.read(runProvider.notifier).travelToNode(node.id);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'NodeOverlay',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        Widget content;
        if (node.type == MapNodeType.shop) {
          content = const ShopScreen();
        } else if (node.type == MapNodeType.rest) {
          content = const RestScreen();
        } else {
          content = const EventScreen();
        }

        return Consumer(
          builder: (context, ref, child) {
            final runState = ref.watch(runProvider);
            bool isCompleted = false;
            try {
              final activeNode =
                  runState.mapNodes.firstWhere((n) => n.id == node.id);
              isCompleted = activeNode.isCompleted;
            } catch (_) {}

            return PopScope(
              canPop: isCompleted,
              child: BlurWrapper(
                sigma: 5,
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.85,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(150),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: content,
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }
}
