import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:MyBookTrace/models/challenge.dart';
import 'package:MyBookTrace/providers/challenge_provider.dart';
import 'package:MyBookTrace/constants/app_constants.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const ChallengeCard({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Determinar el color de estado
    Color statusColor;
    String statusText;

    if (challenge.isCompleted) {
      statusColor = Colors.green;
      statusText = 'Completado';
    } else if (challenge.isExpired) {
      statusColor = Colors.red;
      statusText = 'Expirado';
    } else if (challenge.isInProgress) {
      statusColor = Colors.blue;
      statusText = 'En progreso';
    } else {
      statusColor = Colors.orange;
      statusText = 'Pendiente';
    }

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de estado
          Container(
            color: statusColor,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: UiConstants.defaultPadding,
            ),
            child: Text(
              statusText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(UiConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y tipo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Chip(
                      label: Text(
                        challenge.type.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Descripción
                if (challenge.description.isNotEmpty) ...[
                  Text(
                    challenge.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // Fechas
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dateFormat.format(challenge.startDate)} - ${dateFormat.format(challenge.endDate)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (!challenge.isCompleted && !challenge.isExpired) ...[
                      const Spacer(),
                      Text(
                        '${challenge.daysRemaining} días restantes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: challenge.daysRemaining < 7
                              ? Colors.red
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Barra de progreso
                LinearProgressIndicator(
                  value: challenge.progressPercentage / 100,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    challenge.isCompleted
                        ? Colors.green
                        : theme.colorScheme.primary,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),

                const SizedBox(height: 4),

                // Detalles de progreso
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${challenge.currentProgress} de ${challenge.target} ${challenge.type.unit}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${challenge.progressPercentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Actualizar progreso
                    if (!challenge.isCompleted && challenge.isActive) ...[
                      OutlinedButton.icon(
                        onPressed: () => _showUpdateProgressDialog(context),
                        icon: const Icon(Icons.update, size: 16),
                        label: const Text('Actualizar'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Marcar como completado/ver detalles
                    if (!challenge.isCompleted && challenge.isActive)
                      ElevatedButton.icon(
                        onPressed: () => _confirmCompleteChallenge(context),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Completar'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: () => _showChallengeDetails(context),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Detalles'),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo para actualizar progreso
  void _showUpdateProgressDialog(BuildContext context) {
    final provider = Provider.of<ChallengeProvider>(context, listen: false);
    int newProgress = challenge.currentProgress;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Progreso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Meta: ${challenge.target} ${challenge.type.unit}'),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Progreso actual',
                hintText: 'Ingresa tu avance en ${challenge.type.unit}',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              initialValue: challenge.currentProgress.toString(),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  newProgress =
                      int.tryParse(value) ?? challenge.currentProgress;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateProgress(challenge.id!, newProgress);
              Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo de confirmación para marcar como completado
  void _confirmCompleteChallenge(BuildContext context) {
    final provider = Provider.of<ChallengeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Desafío'),
        content: const Text(
          '¿Estás seguro de que quieres marcar este desafío como completado?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.completeChallenge(challenge.id!);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Desafío completado con éxito!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }

  // Mostrar detalles completos del desafío
  void _showChallengeDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(challenge.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descripción: ${challenge.description}'),
            const SizedBox(height: 8),
            Text('Tipo: ${challenge.type.displayName}'),
            Text('Meta: ${challenge.target} ${challenge.type.unit}'),
            Text(
              'Progreso: ${challenge.currentProgress} ${challenge.type.unit} (${challenge.progressPercentage.toStringAsFixed(1)}%)',
            ),
            const SizedBox(height: 8),
            Text(
              'Creado: ${DateFormat('dd/MM/yyyy').format(challenge.createdAt)}',
            ),
            Text(
              'Última actualización: ${DateFormat('dd/MM/yyyy').format(challenge.updatedAt)}',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
