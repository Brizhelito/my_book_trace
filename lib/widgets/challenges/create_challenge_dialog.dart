import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';  
import 'package:MyBookTrace/models/challenge.dart';
import 'package:MyBookTrace/providers/challenge_provider.dart';

class CreateChallengeDialog extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Challenge? challengeToEdit;

  const CreateChallengeDialog({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    this.challengeToEdit,
  });

  @override
  State<CreateChallengeDialog> createState() => _CreateChallengeDialogState();
}

class _CreateChallengeDialogState extends State<CreateChallengeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;
  late ChallengeType _selectedType;

  bool _isEditing = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.challengeToEdit != null;

    // Inicializar con valores del desafío a editar o con valores por defecto
    if (_isEditing) {
      final challenge = widget.challengeToEdit!;
      _titleController.text = challenge.title;
      _descriptionController.text = challenge.description;
      _targetController.text = challenge.target.toString();
      _startDate = challenge.startDate;
      _endDate = challenge.endDate;
      _selectedType = challenge.type;
    } else {
      _startDate = widget.initialStartDate;
      _endDate = widget.initialEndDate;
      _selectedType = ChallengeType.pages; // Tipo por defecto
      _targetController.text = '30'; // Meta por defecto
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  // Seleccionar fecha de inicio
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;

        // Si la fecha de fin es anterior a la nueva fecha de inicio, actualizarla
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  // Seleccionar fecha de fin
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // Guardar el desafío
  Future<void> _saveChallenge() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final provider = Provider.of<ChallengeProvider>(context, listen: false);

      // Validar las fechas
      if (!provider.validateChallengeDates(_startDate, _endDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Error al validar fechas')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Crear o actualizar el desafío
      final target = int.parse(_targetController.text);
      bool success;

      if (_isEditing) {
        // Actualizar desafío existente
        final updatedChallenge = widget.challengeToEdit!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
          type: _selectedType,
          target: target,
        );

        success = await provider.updateChallenge(updatedChallenge);
      } else {
        // Crear nuevo desafío
        final newChallenge = Challenge(
          id: '',
          title: _titleController.text,
          description: _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
          type: _selectedType,
          target: target,
        );

        final result = await provider.createChallenge(newChallenge);
        success = result != null;
      }

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Error al guardar el desafío'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      title: Text(_isEditing ? 'Editar Desafío' : 'Crear Nuevo Desafío'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ej: Leer 30 páginas diarias',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Describe tu desafío',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 16),

              // Tipo de desafío
              DropdownButtonFormField<ChallengeType>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de desafío',
                  border: OutlineInputBorder(),
                ),
                value: _selectedType,
                items: ChallengeType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Meta
              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(
                  labelText: 'Meta',
                  hintText: 'Ingresa tu meta',
                  suffixText: _selectedType.unit,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una meta';
                  }
                  try {
                    int target = int.parse(value);
                    if (target <= 0) {
                      return 'La meta debe ser mayor que cero';
                    }
                  } catch (e) {
                    return 'Por favor ingresa un número válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Fechas
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectStartDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de inicio',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(dateFormat.format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEndDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de fin',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(dateFormat.format(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _saveChallenge,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
}
