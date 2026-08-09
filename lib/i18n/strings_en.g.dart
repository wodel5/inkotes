///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  );

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$home$en home = Translations$home$en.internal(_root);
	late final Translations$settings$en settings = Translations$settings$en.internal(_root);
	late final Translations$editor$en editor = Translations$editor$en.internal(_root);
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Done'
	String get done => 'Done';

	/// en: 'Continue'
	String get continueBtn => 'Continue';

	/// en: 'Cancel'
	String get cancel => 'Cancel';
}

// Path: home
class Translations$home$en {
	Translations$home$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$home$titles$en titles = Translations$home$titles$en.internal(_root);

	/// en: 'Import PDF'
	String get importPdf => 'Import PDF';

	late final Translations$home$tooltips$en tooltips = Translations$home$tooltips$en.internal(_root);
	late final Translations$home$create$en create = Translations$home$create$en.internal(_root);
	late final Translations$home$import$en import = Translations$home$import$en.internal(_root);

	/// en: 'Welcome to Inkotes'
	String get welcome => 'Welcome to Inkotes';

	/// en: 'No files found'
	String get noFiles => 'No files found';

	/// en: 'No preview available'
	String get noPreviewAvailable => 'No preview available';

	/// en: 'Edited $date'
	String editedAt({required Object date}) => 'Edited ${date}';

	/// en: 'Today'
	String get today => 'Today';

	/// en: 'Yesterday'
	String get yesterday => 'Yesterday';

	/// en: 'Search notes'
	String get searchNotes => 'Search notes';

	/// en: 'No notes found'
	String get searchNoResults => 'No notes found';

	/// en: 'Tap the + button to create a new note'
	String get createNewNote => 'Tap the + button to create a new note';

	late final Translations$home$renameNote$en renameNote = Translations$home$renameNote$en.internal(_root);

	/// en: 'Delete note'
	String get deleteNote => 'Delete note';

	late final Translations$home$deleteNoteDialog$en deleteNoteDialog = Translations$home$deleteNoteDialog$en.internal(_root);
	late final Translations$home$trash$en trash = Translations$home$trash$en.internal(_root);
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$settings$prefLabels$en prefLabels = Translations$settings$prefLabels$en.internal(_root);

	/// en: 'Update source'
	String get checkUpdateSource => 'Update source';

	/// en: 'About the APP'
	String get aboutApp => 'About the APP';

	late final Translations$settings$update$en update = Translations$settings$update$en.internal(_root);
	late final Translations$settings$aboutDialog$en aboutDialog = Translations$settings$aboutDialog$en.internal(_root);
	late final Translations$settings$accentColorPicker$en accentColorPicker = Translations$settings$accentColorPicker$en.internal(_root);

	/// en: 'Never'
	String get autosaveDisabled => 'Never';
}

// Path: editor
class Translations$editor$en {
	Translations$editor$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$editor$toolbar$en toolbar = Translations$editor$toolbar$en.internal(_root);
	late final Translations$editor$pens$en pens = Translations$editor$pens$en.internal(_root);
	late final Translations$editor$penOptions$en penOptions = Translations$editor$penOptions$en.internal(_root);
	late final Translations$editor$colors$en colors = Translations$editor$colors$en.internal(_root);
	late final Translations$editor$imageOptions$en imageOptions = Translations$editor$imageOptions$en.internal(_root);
	late final Translations$editor$selectionBar$en selectionBar = Translations$editor$selectionBar$en.internal(_root);
	late final Translations$editor$menu$en menu = Translations$editor$menu$en.internal(_root);
	late final Translations$editor$readOnlyBanner$en readOnlyBanner = Translations$editor$readOnlyBanner$en.internal(_root);
	late final Translations$editor$hud$en hud = Translations$editor$hud$en.internal(_root);

	/// en: 'Page Management'
	String get pages => 'Page Management';

	/// en: 'More'
	String get more => 'More';

	/// en: 'Untitled'
	String get untitled => 'Untitled';

	late final Translations$editor$export$en export = Translations$editor$export$en.internal(_root);
}

// Path: home.titles
class Translations$home$titles$en {
	Translations$home$titles$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Recent notes'
	String get home => 'Recent notes';

	/// en: 'Settings'
	String get settings => 'Settings';

	/// en: 'Inkotes'
	String get appName => 'Inkotes';
}

// Path: home.tooltips
class Translations$home$tooltips$en {
	Translations$home$tooltips$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Export note'
	String get exportNote => 'Export note';
}

// Path: home.create
class Translations$home$create$en {
	Translations$home$create$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'New note'
	String get newNote => 'New note';

	/// en: 'Import note'
	String get importNote => 'Import note';
}

// Path: home.import
class Translations$home$import$en {
	Translations$home$import$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Note imported successfully'
	String get success => 'Note imported successfully';

	/// en: 'Failed to import note'
	String get failed => 'Failed to import note';

	/// en: 'Invalid file. This is not a note archive.'
	String get invalidFile => 'Invalid file. This is not a note archive.';
}

// Path: home.renameNote
class Translations$home$renameNote$en {
	Translations$home$renameNote$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Rename note'
	String get renameNote => 'Rename note';

	/// en: 'Note name'
	String get noteName => 'Note name';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'Note name can't be empty'
	String get noteNameEmpty => 'Note name can\'t be empty';

	/// en: 'A note with this name already exists'
	String get noteNameExists => 'A note with this name already exists';
}

// Path: home.deleteNoteDialog
class Translations$home$deleteNoteDialog$en {
	Translations$home$deleteNoteDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Delete $n notes'
	String deleteNotes({required Object n}) => 'Delete ${n} notes';

	/// en: 'Delete $f'
	String deleteName({required Object f}) => 'Delete ${f}';

	/// en: '(one) {Permanently delete the selected note?} (other) {Permanently delete the selected notes?}'
	String confirmDelete({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Permanently delete the selected note?',
		other: 'Permanently delete the selected notes?',
	);

	/// en: 'Delete'
	String get delete => 'Delete';
}

// Path: home.trash
class Translations$home$trash$en {
	Translations$home$trash$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Trash'
	String get title => 'Trash';

	/// en: 'Trash is empty'
	String get empty => 'Trash is empty';

	/// en: 'Deleted notes will appear here'
	String get emptyDescription => 'Deleted notes will appear here';

	/// en: 'Restore'
	String get restore => 'Restore';

	/// en: 'Delete permanently'
	String get delete => 'Delete permanently';

	/// en: 'Empty trash'
	String get emptyTrash => 'Empty trash';

	/// en: 'Are you sure you want to empty the trash? This cannot be undone.'
	String get confirmEmptyTrash => 'Are you sure you want to empty the trash? This cannot be undone.';

	/// en: 'Are you sure you want to permanently delete this note? This cannot be undone.'
	String get confirmPermanentDelete => 'Are you sure you want to permanently delete this note? This cannot be undone.';
}

// Path: settings.prefLabels
class Translations$settings$prefLabels$en {
	Translations$settings$prefLabels$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Language'
	String get locale => 'Language';

	/// en: 'App theme'
	String get appTheme => 'App theme';

	/// en: 'Auto-disable finger drawing'
	String get autoDisableFingerDrawingWhenStylusDetected => 'Auto-disable finger drawing';

	/// en: 'Auto-switch paper color'
	String get autoSwitchPaperColor => 'Auto-switch paper color';

	/// en: 'Print page indicators'
	String get printPageIndicators => 'Print page indicators';

	/// en: 'Auto-save'
	String get autosave => 'Auto-save';
}

// Path: settings.update
class Translations$settings$update$en {
	Translations$settings$update$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Update'
	String get title => 'Update';

	/// en: 'New version $version available'
	String newVersion({required Object version}) => 'New version ${version} available';

	/// en: 'Changelog'
	String get changelog => 'Changelog';

	/// en: 'Download update'
	String get downloadUpdate => 'Download update';

	/// en: 'Downloading $percent'
	String downloading({required Object percent}) => 'Downloading ${percent}';

	/// en: 'Download complete'
	String get downloaded => 'Download complete';

	/// en: 'Download failed, please check your network and retry'
	String get downloadFailed => 'Download failed, please check your network and retry';
}

// Path: settings.aboutDialog
class Translations$settings$aboutDialog$en {
	Translations$settings$aboutDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'About Inkotes'
	String get title => 'About Inkotes';

	/// en: 'Version $version'
	String version({required Object version}) => 'Version ${version}';

	/// en: 'Inkotes Copyright © $year This is free software, and you are welcome to redistribute it under certain conditions.'
	String copyright({required Object year}) => 'Inkotes Copyright © ${year}\nThis is free software, and you are welcome to redistribute it under certain conditions.';

	/// en: 'View open source licenses'
	String get licenses => 'View open source licenses';
}

// Path: settings.accentColorPicker
class Translations$settings$accentColorPicker$en {
	Translations$settings$accentColorPicker$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Custom color'
	String get customColor => 'Custom color';
}

// Path: editor.toolbar
class Translations$editor$toolbar$en {
	Translations$editor$toolbar$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Export as:'
	String get exportAs => 'Export as:';
}

// Path: editor.pens
class Translations$editor$pens$en {
	Translations$editor$pens$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Fountain pen'
	String get fountainPen => 'Fountain pen';

	/// en: 'Ballpoint pen'
	String get ballpointPen => 'Ballpoint pen';

	/// en: 'Highlighter'
	String get highlighter => 'Highlighter';

	/// en: 'Pencil'
	String get pencil => 'Pencil';
}

// Path: editor.penOptions
class Translations$editor$penOptions$en {
	Translations$editor$penOptions$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Stroke size'
	String get size => 'Stroke size';
}

// Path: editor.colors
class Translations$editor$colors$en {
	Translations$editor$colors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Color picker'
	String get colorPicker => 'Color picker';

	/// en: 'Custom $b $h'
	String customBrightnessHue({required Object b, required Object h}) => 'Custom ${b} ${h}';

	/// en: 'Custom $h'
	String customHue({required Object h}) => 'Custom ${h}';

	/// en: 'dark'
	String get dark => 'dark';

	/// en: 'light'
	String get light => 'light';

	/// en: 'Black'
	String get black => 'Black';

	/// en: 'Dark grey'
	String get darkGrey => 'Dark grey';

	/// en: 'Grey'
	String get grey => 'Grey';

	/// en: 'Light grey'
	String get lightGrey => 'Light grey';

	/// en: 'White'
	String get white => 'White';

	/// en: 'Red'
	String get red => 'Red';

	/// en: 'Green'
	String get green => 'Green';

	/// en: 'Cyan'
	String get cyan => 'Cyan';

	/// en: 'Blue'
	String get blue => 'Blue';

	/// en: 'Yellow'
	String get yellow => 'Yellow';

	/// en: 'Purple'
	String get purple => 'Purple';

	/// en: 'Pink'
	String get pink => 'Pink';

	/// en: 'Orange'
	String get orange => 'Orange';

	/// en: 'Pastel red'
	String get pastelRed => 'Pastel red';

	/// en: 'Pastel orange'
	String get pastelOrange => 'Pastel orange';

	/// en: 'Pastel yellow'
	String get pastelYellow => 'Pastel yellow';

	/// en: 'Pastel green'
	String get pastelGreen => 'Pastel green';

	/// en: 'Pastel cyan'
	String get pastelCyan => 'Pastel cyan';

	/// en: 'Pastel blue'
	String get pastelBlue => 'Pastel blue';

	/// en: 'Pastel purple'
	String get pastelPurple => 'Pastel purple';

	/// en: 'Pastel pink'
	String get pastelPink => 'Pastel pink';
}

// Path: editor.imageOptions
class Translations$editor$imageOptions$en {
	Translations$editor$imageOptions$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Image options'
	String get title => 'Image options';

	/// en: 'Invertible'
	String get invertible => 'Invertible';

	/// en: 'Download'
	String get download => 'Download';

	/// en: 'Delete'
	String get delete => 'Delete';
}

// Path: editor.selectionBar
class Translations$editor$selectionBar$en {
	Translations$editor$selectionBar$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Duplicate'
	String get duplicate => 'Duplicate';
}

// Path: editor.menu
class Translations$editor$menu$en {
	Translations$editor$menu$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Insert'
	String get insertPage => 'Insert';

	/// en: 'Duplicate'
	String get duplicatePage => 'Duplicate';

	/// en: 'Clear'
	String get clearPage => 'Clear';

	/// en: 'Delete'
	String get deletePage => 'Delete';

	/// en: 'Line height'
	String get lineHeight => 'Line height';

	/// en: 'Line thickness'
	String get lineThickness => 'Line thickness';

	/// en: 'Paper type'
	String get backgroundPattern => 'Paper type';

	late final Translations$editor$menu$boxFits$en boxFits = Translations$editor$menu$boxFits$en.internal(_root);
	late final Translations$editor$menu$bgPatterns$en bgPatterns = Translations$editor$menu$bgPatterns$en.internal(_root);
}

// Path: editor.readOnlyBanner
class Translations$editor$readOnlyBanner$en {
	Translations$editor$readOnlyBanner$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Read-only mode'
	String get title => 'Read-only mode';

	/// en: 'You are currently watching for updates on the server. Editing is disabled in this mode.'
	String get watchingServer => 'You are currently watching for updates on the server. Editing is disabled in this mode.';

	/// en: 'Failed to load note. It may be corrupted or still being downloaded.'
	String get corrupted => 'Failed to load note. It may be corrupted or still being downloaded.';
}

// Path: editor.hud
class Translations$editor$hud$en {
	Translations$editor$hud$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Unlock zoom'
	String get unlockZoom => 'Unlock zoom';

	/// en: 'Lock zoom'
	String get lockZoom => 'Lock zoom';

	/// en: 'Enable single-finger panning'
	String get unlockSingleFingerPan => 'Enable single-finger panning';

	/// en: 'Disable single-finger panning'
	String get lockSingleFingerPan => 'Disable single-finger panning';
}

// Path: editor.export
class Translations$editor$export$en {
	Translations$editor$export$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'PNG saved to gallery'
	String get pngSuccess => 'PNG saved to gallery';

	/// en: 'Failed to export PNG'
	String get pngFailed => 'Failed to export PNG';

	/// en: 'PDF exported successfully'
	String get pdfSuccess => 'PDF exported successfully';

	/// en: 'Failed to export PDF'
	String get pdfFailed => 'Failed to export PDF';

	/// en: 'IKS exported successfully'
	String get iksSuccess => 'IKS exported successfully';

	/// en: 'Failed to export IKS'
	String get iksFailed => 'Failed to export IKS';
}

// Path: editor.menu.boxFits
class Translations$editor$menu$boxFits$en {
	Translations$editor$menu$boxFits$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Stretch'
	String get fill => 'Stretch';

	/// en: 'Cover'
	String get cover => 'Cover';

	/// en: 'Contain'
	String get contain => 'Contain';
}

// Path: editor.menu.bgPatterns
class Translations$editor$menu$bgPatterns$en {
	Translations$editor$menu$bgPatterns$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Blank'
	String get none => 'Blank';

	/// en: 'Lined'
	String get lined => 'Lined';

	/// en: 'Dots'
	String get dots => 'Dots';
}
