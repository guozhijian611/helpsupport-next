import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/material_controller.dart';
import '../data/material_models.dart';

class MaterialPrivateUploadScreen extends ConsumerStatefulWidget {
  const MaterialPrivateUploadScreen({super.key});

  @override
  ConsumerState<MaterialPrivateUploadScreen> createState() =>
      _MaterialPrivateUploadScreenState();
}

class _MaterialPrivateUploadScreenState
    extends ConsumerState<MaterialPrivateUploadScreen> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();
  final _imagePicker = ImagePicker();

  String _mediaType = 'txt';
  int _selectedCategoryId = 0;
  List<PlatformFile> _selectedFiles = const [];
  bool _submitting = false;

  _PrivateMediaOption get _currentOption {
    return _privateMediaOptions.firstWhere(
      (item) => item.value == _mediaType,
      orElse: () => _privateMediaOptions.first,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PrivateUploadPalette.of(context);
    final option = _currentOption;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final categoriesQuery = MaterialCategoriesQuery(
      type: 'private',
      locale: locale,
    );
    final categories = ref.watch(materialCategoriesProvider(categoriesQuery));

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: Text(_t(context, '上传私人素材', 'Upload Private Material')),
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            _PrivateNotice(palette: palette),
            const SizedBox(height: 16),
            _PrivateUploadPanel(
              palette: palette,
              titleController: _titleController,
              summaryController: _summaryController,
              contentController: _contentController,
              linkController: _linkController,
              selectedFiles: _selectedFiles,
              mediaType: _mediaType,
              selectedCategoryId: _selectedCategoryId,
              categories: categories.asData?.value ?? const [],
              option: option,
              onCategoryChanged: (value) =>
                  setState(() => _selectedCategoryId = value ?? 0),
              onCreateCategory: _createCategory,
              onMediaChanged: (value) {
                if (value == null || value == _mediaType) {
                  return;
                }
                setState(() {
                  _mediaType = value;
                  _selectedFiles = const [];
                });
              },
              onPickFile: _pickFile,
              onClearFile: () => setState(() => _selectedFiles = const []),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                _submitting
                    ? _t(context, '正在保存', 'Saving')
                    : _t(context, '保存到私人素材', 'Save to Private Materials'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final option = _currentOption;
    if (option.value == 'image') {
      await _pickImage();
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      allowedExtensions: option.extensions,
      type: FileType.custom,
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    setState(() => _selectedFiles = [result.files.single]);
  }

  Future<void> _pickImage() async {
    final permission = await ref
        .read(permissionServiceProvider)
        .requestMediaLibrary();
    final granted =
        permission == PermissionStatus.granted ||
        permission == PermissionStatus.limited;
    if (!granted) {
      if (mounted) {
        context.showCenteredNotice(
          _t(
            context,
            '需要开启相册权限后才能选择图片',
            'Photo permission is required to choose an image',
          ),
        );
      }
      return;
    }

    final images = await _imagePicker.pickMultiImage(
      imageQuality: 90,
      maxWidth: 2000,
    );
    if (images.isEmpty) {
      return;
    }

    final files = <PlatformFile>[];
    for (final image in images) {
      final fileName = image.name.trim().isNotEmpty
          ? image.name
          : Uri.file(image.path).pathSegments.last;
      files.add(
        PlatformFile(
          name: fileName,
          path: image.path,
          size: await image.length(),
        ),
      );
    }
    setState(() => _selectedFiles = files);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      context.showCenteredNotice(_t(context, '请填写标题', 'Title is required'));
      return;
    }

    final option = _currentOption;
    final payload = <String, dynamic>{
      'category_id': _selectedCategoryId,
      'media_type': option.value,
      'title': title,
      'summary': _summaryController.text.trim(),
      'tags': const <String>[],
    };

    if (option.requiresFile) {
      final files = _selectedFiles;
      if (files.isEmpty) {
        context.showCenteredNotice(
          option.value == 'image'
              ? _t(context, '请选择要上传的图片', 'Choose an image first')
              : _t(context, '请选择要上传的文件', 'Choose a file first'),
        );
        return;
      }
      setState(() => _submitting = true);
      try {
        await _uploadAndSaveFiles(payload, files, option);
      } finally {
        if (mounted) {
          setState(() => _submitting = false);
        }
      }
      return;
    }

    if (option.value == 'link') {
      final link = _linkController.text.trim();
      final uri = Uri.tryParse(link);
      if (uri == null || !uri.hasScheme) {
        context.showCenteredNotice(
          _t(context, '请填写有效的外链地址', 'Enter a valid link'),
        );
        return;
      }
      payload['content_url'] = link;
    } else {
      final content = _contentController.text.trim();
      if (content.isEmpty) {
        context.showCenteredNotice(
          _t(context, '请填写文字内容', 'Enter the text content'),
        );
        return;
      }
      payload['content_text'] = content;
    }

    setState(() => _submitting = true);
    try {
      await _save(payload);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _uploadAndSaveFiles(
    Map<String, dynamic> basePayload,
    List<PlatformFile> files,
    _PrivateMediaOption option,
  ) async {
    final repository = ref.read(materialRepositoryProvider);
    try {
      for (final file in files) {
        final upload = await repository.uploadPrivateMaterialFile(file: file);
        final payload = Map<String, dynamic>.of(basePayload);
        payload['content_url'] = upload.url;
        if (option.value == 'image') {
          payload['cover_url'] = upload.url;
        }
        if ((payload['summary'] as String).isEmpty &&
            upload.originName.trim().isNotEmpty) {
          payload['summary'] = upload.originName.trim();
        }
        await repository.savePrivateMaterial(payload);
      }
      _invalidateMaterialLists();
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(
        files.length > 1
            ? _t(
                context,
                '已保存 ${files.length} 个素材',
                'Saved ${files.length} materials',
              )
            : _t(context, '已保存', 'Saved'),
      );
      context.pop();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }

  Future<void> _save(Map<String, dynamic> payload) async {
    try {
      await ref.read(materialRepositoryProvider).savePrivateMaterial(payload);
      _invalidateMaterialLists();
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(_t(context, '已保存', 'Saved'));
      context.pop();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }

  void _invalidateMaterialLists() {
    final locale = Localizations.localeOf(context).toLanguageTag();
    for (final categoryId in {0, _selectedCategoryId}) {
      ref.invalidate(
        materialListProvider(
          MaterialListQuery(
            materialType: 'private',
            categoryId: categoryId,
            keyword: '',
            locale: locale,
          ),
        ),
      );
    }
  }

  Future<void> _createCategory() async {
    final controller = TextEditingController();
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          String? errorText;
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text(_t(context, '新建分类', 'New category')),
              content: TextField(
                controller: controller,
                autofocus: true,
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: _t(context, '分类名称', 'Category name'),
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(_t(context, '取消', 'Cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) {
                      setState(() {
                        errorText = _t(
                          context,
                          '请填写分类名称',
                          'Enter a category name',
                        );
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(value);
                  },
                  child: Text(_t(context, '保存', 'Save')),
                ),
              ],
            ),
          );
        },
      );
      if (name == null || name.trim().isEmpty) {
        return;
      }
      final category = await ref
          .read(materialRepositoryProvider)
          .savePrivateCategory(name.trim());
      final locale = Localizations.localeOf(context).toLanguageTag();
      ref.invalidate(
        materialCategoriesProvider(
          MaterialCategoriesQuery(type: 'private', locale: locale),
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() => _selectedCategoryId = category.id);
      context.showCenteredNotice(_t(context, '分类已创建', 'Category created'));
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    } finally {
      controller.dispose();
    }
  }
}

class _PrivateUploadPanel extends StatelessWidget {
  const _PrivateUploadPanel({
    required this.palette,
    required this.titleController,
    required this.summaryController,
    required this.contentController,
    required this.linkController,
    required this.selectedFiles,
    required this.mediaType,
    required this.selectedCategoryId,
    required this.categories,
    required this.option,
    required this.onCategoryChanged,
    required this.onCreateCategory,
    required this.onMediaChanged,
    required this.onPickFile,
    required this.onClearFile,
  });

  final _PrivateUploadPalette palette;
  final TextEditingController titleController;
  final TextEditingController summaryController;
  final TextEditingController contentController;
  final TextEditingController linkController;
  final List<PlatformFile> selectedFiles;
  final String mediaType;
  final int selectedCategoryId;
  final List<MaterialCategory> categories;
  final _PrivateMediaOption option;
  final ValueChanged<int?> onCategoryChanged;
  final VoidCallback onCreateCategory;
  final ValueChanged<String?> onMediaChanged;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: _inputDecoration(
                    context,
                    _t(context, '素材分类', 'Category'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(_t(context, '未分类', 'Uncategorized')),
                    ),
                    for (final category in categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    if (selectedCategoryId > 0 &&
                        categories.every(
                          (category) => category.id != selectedCategoryId,
                        ))
                      DropdownMenuItem(
                        value: selectedCategoryId,
                        child: Text('#$selectedCategoryId'),
                      ),
                  ],
                  onChanged: onCategoryChanged,
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: _t(context, '新建分类', 'New category'),
                onPressed: onCreateCategory,
                icon: const Icon(Icons.create_new_folder_outlined),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: mediaType,
            decoration: _inputDecoration(context, _t(context, '素材类型', 'Type')),
            items: [
              for (final item in _privateMediaOptions)
                DropdownMenuItem(
                  value: item.value,
                  child: Text(item.label(context)),
                ),
            ],
            onChanged: onMediaChanged,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: titleController,
            decoration: _inputDecoration(context, _t(context, '标题', 'Title')),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: summaryController,
            minLines: 2,
            maxLines: 3,
            decoration: _inputDecoration(
              context,
              _t(context, '摘要（可选）', 'Summary (optional)'),
            ),
          ),
          const SizedBox(height: 14),
          if (option.requiresFile)
            _FilePickerTile(
              palette: palette,
              option: option,
              files: selectedFiles,
              onPickFile: onPickFile,
              onClearFile: onClearFile,
            )
          else if (option.value == 'link')
            TextField(
              controller: linkController,
              keyboardType: TextInputType.url,
              decoration: _inputDecoration(
                context,
                _t(context, '游戏外链', 'Game link'),
              ),
            )
          else
            TextField(
              controller: contentController,
              minLines: 8,
              maxLines: 12,
              decoration: _inputDecoration(
                context,
                _t(context, '文字内容', 'Text content'),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrivateNotice extends StatelessWidget {
  const _PrivateNotice({required this.palette});

  final _PrivateUploadPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: palette.noticeBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: palette.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _t(
                context,
                '私人素材上传到服务器后仅当前账号可见。',
                'Private materials are uploaded to the server and visible only to your account.',
              ),
              style: TextStyle(
                color: palette.bodyText,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilePickerTile extends StatelessWidget {
  const _FilePickerTile({
    required this.palette,
    required this.option,
    required this.files,
    required this.onPickFile,
    required this.onClearFile,
  });

  final _PrivateUploadPalette palette;
  final _PrivateMediaOption option;
  final List<PlatformFile> files;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  @override
  Widget build(BuildContext context) {
    final hasFiles = files.isNotEmpty;
    final title = _selectedFileTitle(context);
    final subtitle = _selectedFileSubtitle(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onPickFile,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.fieldBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.outline),
        ),
        child: Row(
          children: [
            Icon(option.icon, color: palette.accent, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(color: palette.secondaryText),
                  ),
                ],
              ),
            ),
            if (hasFiles)
              IconButton(
                tooltip: _t(context, '移除文件', 'Remove file'),
                onPressed: onClearFile,
                icon: const Icon(Icons.close_rounded),
              )
            else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  String _selectedFileTitle(BuildContext context) {
    if (files.isEmpty) {
      return option.value == 'image'
          ? _t(context, '选择图片', 'Choose images')
          : _t(context, '选择文件', 'Choose file');
    }
    if (option.value == 'image' && files.length > 1) {
      return _t(
        context,
        '已选择 ${files.length} 张图片',
        '${files.length} images selected',
      );
    }
    return files.first.name;
  }

  String _selectedFileSubtitle(BuildContext context) {
    if (files.isNotEmpty) {
      if (option.value == 'image' && files.length > 1) {
        return files.take(3).map((file) => file.name).join(' / ');
      }
      return _t(
        context,
        '支持 ${option.extensions.join(' / ')}',
        'Supports ${option.extensions.join(' / ')}',
      );
    }
    return _t(
      context,
      '支持 ${option.extensions.join(' / ')}',
      'Supports ${option.extensions.join(' / ')}',
    );
  }
}

InputDecoration _inputDecoration(BuildContext context, String label) {
  final palette = _PrivateUploadPalette.of(context);
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: palette.fieldBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  );
}

class _PrivateMediaOption {
  const _PrivateMediaOption({
    required this.value,
    required this.zh,
    required this.en,
    required this.icon,
    this.extensions = const [],
  });

  final String value;
  final String zh;
  final String en;
  final IconData icon;
  final List<String> extensions;

  bool get requiresFile => extensions.isNotEmpty;

  String label(BuildContext context) => _t(context, zh, en);
}

const _privateMediaOptions = <_PrivateMediaOption>[
  _PrivateMediaOption(
    value: 'txt',
    zh: '书籍 TXT',
    en: 'Book TXT',
    icon: Icons.menu_book_rounded,
    extensions: ['txt'],
  ),
  _PrivateMediaOption(
    value: 'epub',
    zh: '书籍 EPUB',
    en: 'Book EPUB',
    icon: Icons.menu_book_rounded,
    extensions: ['epub'],
  ),
  _PrivateMediaOption(
    value: 'pdf',
    zh: '书籍 PDF',
    en: 'Book PDF',
    icon: Icons.picture_as_pdf_rounded,
    extensions: ['pdf'],
  ),
  _PrivateMediaOption(
    value: 'mp4',
    zh: '电影 MP4',
    en: 'Movie MP4',
    icon: Icons.movie_rounded,
    extensions: ['mp4'],
  ),
  _PrivateMediaOption(
    value: 'mov',
    zh: '电影 MOV',
    en: 'Movie MOV',
    icon: Icons.movie_rounded,
    extensions: ['mov'],
  ),
  _PrivateMediaOption(
    value: 'mp3',
    zh: '音乐 MP3',
    en: 'Music MP3',
    icon: Icons.music_note_rounded,
    extensions: ['mp3'],
  ),
  _PrivateMediaOption(
    value: 'image',
    zh: '图片素材',
    en: 'Image',
    icon: Icons.image_rounded,
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
  ),
  _PrivateMediaOption(
    value: 'link',
    zh: '游戏外链',
    en: 'Game link',
    icon: Icons.sports_esports_rounded,
  ),
  _PrivateMediaOption(
    value: 'article',
    zh: '文字记录',
    en: 'Text note',
    icon: Icons.edit_note_rounded,
  ),
];

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _PrivateUploadPalette {
  const _PrivateUploadPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.fieldBackground,
    required this.noticeBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.bodyText,
    required this.outline,
    required this.accent,
  });

  factory _PrivateUploadPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _PrivateUploadPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      fieldBackground: scheme.surfaceContainerLow,
      noticeBackground: isDark
          ? const Color(0x22FF9585)
          : const Color(0xFFFFF1ED),
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      bodyText: isDark
          ? scheme.onSurface.withValues(alpha: 0.86)
          : const Color(0xFF555A64),
      outline: scheme.outlineVariant,
      accent: const Color(0xFFFF9585),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color fieldBackground;
  final Color noticeBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color bodyText;
  final Color outline;
  final Color accent;
}
