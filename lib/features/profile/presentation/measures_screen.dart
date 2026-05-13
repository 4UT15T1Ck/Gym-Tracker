import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/utils/date_formatters.dart';
import 'package:gym_tracker/features/profile/bloc/measures_cubit.dart';

class MeasuresScreen extends StatefulWidget {
  const MeasuresScreen({super.key});

  @override
  State<MeasuresScreen> createState() => _MeasuresScreenState();
}

class _MeasuresScreenState extends State<MeasuresScreen> {
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeasuresCubit, MeasuresState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Measures')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _bodyFatController,
                decoration: const InputDecoration(labelText: 'Body fat %'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  context.read<MeasuresCubit>().add(
                        weight: double.tryParse(_weightController.text),
                        bodyFat: double.tryParse(_bodyFatController.text),
                      );
                  _weightController.clear();
                  _bodyFatController.clear();
                },
                child: const Text('Add Entry'),
              ),
              const SizedBox(height: 24),
              Text('Weight History', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: state.entries.reversed.take(30).map((entry) {
                    final weight = entry.weight ?? 0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          height: weight <= 0 ? 4 : weight.clamp(20, 160).toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (state.entries.isEmpty) const Text('No body metrics logged yet.'),
              ...state.entries.map(
                (entry) => ListTile(
                  title: Text(DateFormatters.shortDate(entry.date)),
                  subtitle: Text('Weight: ${entry.weight?.toStringAsFixed(1) ?? '-'} · Body fat: ${entry.bodyFatPercent?.toStringAsFixed(1) ?? '-'}%'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => context.read<MeasuresCubit>().delete(entry.id),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
