import 'package:flutter/material.dart';

void main() {
  runApp(const NotesApp());
}

// PUBLIC_INTERFACE
class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoteEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1565C0),
          secondary: Color(0xFF90CAF9),
        ),
        scaffoldBackgroundColor: Colors.white,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFB300),
          foregroundColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1565C0),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1565C0)),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF1565C0),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const NotesListPage(),
    );
  }
}

// Note model class
class Note {
  int id;
  String title;
  String content;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });
}

// Notes data manager (simple in-memory for now)
class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  int _nextId = 0;

  List<Note> get notes => List.unmodifiable(_notes);

  // PUBLIC_INTERFACE
  void addNote(String title, String content) {
    _notes.insert(
      0,
      Note(
        id: _nextId++,
        title: title.trim(),
        content: content,
        updatedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // PUBLIC_INTERFACE
  void updateNote(int id, String title, String content) {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notes[idx] = Note(
      id: id,
      title: title.trim(),
      content: content,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  // PUBLIC_INTERFACE
  void deleteNote(int id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // PUBLIC_INTERFACE
  Note? getById(int id) {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  // PUBLIC_INTERFACE
  List<Note> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return notes;
    return _notes
        .where((n) =>
            n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q))
        .toList();
  }

  // PUBLIC_INTERFACE
  void reorderNotes(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final note = _notes.removeAt(oldIndex);
    _notes.insert(newIndex, note);
    notifyListeners();
  }
}

class NotesInheritedProvider extends InheritedNotifier<NotesProvider> {
  const NotesInheritedProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  static NotesProvider of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<NotesInheritedProvider>();
    assert(inherited != null, 'No NotesInheritedProvider found above the widget tree.');
    return inherited!.notifier!;
  }

  @override
  bool updateShouldNotify(NotesInheritedProvider oldWidget) =>
      notifier != oldWidget.notifier;
}

// MAIN SCREEN: Notes List with Search
class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final NotesProvider _provider = NotesProvider();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return NotesInheritedProvider(
      notifier: _provider,
      child: Builder(builder: (context) {
        final notes = _provider.search(_searchQuery);

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                height: 40,
                child: TextField(
                  onChanged: (query) => setState(() => _searchQuery = query),
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    fillColor: Colors.grey[100],
                    filled: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.sort),
                tooltip: 'Reorder notes',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OrganizeNotesPage(),
                    ),
                  );
                },
              ),
            ],
            elevation: 0,
            backgroundColor: Colors.white,
          ),
          body: notes.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? "No notes yet.\nTap '+' to add."
                        : "No results for '$_searchQuery'.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemBuilder: (_, idx) {
                    final note = notes[idx];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      tileColor: Colors.grey[50],
                      title: Text(
                        note.title.isNotEmpty
                            ? note.title
                            : note.content.isNotEmpty
                                ? note.content.length > 20
                                    ? "${note.content.substring(0, 20)}..."
                                    : note.content
                                : "(No Title)",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: note.content.isNotEmpty
                          ? Text(
                              note.content.length > 40
                                  ? "${note.content.substring(0, 40)}..."
                                  : note.content,
                              maxLines: 1,
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 14),
                            )
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Delete note',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete this note?'),
                              content: const Text(
                                  'Are you sure you want to permanently delete this note?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    setState(() {
                                      _provider.deleteNote(note.id);
                                    });
                                  },
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NoteDetailPage(noteId: note.id),
                          ),
                        );
                        setState(() {});
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: notes.length,
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NoteEditPage()),
              );
              setState(() {});
            },
            child: const Icon(Icons.add, size: 30),
            tooltip: 'Add note',
          ),
        );
      }),
    );
  }
}

// DETAIL PAGE (READ or EDIT EXISTING)
class NoteDetailPage extends StatelessWidget {
  final int noteId;
  const NoteDetailPage({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    final provider = NotesInheritedProvider.of(context);
    final note = provider.getById(noteId);

    if (note == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Note not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(note.title.isNotEmpty ? note.title : '(No Title)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit note',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => NoteEditPage(note: note)),
              );
              (context as Element).markNeedsBuild();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isNotEmpty ? note.title : '(No Title)',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 12),
              Text(
                note.content.isNotEmpty ? note.content : '(No content)',
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Last edited: ${_formatDate(note.updatedAt)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'
      ' ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// CREATE/EDIT PAGE
class NoteEditPage extends StatefulWidget {
  final Note? note;
  const NoteEditPage({Key? key, this.note}) : super(key: key);

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.note != null ? widget.note!.title : "");
    _contentCtrl =
        TextEditingController(text: widget.note != null ? widget.note!.content : "");
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final provider = NotesInheritedProvider.of(context);

    setState(() => _isSaving = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (widget.note != null) {
        provider.updateNote(
          widget.note!.id,
          _titleCtrl.text,
          _contentCtrl.text,
        );
      } else {
        provider.addNote(
          _titleCtrl.text,
          _contentCtrl.text,
        );
      }
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.note != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Note' : 'Add Note'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _save(context),
            child: _isSaving
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    isEdit ? 'Save' : 'Add',
                    style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  textInputAction: TextInputAction.next,
                  maxLength: 50,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 20, color: Color(0xFF1565C0)),
                  decoration: const InputDecoration(
                    labelText: "Title",
                    border: InputBorder.none,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      // Allow empty title, but at least one field should not be empty.
                      if (_contentCtrl.text.trim().isEmpty) {
                        return 'Title or content must not be empty';
                      }
                    }
                    return null;
                  },
                ),
                Expanded(
                  child: TextFormField(
                    controller: _contentCtrl,
                    maxLines: null,
                    expands: true,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: "Write your note...",
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      if ((_titleCtrl.text.trim().isEmpty) &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Title or content must not be empty';
                      }
                      return null;
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ORGANIZATION PAGE
class OrganizeNotesPage extends StatefulWidget {
  const OrganizeNotesPage({Key? key}) : super(key: key);

  @override
  State<OrganizeNotesPage> createState() => _OrganizeNotesPageState();
}

class _OrganizeNotesPageState extends State<OrganizeNotesPage> {
  late List<Note> _notes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = NotesInheritedProvider.of(context);
    _notes = List.of(provider.notes);
  }

  @override
  Widget build(BuildContext context) {
    final provider = NotesInheritedProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organize Notes'),
        actions: [
          TextButton(
            onPressed: () {
              provider
                  .reorderNotesBulk(_notes.map((n) => n.id).toList());
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: _notes.length,
        padding: const EdgeInsets.all(18),
        onReorder: (oldIndex, newIndex) {
          setState(() {
            final note = _notes.removeAt(oldIndex);
            _notes.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, note);
          });
        },
        itemBuilder: (_, idx) {
          final note = _notes[idx];
          return ListTile(
            key: ValueKey(note.id),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            tileColor: Colors.grey[50],
            trailing: const Icon(Icons.drag_handle),
            title: Text(
              note.title.isNotEmpty ? note.title : '(No Title)',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Color(0xFF1565C0)),
            ),
          );
        },
      ),
    );
  }
}

// Add bulk reordering interface for provider
extension NotesProviderBulkReorder on NotesProvider {
  // PUBLIC_INTERFACE
  void reorderNotesBulk(List<int> orderedIds) {
    List<Note> sorted = [];
    for (var id in orderedIds) {
      try {
        final note = _notes.firstWhere((n) => n.id == id);
        sorted.add(note);
      } catch (_) {
        // skip if not found
      }
    }
    if (sorted.length == _notes.length) {
      _notes = sorted;
      this.notifyListeners();
    }
  }
}
