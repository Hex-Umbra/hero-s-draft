import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _MapScreenState extends ConsumerState<MapScreen> {
  final TransformationController _transformationController =
      TransformationController();
  int? _lastActCentered;

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
    _transformationController.value =
        Matrix4.translationValues(-200.0, -1500.0, 0.0) *
        Matrix4.diagonal3Values(0.8, 0.8, 1.0);
  }

  @override
  void dispose() {
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
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: Text(
          'Acte ${runState.act} - Carte du Monde',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black45,
        elevation: 0,
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
              const Icon(Icons.style, color: Colors.white),
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
              color: canMerge ? Colors.amber : Colors.white,
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
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 4),
                Text(
                  '${runState.gold}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
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
            boundaryMargin: const EdgeInsets.all(
              2000,
            ), // Très large marge pour éviter les snaps sur 4K
            minScale: 0.1,
            maxScale: 2.0,
            scaleEnabled: false, // Bloque le zoom (dézoom/zoom désactivé)
            constrained: false, // Permet au Container d'être plus grand que l'écran
            child: Container(
              width: 3000, // Largeur généreuse
              height: 5000, // Hauteur généreuse
              padding: const EdgeInsets.symmetric(
                horizontal: 1000,
                vertical: 1000,
              ), // Centrage des nodes dans le container
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(1000, 3000),
                    painter: MapConnectionPainter(nodes: nodes),
                  ),
                  ...nodes.map(
                    (node) => _MapNodeWidget(
                      node: node,
                      isAvailable: _isNodeAvailable(node, nodes, currentNodeId),
                      isCurrent: node.id == currentNodeId,
                      onTap: () => _onNodeTap(context, ref, node),
                      onShowTooltip: _showNodeTooltip,
                      onHideTooltip: _hideTooltip,
                    ),
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
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LÉGENDE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Divider(color: Colors.white24),
                  _LegendItem(
                    icon: Icons.flash_on,
                    color: Colors.white70,
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
                    color: const Color(0xFF2A2A3D).withAlpha(240),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(100),
                        blurRadius: 10,
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
                          color: Colors.blueAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(color: Colors.white24),
                      Text(
                        _tooltipDescription ?? '',
                        style: const TextStyle(
                          color: Colors.white,
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
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => destination));
  }
}

class _MapNodeWidget extends StatefulWidget {
  final MapNode node;
  final bool isAvailable;
  final bool isCurrent;
  final VoidCallback onTap;
  final Function(String, String) onShowTooltip;
  final VoidCallback onHideTooltip;

  const _MapNodeWidget({
    required this.node,
    required this.isAvailable,
    required this.isCurrent,
    required this.onTap,
    required this.onShowTooltip,
    required this.onHideTooltip,
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
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
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

  MapConnectionPainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(30)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var node in nodes) {
      for (var targetId in node.connections) {
        try {
          final targetNode = nodes.firstWhere((n) => n.id == targetId);
          canvas.drawLine(
            Offset(node.position.x, node.position.y),
            Offset(targetNode.position.x, targetNode.position.y),
            paint,
          );
        } catch (e) {
          // Ignorer si la cible n'existe pas (cas de changement de map)
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapConnectionPainter oldDelegate) =>
      oldDelegate.nodes != nodes;
}

