import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/serial_validator.dart';

class FilterWidget extends StatelessWidget {
  final String modelFilter;
  final String serialRangeStart;
  final String serialRangeEnd;
  final Function(String) onModelFilterChanged;
  final Function(String, String) onSerialRangeChanged;

  const FilterWidget({
    super.key,
    required this.modelFilter,
    required this.serialRangeStart,
    required this.serialRangeEnd,
    required this.onModelFilterChanged,
    required this.onSerialRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '모델: ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Expanded(
          flex: 2,
          child: DropdownButton<String>(
            value: modelFilter,
            onChanged: (String? newValue) {
              if (newValue != null) {
                onModelFilterChanged(newValue);
              }
            },
            items: AppConstants.modelFilters
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '시리얼: ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Expanded(
          flex: 2,
          child: _SerialRangeField(
            label: '시작',
            value: serialRangeStart,
            onChanged: (value) => onSerialRangeChanged(value, serialRangeEnd),
          ),
        ),
        const SizedBox(width: 4),
        const Text('~', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Expanded(
          flex: 2,
          child: _SerialRangeField(
            label: '끝',
            value: serialRangeEnd,
            onChanged: (value) => onSerialRangeChanged(serialRangeStart, value),
          ),
        ),
      ],
    );
  }
}

class _SerialRangeField extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;

  const _SerialRangeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        labelStyle: const TextStyle(fontSize: 10),
      ),
      style: const TextStyle(fontSize: 12),
      keyboardType: TextInputType.number,
      maxLength: AppConstants.maxSerialLength,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
      onChanged: (value) {
        final numericValue = SerialValidator.sanitizeNumericInput(value);
        if (numericValue == value) {
          onChanged(numericValue);
        }
      },
    );
  }
}