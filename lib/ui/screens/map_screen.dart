import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/extensions.dart' hide Matrix4;
import '../../game/controllers/run_controller.dart';
import '../../models/map_node.dart';
import 'game_screen.dart';
import 'shop_screen.dart';
import 'deck_screen.dart';
import 'rest_screen.dart';
import 'event_screen.dart';
import '../../models/card_instance.dart';
import '../../game/controllers/deck_controller.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  int? _lastActCentered;

  late final AnimationController _dashController;

  // État de la surbrillance
  Set<String> _highlightedNodeIds = {};
  Set<(String, String)> _highlightedConnections = {};

  void _updateHighlight(String? hoveredNodeId, List<MapNode> nodes, String? currentNodeId) {
    if (hoveredNodeId == null) {
      if (_highlightedNodeIds.isNotEmpty || _highlightedConnections.isNotEmpty) {
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
    if (_findPathToCurrent(hoveredNodeId, currentNodeId, nodes, reachableNodes, reachableConnections)) {
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
    if (targetId == startId || (startId == null && targetId.startsWith('node_0_'))) {
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
      if (_findPathToCurrent(parent.id, startId, allNodes, pathNodes, pathConnections)) {
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
        double actualX = targetNode.position.x + 1000; // padding left
        double actualY = targetNode.position.y + 1000; // padding top

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

    return Scaffold(
      backgroundColor: const Color(0xFFE8D5B5), // Fond parchemin clair
      appBar: AppBar(
        title: Text(
          'Acte ${runState.act} - Carte du Monde',
          style: const TextStyle(
            color: Color(0xFF4A3728), // Texte brun foncÃ©
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFD2B48C).withAlpha(200), // Tan translucide
        elevation: 2,
        centerTitle: true,
        leadingWidth: 120,
        leading: TextButton.icon(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const DeckScreen()));
          },
          icon: Stack(
            children: [
              const Icon(Icons.style, color: Color(0xFF4A3728)),
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
                      minWidth: 10,
                      minHeight: 10,
                    ),
                  ),
                ),
            ],
          ),
          label: Text(
            canMerge ? 'DECK (!)' : 'MON DECK',
            style: TextStyle(
              color: canMerge ? Colors.redAccent : const Color(0xFF4A3728),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
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
          InteractiveViewer(
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
                  CustomPaint(
                    size: const Size(1000, 3000),
                    painter: MapConnectionPainter(
                      nodes: nodes,
                      animation: _dashController,
                      highlightedConnections: _highlightedConnections,
                      isParchmentMode: true,
                    ),
                  ),
                  ...nodes.map(
                    (node) => _MapNodeWidget(
                      node: node,
                      isAvailable: _isNodeAvailable(node, nodes, currentNodeId),
                      isCurrent: node.id == currentNodeId,
                      onTap: () => _onNodeTap(context, ref, node),
                      onShowTooltip: _showNodeTooltip,
                      onHideTooltip: _hideTooltip,
                      onHoverEnter: () => _updateHighlight(node.id, nodes, currentNodeId),
                      onHoverExit: () => _updateHighlight(null, nodes, currentNodeId),
                    ),
                  ),
                  // Pion du Joueur AnimÃ©
                  if (currentNodeId != null)
                    _PlayerPawn(
                      position: nodes.firstWhere((n) => n.id == currentNodeId).position,
                    ),
                ],
              ),
            ),
          ),
          // Légende
          Positioned(
            left: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A3728).withAlpha(230), // Brun foncé
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD2B48C)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LÉGENDE',
                    style: TextStyle(
                      color: Color(0xFFE8D5B5), // Couleur parchemin
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Divider(color: Colors.white24),
                  _LegendItem(
                    icon: Icons.flash_on,
                    color: Colors.white,
                    label: 'Combat',
                  ),
                  _LegendItem(
                    icon: Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    label: 'Élite',
                  ),
                  _LegendItem(
                    icon: Icons.shopping_cart_outlined,
                    color: Colors.amber,
                    label: 'Boutique',
                  ),
                  _LegendItem(
                    icon: Icons.nightlight_round,
                    color: Colors.greenAccent,
                    label: 'Repos',
                  ),
                  _LegendItem(
                    icon: Icons.help_outline,
                    color: Colors.blueAccent,
                    label: 'Événement',
                  ),
                  _LegendItem(
                    icon: Icons.dangerous,
                    color: Colors.purpleAccent,
                    label: 'Boss',
                  ),
                ],
              ),
            ),
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
      return currentNode.connections.contains(node.id);
    } catch (e) {
      // Cas de repli si le noeud actuel n'est plus dans la liste (ex: changement d'acte mal synchronisÃ©)
      return node.id.startsWith('node_0_');
    }
  }

  void _onNodeTap(BuildContext context, WidgetRef ref, MapNode node) {
    if (node.type == MapNodeType.shop || node.type == MapNodeType.rest) {
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
        case MapNodeType.event:
          destination = const EventScreen();
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
      pageBuilder: (context, anim1, anim2) {
        Widget content;
        if (node.type == MapNodeType.shop) {
          content = const ShopScreen();
        } else {
          content = const RestScreen();
        }

        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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

class _MapNodeWidget extends StatefulWidget {
  final MapNode node;
  final bool isAvailable;
  final bool isCurrent;
  final VoidCallback onTap;
  final Function(String, String) onShowTooltip;
  final VoidCallback onHideTooltip;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;

  const _MapNodeWidget({
    required this.node,
    required this.isAvailable,
    required this.isCurrent,
    required this.onTap,
    required this.onShowTooltip,
    required this.onHideTooltip,
    required this.onHoverEnter,
    required this.onHoverExit,
  });

  @override
  State<_MapNodeWidget> createState() => _MapNodeWidgetState();
}

class _MapNodeWidgetState extends State<_MapNodeWidget> {
  bool _isHovered = false;

  (String, String) _getTooltipData() {
    switch (widget.node.type) {
      case MapNodeType.combat:
        return (
          'COMBAT',
          'Une rencontre standard avec des ennemis. Gagnez de l\'or et de nouvelles cartes.'
        );
      case MapNodeType.elite:
        return (
          'ÉLITE',
          'Un combat très difficile contre des ennemis puissants. Offre de meilleures récompenses et des reliques.'
        );
      case MapNodeType.shop:
        return (
          'BOUTIQUE',
          'Dépensez votre or pour acheter des cartes, retirer des cartes de votre deck ou cloner vos meilleures cartes.'
        );
      case MapNodeType.rest:
        return (
          'REPOS',
          'Une zone sûre pour reprendre des forces ou améliorer votre équipement.'
        );
      case MapNodeType.event:
        return (
          'ÉVÉNEMENT',
          'Une rencontre imprévisible qui peut vous octroyer des bonus... ou des malus.'
        );
      case MapNodeType.boss:
        return (
          'BOSS',
          'L\'épreuve ultime de cet acte. Battez le boss pour passer à l\'acte suivant.'
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (widget.node.type) {
      case MapNodeType.combat:
        icon = Icons.flash_on;
        color = Colors.white70;
        break;
      case MapNodeType.elite:
        icon = Icons.warning_amber_rounded;
        color = Colors.redAccent;
        break;
      case MapNodeType.shop:
        icon = Icons.shopping_cart_outlined;
        color = Colors.amber;
        break;
      case MapNodeType.rest:
        icon = Icons.nightlight_round;
        color = Colors.greenAccent;
        break;
      case MapNodeType.event:
        icon = Icons.help_outline;
        color = Colors.blueAccent;
        break;
      case MapNodeType.boss:
        icon = Icons.dangerous;
        color = Colors.purpleAccent;
        break;
    }

    final tooltipData = _getTooltipData();

    return Positioned(
      left: widget.node.position.x - 35,
      top: widget.node.position.y - 35,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          widget.onHoverEnter();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          widget.onHoverExit();
        },
        cursor: widget.isAvailable
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.isAvailable ? widget.onTap : null,
          onLongPressStart: (_) =>
              widget.onShowTooltip(tooltipData.$1, tooltipData.$2),
          onLongPressEnd: (_) => widget.onHideTooltip(),
          child: Column(
            children: [
              Opacity(
                opacity: widget.node.isCompleted
                    ? 0.4
                    : (widget.isAvailable ? 1.0 : 0.2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isHovered && widget.isAvailable ? 85 : 70,
                  height: _isHovered && widget.isAvailable ? 85 : 70,
                  decoration: BoxDecoration(
                    color: widget.isCurrent
                        ? const Color(0xFF2A2A40)
                        : const Color(0xFF1A1A2E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isCurrent
                          ? Colors.yellow
                          : (_isHovered && widget.isAvailable
                              ? Colors.white
                              : (widget.isAvailable
                                  ? color
                                  : color.withAlpha(128))),
                      width: widget.isCurrent || _isHovered ? 4 : 2,
                    ),
                    boxShadow: (widget.isCurrent ||
                            (_isHovered && widget.isAvailable))
                        ? [
                          BoxShadow(
                            color: (widget.isCurrent ? Colors.yellow : color)
                                .withAlpha(128),
                            blurRadius: _isHovered ? 20 : 15,
                            spreadRadius: _isHovered ? 4 : 2,
                          ),
                        ]
                        : [],
                  ),
                  child: Icon(
                    icon,
                    color: widget.isAvailable || widget.isCurrent
                        ? color
                        : color.withAlpha(128),
                    size: _isHovered && widget.isAvailable ? 42 : 35,
                  ),
                ),
              ),
              if (widget.node.isCompleted)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class MapConnectionPainter extends CustomPainter {
  final List<MapNode> nodes;
  final Animation<double> animation;
  final Set<(String, String)> highlightedConnections;
  final bool isParchmentMode;

  MapConnectionPainter({
    required this.nodes,
    required this.animation,
    this.highlightedConnections = const {},
    this.isParchmentMode = false,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paintBase = Paint()
      ..color = isParchmentMode
          ? const Color(0xFF4A3728).withAlpha(80) // Brun encre dilué
          : Colors.white.withAlpha(60)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paintHighlight = Paint()
      ..color = isParchmentMode
          ? const Color(0xFF8B4513) // Brun sienne pour la surbrillance
          : Colors.blueAccent
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final double dashLength = 12.0;
    final double dashSpace = 8.0;
    final double phase = animation.value * (dashLength + dashSpace) * 2;

    for (var node in nodes) {
      for (var targetId in node.connections) {
        try {
          final targetNode = nodes.firstWhere((n) => n.id == targetId);
          final bool isHighlighted = highlightedConnections.contains((node.id, targetId));
          final paint = isHighlighted ? paintHighlight : paintBase;

          final Path path = Path()
            ..moveTo(node.position.x, node.position.y)
            ..lineTo(targetNode.position.x, targetNode.position.y);

          for (final ui.PathMetric metric in path.computeMetrics()) {
            double distance = phase - (dashLength + dashSpace) * 2;
            bool draw = true;
            while (distance < metric.length) {
              final double len = draw ? dashLength : dashSpace;
              if (draw) {
                final double start = distance < 0 ? 0 : distance;
                final double end = (distance + len > metric.length)
                    ? metric.length
                    : distance + len;
                if (start < end) {
                  canvas.drawPath(metric.extractPath(start, end), paint);
                }
              }
              distance += len;
              draw = !draw;
            }
          }
        } catch (e) {
          // Ignorer si la cible n'existe pas
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapConnectionPainter oldDelegate) =>
      oldDelegate.nodes != nodes ||
      oldDelegate.animation != animation ||
      oldDelegate.highlightedConnections != highlightedConnections;
}

class _PlayerPawn extends StatelessWidget {
  final Vector2 position;

  const _PlayerPawn({required this.position});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutBack, // Petit effet de ressort lors de l'arrivée
      left: position.x - 20,
      top: position.y - 65, // Un peu au dessus du centre du node
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withAlpha(150),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin,
              color: Colors.blueAccent,
              size: 32,
            ),
          ),
          CustomPaint(
            size: const Size(10, 10),
            painter: _PawnPointerPainter(),
          ),
        ],
      ),
    );
  }
}

class _PawnPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

