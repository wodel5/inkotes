///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsZhHansCn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZhHansCn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhHansCn,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <zh-Hans-CN>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsZhHansCn _root = this; // ignore: unused_field

	@override 
	TranslationsZhHansCn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZhHansCn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$zh_Hans_CN common = _Translations$common$zh_Hans_CN._(_root);
	@override late final _Translations$home$zh_Hans_CN home = _Translations$home$zh_Hans_CN._(_root);
	@override late final _Translations$settings$zh_Hans_CN settings = _Translations$settings$zh_Hans_CN._(_root);
	@override late final _Translations$editor$zh_Hans_CN editor = _Translations$editor$zh_Hans_CN._(_root);
}

// Path: common
class _Translations$common$zh_Hans_CN extends Translations$common$en {
	_Translations$common$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get done => '完成';
	@override String get continueBtn => '继续';
	@override String get cancel => '取消';
}

// Path: home
class _Translations$home$zh_Hans_CN extends Translations$home$en {
	_Translations$home$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$titles$zh_Hans_CN titles = _Translations$home$titles$zh_Hans_CN._(_root);
	@override String get importPdf => '导入 PDF';
	@override late final _Translations$home$tooltips$zh_Hans_CN tooltips = _Translations$home$tooltips$zh_Hans_CN._(_root);
	@override late final _Translations$home$create$zh_Hans_CN create = _Translations$home$create$zh_Hans_CN._(_root);
	@override late final _Translations$home$import$zh_Hans_CN import = _Translations$home$import$zh_Hans_CN._(_root);
	@override String get welcome => '欢迎使用 Inkotes';
	@override String get noFiles => '未找到文件';
	@override String get noPreviewAvailable => '无可用预览';
	@override String editedAt({required Object date}) => '编辑于${date}';
	@override String get today => '今天';
	@override String get yesterday => '昨天';
	@override String get searchNotes => '搜索笔记';
	@override String get searchNoResults => '未找到笔记';
	@override String get createNewNote => '点击 + 按钮新建一个笔记';
	@override late final _Translations$home$renameNote$zh_Hans_CN renameNote = _Translations$home$renameNote$zh_Hans_CN._(_root);
	@override String get deleteNote => '删除笔记';
	@override late final _Translations$home$deleteNoteDialog$zh_Hans_CN deleteNoteDialog = _Translations$home$deleteNoteDialog$zh_Hans_CN._(_root);
	@override late final _Translations$home$trash$zh_Hans_CN trash = _Translations$home$trash$zh_Hans_CN._(_root);
}

// Path: settings
class _Translations$settings$zh_Hans_CN extends Translations$settings$en {
	_Translations$settings$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$prefLabels$zh_Hans_CN prefLabels = _Translations$settings$prefLabels$zh_Hans_CN._(_root);
	@override String get checkUpdateSource => '检查更新源';
	@override String get aboutApp => '关于此应用';
	@override late final _Translations$settings$update$zh_Hans_CN update = _Translations$settings$update$zh_Hans_CN._(_root);
	@override late final _Translations$settings$aboutDialog$zh_Hans_CN aboutDialog = _Translations$settings$aboutDialog$zh_Hans_CN._(_root);
	@override late final _Translations$settings$accentColorPicker$zh_Hans_CN accentColorPicker = _Translations$settings$accentColorPicker$zh_Hans_CN._(_root);
	@override String get autosaveDisabled => '禁用';
}

// Path: editor
class _Translations$editor$zh_Hans_CN extends Translations$editor$en {
	_Translations$editor$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$editor$toolbar$zh_Hans_CN toolbar = _Translations$editor$toolbar$zh_Hans_CN._(_root);
	@override late final _Translations$editor$pens$zh_Hans_CN pens = _Translations$editor$pens$zh_Hans_CN._(_root);
	@override late final _Translations$editor$penOptions$zh_Hans_CN penOptions = _Translations$editor$penOptions$zh_Hans_CN._(_root);
	@override late final _Translations$editor$colors$zh_Hans_CN colors = _Translations$editor$colors$zh_Hans_CN._(_root);
	@override late final _Translations$editor$imageOptions$zh_Hans_CN imageOptions = _Translations$editor$imageOptions$zh_Hans_CN._(_root);
	@override late final _Translations$editor$selectionBar$zh_Hans_CN selectionBar = _Translations$editor$selectionBar$zh_Hans_CN._(_root);
	@override late final _Translations$editor$menu$zh_Hans_CN menu = _Translations$editor$menu$zh_Hans_CN._(_root);
	@override late final _Translations$editor$readOnlyBanner$zh_Hans_CN readOnlyBanner = _Translations$editor$readOnlyBanner$zh_Hans_CN._(_root);
	@override late final _Translations$editor$hud$zh_Hans_CN hud = _Translations$editor$hud$zh_Hans_CN._(_root);
	@override String get pages => '页面管理';
	@override String get more => '更多';
	@override String get untitled => '未命名';
	@override late final _Translations$editor$export$zh_Hans_CN export = _Translations$editor$export$zh_Hans_CN._(_root);
}

// Path: home.titles
class _Translations$home$titles$zh_Hans_CN extends Translations$home$titles$en {
	_Translations$home$titles$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get home => '最近笔记';
	@override String get settings => '设置';
	@override String get appName => 'Inkotes';
}

// Path: home.tooltips
class _Translations$home$tooltips$zh_Hans_CN extends Translations$home$tooltips$en {
	_Translations$home$tooltips$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get exportNote => '导出笔记';
}

// Path: home.create
class _Translations$home$create$zh_Hans_CN extends Translations$home$create$en {
	_Translations$home$create$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get newNote => '新建笔记';
	@override String get importNote => '导入笔记';
}

// Path: home.import
class _Translations$home$import$zh_Hans_CN extends Translations$home$import$en {
	_Translations$home$import$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get success => '笔记导入成功';
	@override String get failed => '笔记导入失败';
	@override String get invalidFile => '无效文件，该文件不是笔记归档';
}

// Path: home.renameNote
class _Translations$home$renameNote$zh_Hans_CN extends Translations$home$renameNote$en {
	_Translations$home$renameNote$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get renameNote => '重命名笔记';
	@override String get noteName => '笔记名称';
	@override String get rename => '重命名';
	@override String get noteNameEmpty => '笔记名称不能为空';
	@override String get noteNameExists => '此名称的笔记已经存在';
}

// Path: home.deleteNoteDialog
class _Translations$home$deleteNoteDialog$zh_Hans_CN extends Translations$home$deleteNoteDialog$en {
	_Translations$home$deleteNoteDialog$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String deleteNotes({required Object n}) => '删除 ${n} 个笔记';
	@override String deleteName({required Object f}) => '删除 ${f}';
	@override String confirmDelete({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '是否永久删除所选笔记？',
		other: '是否永久删除所选笔记？',
	);
	@override String get delete => '删除';
}

// Path: home.trash
class _Translations$home$trash$zh_Hans_CN extends Translations$home$trash$en {
	_Translations$home$trash$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '回收站';
	@override String get empty => '回收站为空';
	@override String get emptyDescription => '删除的笔记会显示在这里';
	@override String get restore => '恢复';
	@override String get delete => '彻底删除';
	@override String get emptyTrash => '清空回收站';
	@override String get confirmEmptyTrash => '确定要清空回收站吗？此操作不可撤销。';
	@override String get confirmPermanentDelete => '确定要彻底删除此笔记吗？此操作不可撤销。';
}

// Path: settings.prefLabels
class _Translations$settings$prefLabels$zh_Hans_CN extends Translations$settings$prefLabels$en {
	_Translations$settings$prefLabels$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get locale => '应用语言';
	@override String get appTheme => '应用主题';
	@override String get autoDisableFingerDrawingWhenStylusDetected => '自动禁用手指绘图';
	@override String get autoSwitchPaperColor => '自动切换画纸颜色';
	@override String get printPageIndicators => '打印页码';
	@override String get autosave => '自动保存';
}

// Path: settings.update
class _Translations$settings$update$zh_Hans_CN extends Translations$settings$update$en {
	_Translations$settings$update$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '更新';
	@override String newVersion({required Object version}) => '发现新版本 ${version}';
	@override String get changelog => '更新日志';
	@override String get downloadUpdate => '下载更新';
	@override String downloading({required Object percent}) => '正在下载 ${percent}';
	@override String get downloaded => '下载完成';
	@override String get downloadFailed => '下载失败，请检查网络后重试';
}

// Path: settings.aboutDialog
class _Translations$settings$aboutDialog$zh_Hans_CN extends Translations$settings$aboutDialog$en {
	_Translations$settings$aboutDialog$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '关于 Inkotes';
	@override String version({required Object version}) => '版本 ${version}';
	@override String copyright({required Object year}) => 'Inkotes Copyright © ${year}\n这是自由软件，欢迎在特定条件下重新分发。';
	@override String get licenses => '查看开源许可证';
}

// Path: settings.accentColorPicker
class _Translations$settings$accentColorPicker$zh_Hans_CN extends Translations$settings$accentColorPicker$en {
	_Translations$settings$accentColorPicker$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get customColor => '自定义颜色';
}

// Path: editor.toolbar
class _Translations$editor$toolbar$zh_Hans_CN extends Translations$editor$toolbar$en {
	_Translations$editor$toolbar$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get exportAs => '导出为：';
}

// Path: editor.pens
class _Translations$editor$pens$zh_Hans_CN extends Translations$editor$pens$en {
	_Translations$editor$pens$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get fountainPen => '钢笔';
	@override String get ballpointPen => '圆珠笔';
	@override String get highlighter => '荧光笔';
	@override String get pencil => '铅笔';
}

// Path: editor.penOptions
class _Translations$editor$penOptions$zh_Hans_CN extends Translations$editor$penOptions$en {
	_Translations$editor$penOptions$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get size => '笔画粗细';
}

// Path: editor.colors
class _Translations$editor$colors$zh_Hans_CN extends Translations$editor$colors$en {
	_Translations$editor$colors$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get colorPicker => '选色器';
	@override String customBrightnessHue({required Object b, required Object h}) => '自定义 ${b} ${h}';
	@override String customHue({required Object h}) => '自定义 ${h}';
	@override String get dark => '暗色';
	@override String get light => '亮色';
	@override String get black => '黑色';
	@override String get darkGrey => '深灰色';
	@override String get grey => '灰色';
	@override String get lightGrey => '浅灰色';
	@override String get white => '白色';
	@override String get red => '红色';
	@override String get green => '绿色';
	@override String get cyan => '青色';
	@override String get blue => '蓝色';
	@override String get yellow => '黄色';
	@override String get purple => '紫色';
	@override String get pink => '粉色';
	@override String get orange => '橙色';
	@override String get pastelRed => '浅红色';
	@override String get pastelOrange => '浅橙色';
	@override String get pastelYellow => '浅黄色';
	@override String get pastelGreen => '浅绿色';
	@override String get pastelCyan => '浅青色';
	@override String get pastelBlue => '浅蓝色';
	@override String get pastelPurple => '浅紫色';
	@override String get pastelPink => '浅粉色';
}

// Path: editor.imageOptions
class _Translations$editor$imageOptions$zh_Hans_CN extends Translations$editor$imageOptions$en {
	_Translations$editor$imageOptions$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '图片选项';
	@override String get invertible => '反转颜色';
	@override String get download => '下载';
	@override String get delete => '删除';
}

// Path: editor.selectionBar
class _Translations$editor$selectionBar$zh_Hans_CN extends Translations$editor$selectionBar$en {
	_Translations$editor$selectionBar$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get delete => '删除';
	@override String get duplicate => '复制';
}

// Path: editor.menu
class _Translations$editor$menu$zh_Hans_CN extends Translations$editor$menu$en {
	_Translations$editor$menu$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get insertPage => '插入';
	@override String get duplicatePage => '复制';
	@override String get clearPage => '清空';
	@override String get deletePage => '删除';
	@override String get lineHeight => '行高';
	@override String get lineThickness => '线条粗细';
	@override String get backgroundPattern => '画纸类型';
	@override late final _Translations$editor$menu$boxFits$zh_Hans_CN boxFits = _Translations$editor$menu$boxFits$zh_Hans_CN._(_root);
	@override late final _Translations$editor$menu$bgPatterns$zh_Hans_CN bgPatterns = _Translations$editor$menu$bgPatterns$zh_Hans_CN._(_root);
}

// Path: editor.readOnlyBanner
class _Translations$editor$readOnlyBanner$zh_Hans_CN extends Translations$editor$readOnlyBanner$en {
	_Translations$editor$readOnlyBanner$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '只读模式';
	@override String get watchingServer => '当前正在监视服务器的更新，此模式下编辑功能已禁用。';
	@override String get corrupted => '无法加载笔记。它可能已损坏或仍在下载中。';
}

// Path: editor.hud
class _Translations$editor$hud$zh_Hans_CN extends Translations$editor$hud$en {
	_Translations$editor$hud$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get unlockZoom => '解锁缩放';
	@override String get lockZoom => '锁定缩放';
	@override String get unlockSingleFingerPan => '启用单指平移';
	@override String get lockSingleFingerPan => '禁用单指平移';
}

// Path: editor.export
class _Translations$editor$export$zh_Hans_CN extends Translations$editor$export$en {
	_Translations$editor$export$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get pngSuccess => 'PNG 已保存到相册';
	@override String get pngFailed => '导出 PNG 失败';
	@override String get pdfSuccess => 'PDF 导出成功';
	@override String get pdfFailed => '导出 PDF 失败';
	@override String get iksSuccess => 'IKS 导出成功';
	@override String get iksFailed => '导出 IKS 失败';
}

// Path: editor.menu.boxFits
class _Translations$editor$menu$boxFits$zh_Hans_CN extends Translations$editor$menu$boxFits$en {
	_Translations$editor$menu$boxFits$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get fill => '拉伸';
	@override String get cover => '覆盖';
	@override String get contain => '包含';
}

// Path: editor.menu.bgPatterns
class _Translations$editor$menu$bgPatterns$zh_Hans_CN extends Translations$editor$menu$bgPatterns$en {
	_Translations$editor$menu$bgPatterns$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get none => '空白';
	@override String get lined => '横线';
	@override String get dots => '点';
}
