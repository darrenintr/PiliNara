import 'package:PiliPlus/pages/setting/ai_setting/controller.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AiSettingPage extends StatelessWidget {
  const AiSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AiSettingController());
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('AI 视频总结设置'.tr)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 总开关
          Obx(() => SwitchListTile(
                title: Text('启用 AI 视频助手'.tr),
                subtitle: Text('关闭后视频详情页不再显示 AI 按钮'.tr),
                value: controller.enableAiChat.value,
                onChanged: (value) {
                  controller.enableAiChat.value = value;
                  Pref.enableAiChat = value;
                },
              )),
          const SizedBox(height: 8),

          // API 配置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('API 配置'.tr, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.apiUrlCtl,
                    decoration: InputDecoration(
                      labelText: '接口地址'.tr,
                      hintText: 'https://api.example.com/v1',
                      helperText:
                          '填到版本路径为止，将自动补全 /models、/chat/completions；'.tr +
                          '如 OpenAI …/v1、Gemini …/v1beta、火山方舟 …/api/v3'.tr,
                      helperMaxLines: 3,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    onChanged: controller.saveApiUrl,
                  ),
                  const SizedBox(height: 12),
                  _ApiKeyField(controller: controller),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 模型选择
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('模型选择'.tr, style: theme.textTheme.titleMedium),
                      const Spacer(),
                      Obx(
                        () => controller.isLoadingModels.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton.filled(
                                icon: const Icon(Icons.refresh),
                                tooltip: '拉取模型列表'.tr,
                                onPressed: controller.fetchModels,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    if (controller.modelList.isNotEmpty) {
                      return DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: controller.modelList
                                .contains(controller.model.value)
                            ? controller.model.value
                            : null,
                        items: controller.modelList
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixIcon: Icon(Icons.smart_toy),
                        ),
                        onChanged: (value) {
                          if (value != null) controller.saveModel(value);
                        },
                      );
                    }
                    return TextField(
                      controller: controller.modelCtl,
                      decoration: InputDecoration(
                        labelText: '模型名称'.tr,
                        hintText: 'gpt-5.4',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.smart_toy),
                      ),
                      onChanged: controller.saveModel,
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 模板管理
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('提示词模板'.tr, style: theme.textTheme.titleMedium),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.restore, size: 18),
                        label: Text('恢复默认'.tr),
                        onPressed: () => _confirmRestoreDefaults(
                          context,
                          controller,
                        ),
                      ),
                      const SizedBox(width: 4),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.add, size: 18),
                        label: Text('添加'.tr),
                        onPressed: () =>
                            _showTemplateDialog(context, controller),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    if (controller.templates.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            '暂无模板，点击上方添加'.tr,
                            style: TextStyle(color: colorScheme.outline),
                          ),
                        ),
                      );
                    }
                    return ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.templates.length,
                      onReorder: controller.reorderTemplate,
                      itemBuilder: (context, index) {
                        final t = controller.templates[index];
                        return Card(
                          key: ValueKey('${t.name}_$index'),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.name,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        t.prompt,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  iconSize: 20,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _showTemplateDialog(
                                    context,
                                    controller,
                                    index: index,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: colorScheme.error,
                                  ),
                                  iconSize: 20,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      controller.deleteTemplate(index),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.drag_handle,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Info card
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '使用说明'.tr,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 支持 OpenAI 兼容的 API 接口\n'.tr +
                    '• 在视频详情页点击 AI 按钮使用\n'.tr +
                    '• 点击「分析」自动载入视频上下文，也可手动载入后自由提问\n'.tr +
                    '• 无字幕时仍可使用通用问答\n'.tr +
                    '• 支持 Markdown 和 LaTeX，时间戳可点击跳转\n'.tr +
                    '• 内置模板名称（概貌总结、详细分析）的内容会被版本更新覆盖\n'.tr +
                    '• 自定义模板请使用不同名称，避免与内置模板重名'.tr,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _confirmRestoreDefaults(
    BuildContext context,
    AiSettingController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('恢复默认模板'.tr),
        content: Text('将清除所有自定义模板，恢复为内置默认模板。确定继续？'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消'.tr,
              style: TextStyle(color: ColorScheme.of(context).outline),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.restoreDefaults();
              Navigator.pop(context);
            },
            child: Text('确定'.tr),
          ),
        ],
      ),
    );
  }

  void _showTemplateDialog(
    BuildContext context,
    AiSettingController controller, {
    int? index,
  }) {
    final isEdit = index != null;
    final existing = isEdit ? controller.templates[index] : null;
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final promptCtl = TextEditingController(text: existing?.prompt ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? '编辑模板'.tr : '添加模板'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: InputDecoration(
                labelText: '模板名称'.tr,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: promptCtl,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: '提示词内容'.tr,
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消'.tr,
              style: TextStyle(color: ColorScheme.of(context).outline),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtl.text.trim();
              final prompt = promptCtl.text.trim();
              if (name.isEmpty || prompt.isEmpty) return;
              if (isEdit) {
                controller.updateTemplate(index, name, prompt);
              } else {
                controller.addTemplate(name, prompt);
              }
              Navigator.pop(context);
            },
            child: Text('确定'.tr),
          ),
        ],
      ),
    );
  }
}

class _ApiKeyField extends StatefulWidget {
  const _ApiKeyField({required this.controller});
  final AiSettingController controller;

  @override
  State<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<_ApiKeyField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller.apiKeyCtl,
      decoration: InputDecoration(
        labelText: 'API Key',
        hintText: 'sk-...',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.key),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: widget.controller.saveApiKey,
    );
  }
}
