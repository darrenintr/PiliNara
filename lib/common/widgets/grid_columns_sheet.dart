/*
 * This file is part of PiliPlus
 *
 * PiliPlus is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * PiliPlus is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with PiliPlus.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:PiliPlus/utils/grid_columns.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom sheet that lets the user pick how many video tiles fit per row.
///
/// The value is persisted immediately and the grids reflow live.
Future<void> showGridColumnsSheet(BuildContext context) {
  final colorScheme = ColorScheme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.grid_view_rounded, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text('每行视频数'.tr, style: textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '自动会随屏幕宽度调整列数'.tr,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _ColumnPicker(label: '主页推荐'.tr, value: GridColumns.home),
              const SizedBox(height: 20),
              _ColumnPicker(label: '其他列表'.tr, value: GridColumns.def),
            ],
          ),
        ),
      );
    },
  );
}

class _ColumnPicker extends StatelessWidget {
  const _ColumnPicker({required this.label, required this.value});

  final String label;
  final RxInt value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final columns in GridColumns.pickerValues)
                ChoiceChip(
                  label: Text(GridColumns.label(columns)),
                  selected: value.value == columns,
                  onSelected: (_) {
                    if (value == GridColumns.home) {
                      GridColumns.setHome(columns);
                    } else {
                      GridColumns.setDefault(columns);
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
