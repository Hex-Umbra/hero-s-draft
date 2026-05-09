import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/run_controller.dart';
import '../../models/map_node.dart';
import 'game_screen.dart';
import 'shop_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final TransformationController _transformationController = TransformationController();
  int? _lastActCentered;

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.translationValues(-200.0, -1500.0, 0.0)
      * Matrix4.diagonal3Values(0.8, 0.8, 1.0);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
    final nodes = runState.mapNodes;
    final currentNodeId = runState.currentNodeId;
    final screenSize = MediaQuery.of(context).size;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force le re-centrage si on change d'acte ou si on n'a jamais centré
      if (_lastActCentered != runState.act || (currentNodeId == null && _lastActCentered == null)) {
          MapNode? targetNode;
          if (currentNodeId != null) {
            targetNode = nodes.firstWhere((n) => n.id == currentNodeId, orElse: () => nodes.first);
          } else {
            // Pour un nouvel acte, on cible le milieu du premier étage
            targetNode = nodes.firstWhere((n) => n.id.startsWith('node_0_'), orElse: () => nodes.first);
          }
          
          double scale = 0.8;
          double actualX = targetNode.position.x;
          double actualY = targetNode.position.y + 300; // prise en compte du padding top
          
          double dx = (screenSize.width / 2) - (actualX * scale);
          double dy = (screenSize.height / 2) - (actualY * scale);
          
          if (mounted) {
            setState(() {
              _transformationController.value = Matrix4.translationValues(dx, dy, 0.0)
                * Matrix4.diagonal3Values(scale, scale, 1.0);
              _lastActCentered = runState.act;
            });
          }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: Text('Acte ${runState.act} - Carte du Monde', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black45,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                const SizedBox(width: 4),
                Text(
                  '${runState.gold}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ],
            ),
          )
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(1000),
        minScale: 0.1,
        maxScale: 2.0,
        scaleEnabled: false, // Bloque le zoom (dézoom/zoom désactivé)
        constrained: false, // Permet au Container d'être plus grand que l'écran
        child: Container(
          width: 1200,
          height: 2800,
          padding: const EdgeInsets.only(top: 300, bottom: 200),
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(1200, 2800),
                painter: MapConnectionPainter(nodes: nodes),
              ),
              ...nodes.map((node) => _MapNodeWidget(
                    node: node,
                    isAvailable: _isNodeAvailable(node, nodes, currentNodeId),
                    isCurrent: node.id == currentNodeId,
                    onTap: () => _onNodeTap(context, ref, node),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  bool _isNodeAvailable(MapNode node, List<MapNode> allNodes, String? currentNodeId) {
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
        destination = const GameScreen();
        break;
      case MapNodeType.event:
        destination = const GameScreen();
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => destination),
    );
  }
}

class _MapNodeWidget extends StatelessWidget {
  final MapNode node;
  final bool isAvailable;
  final bool isCurrent;
  final VoidCallback onTap;

  const _MapNodeWidget({
    required this.node,
    required this.isAvailable,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (node.type) {
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

    return Positioned(
      left: node.position.x - 35,
      top: node.position.y - 35,
      child: GestureDetector(
        onTap: isAvailable ? onTap : null,
        child: Column(
          children: [
            Opacity(
              opacity: node.isCompleted ? 0.4 : (isAvailable ? 1.0 : 0.2),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isCurrent ? const Color(0xFF2A2A40) : const Color(0xFF1A1A2E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? Colors.yellow : (isAvailable ? color : color.withValues(alpha: 0.5)),
                    width: isCurrent ? 4 : 2,
                  ),
                  boxShadow: isCurrent ? [
                    BoxShadow(color: Colors.yellow.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)
                  ] : [],
                ),
                child: Icon(icon, color: isAvailable || isCurrent ? color : color.withValues(alpha: 0.5), size: 35),
              ),
            ),
            if (node.isCompleted)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
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
      ..color = Colors.white.withValues(alpha: 0.12)
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
  bool shouldRepaint(covariant MapConnectionPainter oldDelegate) => oldDelegate.nodes != nodes;
}
