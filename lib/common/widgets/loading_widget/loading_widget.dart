import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/loading_widget/m3e_loading_indicator.dart';
import 'package:PiliPlus/common/widgets/progress_bar/wavy_progress_indicator.dart';
import 'package:flutter/material.dart';

const Widget m3eLoading = Center(child: M3ELoadingIndicator());

const Widget linearLoading = SliverToBoxAdapter(
  child: Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: WavyProgressIndicator(),
  ),
);

const Widget scrollableError = CustomScrollView(slivers: [HttpError()]);

Widget scrollErrorWidget({
  String? errMsg,
  VoidCallback? onReload,
  ScrollController? controller,
}) => CustomScrollView(
  controller: controller,
  slivers: [
    HttpError(
      errMsg: errMsg,
      onReload: onReload,
    ),
  ],
);
