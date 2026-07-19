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
	@override String get welcome => '欢迎使用锋页笔记';
	@override String get noFiles => '未找到文件';
	@override String get noPreviewAvailable => '无可用预览';
	@override String get createNewNote => '点击 + 按钮新建一个笔记';
	@override String get backFolder => '回到上一个文件夹';
	@override String get rootDirectory => '根目录';
	@override late final _Translations$home$newFolder$zh_Hans_CN newFolder = _Translations$home$newFolder$zh_Hans_CN._(_root);
	@override late final _Translations$home$renameNote$zh_Hans_CN renameNote = _Translations$home$renameNote$zh_Hans_CN._(_root);
	@override late final _Translations$home$moveNote$zh_Hans_CN moveNote = _Translations$home$moveNote$zh_Hans_CN._(_root);
	@override String get deleteNote => '删除笔记';
	@override late final _Translations$home$deleteNoteDialog$zh_Hans_CN deleteNoteDialog = _Translations$home$deleteNoteDialog$zh_Hans_CN._(_root);
	@override late final _Translations$home$renameFolder$zh_Hans_CN renameFolder = _Translations$home$renameFolder$zh_Hans_CN._(_root);
	@override late final _Translations$home$deleteFolder$zh_Hans_CN deleteFolder = _Translations$home$deleteFolder$zh_Hans_CN._(_root);
	@override late final _Translations$home$sort$zh_Hans_CN sort = _Translations$home$sort$zh_Hans_CN._(_root);
}

// Path: settings
class _Translations$settings$zh_Hans_CN extends Translations$settings$en {
	_Translations$settings$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$prefCategories$zh_Hans_CN prefCategories = _Translations$settings$prefCategories$zh_Hans_CN._(_root);
	@override late final _Translations$settings$prefLabels$zh_Hans_CN prefLabels = _Translations$settings$prefLabels$zh_Hans_CN._(_root);
	@override late final _Translations$settings$prefDescriptions$zh_Hans_CN prefDescriptions = _Translations$settings$prefDescriptions$zh_Hans_CN._(_root);
	@override late final _Translations$settings$accentColorPicker$zh_Hans_CN accentColorPicker = _Translations$settings$accentColorPicker$zh_Hans_CN._(_root);
	@override late final _Translations$settings$reset$zh_Hans_CN reset = _Translations$settings$reset$zh_Hans_CN._(_root);
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
	@override late final _Translations$editor$versionTooNew$zh_Hans_CN versionTooNew = _Translations$editor$versionTooNew$zh_Hans_CN._(_root);
	@override late final _Translations$editor$quill$zh_Hans_CN quill = _Translations$editor$quill$zh_Hans_CN._(_root);
	@override late final _Translations$editor$hud$zh_Hans_CN hud = _Translations$editor$hud$zh_Hans_CN._(_root);
	@override String get pages => '页面管理';
	@override String get more => '更多';
	@override String get untitled => '未命名';
	@override String get needsToSaveBeforeExiting => '正在保存您的更改... 完成后您可以安全地退出编辑器';
}

// Path: home.titles
class _Translations$home$titles$zh_Hans_CN extends Translations$home$titles$en {
	_Translations$home$titles$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get home => '最近笔记';
	@override String get settings => '设置';
	@override String get appName => '锋页笔记';
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

// Path: home.newFolder
class _Translations$home$newFolder$zh_Hans_CN extends Translations$home$newFolder$en {
	_Translations$home$newFolder$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get newFolder => '新建文件夹';
	@override String get folderName => '文件夹名称';
	@override String get create => '创建';
	@override String get folderNameEmpty => '文件夹名称不能为空';
	@override String get folderNameContainsSlash => '文件夹名称不能包含斜杠';
	@override String get folderNameExists => '文件夹已存在';
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
	@override String get noteNameForbiddenCharacters => '笔记名称包含禁止使用的字符';
	@override String get noteNameReserved => '保留了笔记名';
}

// Path: home.moveNote
class _Translations$home$moveNote$zh_Hans_CN extends Translations$home$moveNote$en {
	_Translations$home$moveNote$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get moveNote => '移动笔记';
	@override String moveNotes({required Object n}) => '移动 ${n} 个笔记';
	@override String moveName({required Object f}) => '移动 ${f}';
	@override String get move => '移动';
	@override String renamedTo({required Object newName}) => '笔记将重命名为 ${newName}';
	@override String get multipleRenamedTo => '以下笔记将被重命名：';
	@override String numberRenamedTo({required Object n}) => '${n} 个笔记将被重命名以避免冲突';
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

// Path: home.renameFolder
class _Translations$home$renameFolder$zh_Hans_CN extends Translations$home$renameFolder$en {
	_Translations$home$renameFolder$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get renameFolder => '重命名文件夹';
	@override String get folderName => '文件夹名称';
	@override String get rename => '重命名';
	@override String get folderNameEmpty => '文件夹不能为空';
	@override String get folderNameContainsSlash => '文件夹名称不能包含斜线';
	@override String get folderNameExists => '已存在该名称的文件夹';
}

// Path: home.deleteFolder
class _Translations$home$deleteFolder$zh_Hans_CN extends Translations$home$deleteFolder$en {
	_Translations$home$deleteFolder$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get deleteFolder => '删除文件夹';
	@override String deleteName({required Object f}) => '删除 ${f}';
	@override String get delete => '删除';
	@override String get alsoDeleteContents => '同时删除此文件夹中的所有笔记';
}

// Path: home.sort
class _Translations$home$sort$zh_Hans_CN extends Translations$home$sort$en {
	_Translations$home$sort$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get sortBy => '按...排序';
	@override String get nameAToZ => '姓名（A-Z）';
	@override String get nameZToA => '姓名（从 A 到 Z）';
	@override String get lastModifiedNewToOld => '编辑（最新优先）';
	@override String get lastModifiedOldToNew => '编辑（按最旧的排序）';
}

// Path: settings.prefCategories
class _Translations$settings$prefCategories$zh_Hans_CN extends Translations$settings$prefCategories$en {
	_Translations$settings$prefCategories$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get general => '通用';
	@override String get writing => '书写';
	@override String get editor => '编辑器';
}

// Path: settings.prefLabels
class _Translations$settings$prefLabels$zh_Hans_CN extends Translations$settings$prefLabels$en {
	_Translations$settings$prefLabels$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get locale => '应用语言';
	@override String get appTheme => '应用主题';
	@override String get autoDisableFingerDrawingWhenStylusDetected => '自动禁用手指绘图';
	@override String get printPageIndicators => '打印页码';
	@override String get autosave => '自动保存';
}

// Path: settings.prefDescriptions
class _Translations$settings$prefDescriptions$zh_Hans_CN extends Translations$settings$prefDescriptions$en {
	_Translations$settings$prefDescriptions$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get autoDisableFingerDrawingWhenStylusDetected => '当检测到手写笔时关闭手指绘图';
	@override String get printPageIndicators => '在导出中显示页码';
	@override String get autosave => '短暂延迟后自动保存，或永不保存';
}

// Path: settings.accentColorPicker
class _Translations$settings$accentColorPicker$zh_Hans_CN extends Translations$settings$accentColorPicker$en {
	_Translations$settings$accentColorPicker$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get pickAColor => '选取颜色';
}

// Path: settings.reset
class _Translations$settings$reset$zh_Hans_CN extends Translations$settings$reset$en {
	_Translations$settings$reset$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '重置此设置？';
	@override String get button => '重置';
}

// Path: editor.toolbar
class _Translations$editor$toolbar$zh_Hans_CN extends Translations$editor$toolbar$en {
	_Translations$editor$toolbar$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get toggleColors => '切换颜色 (Ctrl C)';
	@override String get select => '选择';
	@override String get toggleEraser => '切换橡皮擦 (Ctrl E)';
	@override String get photo => '照片';
	@override String get text => '文本';
	@override String get toggleFingerDrawing => '切换手指绘图 (Ctrl F)';
	@override String get undo => '撤销';
	@override String get redo => '重做';
	@override String get export => '导出 (Ctrl Shift S)';
	@override String get exportAs => '导出为：';
	@override String get fullscreen => '切换全屏 (F11)';
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
	@override String get laserPointer => '激光笔';
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
	@override String get setAsBackground => '设为背景';
	@override String get removeAsBackground => '作为背景移除';
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
	@override String get clearAllPages => '清除全部页面';
	@override String get insertPage => '插入';
	@override String get duplicatePage => '复制';
	@override String get clearPage => '清空';
	@override String get deletePage => '删除';
	@override String get lineHeight => '行高';
	@override String get lineThickness => '线条粗细';
	@override String get backgroundImageFit => '背景图像拟合';
	@override String get backgroundPattern => '画纸类型';
	@override String get defaultColor => '默认';
	@override String get import => '导入';
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

// Path: editor.versionTooNew
class _Translations$editor$versionTooNew$zh_Hans_CN extends Translations$editor$versionTooNew$en {
	_Translations$editor$versionTooNew$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '此笔记使用新版 Saber 编辑而成';
	@override String get subtitle => '编辑此笔记可能会导致某些信息丢失。您想忽略并编辑吗？';
	@override String get allowEditing => '允许编辑';
}

// Path: editor.quill
class _Translations$editor$quill$zh_Hans_CN extends Translations$editor$quill$en {
	_Translations$editor$quill$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get typeSomething => '在这里输入...';
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
	@override String get unlockAxisAlignedPan => '解锁水平或垂直平移';
	@override String get lockAxisAlignedPan => '锁定水平或垂直平移';
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
