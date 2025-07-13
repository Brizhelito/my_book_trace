import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:MyBookTrace/providers/challenge_provider.dart';
import 'package:MyBookTrace/models/challenge.dart';

/// Widget que muestra estadísticas de desafíos del usuario
class ChallengeStatsCard extends StatefulWidget {
  const ChallengeStatsCard({super.key});

  @override
  State<ChallengeStatsCard> createState() => _ChallengeStatsCardState();
}

class _ChallengeStatsCardState extends State<ChallengeStatsCard> {
  bool _isLoading = true;
  List<Challenge> _challenges = [];
  
  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }
  
  /// Carga los desafíos del usuario
  Future<void> _loadChallenges() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
      // Usar el getter allChallenges en lugar de un método inexistente
      final challenges = challengeProvider.allChallenges;
      
      if (mounted) {
        setState(() {
          _challenges = challenges;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar desafíos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Desafíos y Logros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Contenido principal
            _buildContent(),
          ],
        ),
      ),
    );
  }
  
  /// Construye el contenido principal del widget
  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(height: 100, child: Center());
    }
    
    if (_challenges.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      children: [
        // Resumen de desafíos
        _buildChallengeSummary(),
        
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        
        // Desafíos activos
        _buildActiveChallenges(),
      ],
    );
  }
  
  /// Construye el estado vacío cuando no hay desafíos
  Widget _buildEmptyState() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Aún no has creado ningún desafío',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Navegar a la pantalla de desafíos
                Navigator.pushNamed(context, '/challenges');
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Desafío'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construye el resumen de desafíos
  Widget _buildChallengeSummary() {
    // Calcular estadísticas de desafíos
    final totalChallenges = _challenges.length;
    final completedChallenges = _challenges.where((c) => c.isCompleted).length;
    final activeChallenges = _challenges.where((c) => !c.isCompleted).length;
    
    // Calcular porcentaje de completitud
    final completionRate = totalChallenges > 0
        ? (completedChallenges / totalChallenges * 100).toStringAsFixed(0)
        : '0';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          Icons.emoji_events,
          '$completedChallenges',
          'Completados',
          Colors.amber,
        ),
        _buildStatItem(
          Icons.pending_actions,
          '$activeChallenges',
          'Activos',
          Colors.blue,
        ),
        _buildStatItem(
          Icons.percent,
          '$completionRate%',
          'Completitud',
          Colors.green,
        ),
      ],
    );
  }
  
  /// Construye un elemento de estadística
  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  /// Construye la lista de desafíos activos
  Widget _buildActiveChallenges() {
    final activeChallenges = _challenges.where((c) => !c.isCompleted).toList();
    
    if (activeChallenges.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'No tienes desafíos activos actualmente',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desafíos Activos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...activeChallenges.take(3).map(_buildChallengeItem),
        if (activeChallenges.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/challenges');
              },
              child: Text('Ver todos (${activeChallenges.length})'),
            ),
          ),
      ],
    );
  }
  
  /// Construye un elemento de desafío
  Widget _buildChallengeItem(Challenge challenge) {
    // Calcular progreso
    final progress = challenge.currentProgress / challenge.target;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getChallengeIcon(challenge.type),
                size: 18,
                color: _getChallengeColor(challenge.type),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  challenge.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_getChallengeColor(challenge.type)),
          ),
          const SizedBox(height: 2),
          Text(
            '${challenge.currentProgress}/${challenge.target} ${_getChallengeUnit(challenge.type)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Obtiene el icono para un tipo de desafío
  IconData _getChallengeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.books:
        return Icons.book;
      case ChallengeType.pages:
        return Icons.menu_book;
      case ChallengeType.time:
        return Icons.timer;
      case ChallengeType.streak:
        return Icons.calendar_today;
      case ChallengeType.custom:
        return Icons.emoji_events;
    }
  }
  
  /// Obtiene el color para un tipo de desafío
  Color _getChallengeColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.books:
        return Colors.indigo;
      case ChallengeType.pages:
        return Colors.green;
      case ChallengeType.time:
        return Colors.orange;
      case ChallengeType.streak:
        return Colors.purple;
      case ChallengeType.custom:
        return Colors.teal;
    }
  }
  
  /// Obtiene la unidad para un tipo de desafío
  String _getChallengeUnit(ChallengeType type) {
    switch (type) {
      case ChallengeType.books:
        return 'libros';
      case ChallengeType.pages:
        return 'páginas';
      case ChallengeType.time:
        return 'minutos';
      case ChallengeType.streak:
        return 'días';
      case ChallengeType.custom:
        return 'unidades';
    }
  }
}
