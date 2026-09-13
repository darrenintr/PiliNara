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

import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';

/// Reactive, persisted column counts for the video grids.
///
/// [auto] keeps the responsive behavior (the column count is derived from the
/// configured card width); any positive value pins the number of tiles per
/// row. Widgets wrap their grid in an `Obx` so flipping a value reflows it
/// live instead of requiring a restart.
abstract final class GridColumns {
  /// 0 means "auto": let the responsive delegate pick the column count.
  static const int auto = 0;

  static const List<int> pickerValues = [auto, 1, 2, 3, 4, 5];

  static final RxInt home = Pref.homeGridColumns.obs;
  static final RxInt def = Pref.defaultGridColumns.obs;

  static Future<void> setHome(int columns) async {
    if (home.value == columns) return;
    home.value = columns;
    await GStorage.setting.put(SettingBoxKey.homeGridColumns, columns);
  }

  static Future<void> setDefault(int columns) async {
    if (def.value == columns) return;
    def.value = columns;
    await GStorage.setting.put(SettingBoxKey.defaultGridColumns, columns);
  }

  /// `Obx`-friendly label for a column count.
  static String label(int columns) => columns == auto ? '自动'.tr : '$columns';
}
