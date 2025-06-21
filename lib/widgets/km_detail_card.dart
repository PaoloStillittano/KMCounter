// widgets/km_detail_card.dart
import 'package:flutter/material.dart';
import '../controllers/km_controller.dart';
import '../models/km_entry.dart';
import '../logic/km_detail_logic.dart';

class KmDetailCard extends StatefulWidget {
  final KmController controller;
  final DateTime selectedDate;
  final VoidCallback onClose;

  const KmDetailCard({
    super.key,
    required this.controller,
    required this.selectedDate,
    required this.onClose,
  });

  @override
  State<KmDetailCard> createState() => _KmDetailCardState();
}

class _KmDetailCardState extends State<KmDetailCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late KmDetailLogic _logic;

  List<KmEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeLogic();
    _loadEntries();

    widget.controller.addListener(_onControllerChanged);
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  void _initializeLogic() {
    _logic = KmDetailLogic(
      controller: widget.controller,
      selectedDate: widget.selectedDate,
      onClose: widget.onClose,
      context: context,
    );
  }

  void _loadEntries() {
    setState(() {
      _entries = _logic.getEntriesForDate();
    });
  }

  void _onControllerChanged() {
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    
    // Calcola l'altezza disponibile considerando la tastiera
    final availableHeight = mediaQuery.size.height - 
        mediaQuery.padding.top - 
        mediaQuery.padding.bottom - 
        keyboardHeight - 
        32; // margin totale (16 * 2)

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: availableHeight,
                ),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.surface,
                          theme.colorScheme.surface.withAlpha(230),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeaderSection(logic: _logic, entries: _entries),
                        // Usa Flexible invece di un Container con altezza fissa
                        Flexible(
                          child: _ContentSection(
                            logic: _logic,
                            entries: _entries,
                            availableHeight: availableHeight - 100, // Sottrai l'altezza dell'header
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _animationController.dispose();
    super.dispose();
  }
}

// Header section component
class _HeaderSection extends StatelessWidget {
  final KmDetailLogic logic;
  final List<KmEntry> entries;

  const _HeaderSection({
    required this.logic,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        color: theme.colorScheme.primaryContainer,
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: theme.colorScheme.onPrimaryContainer,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  logic.formatDate(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                if (entries.isNotEmpty)
                  Text(
                    '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onPrimaryContainer.withAlpha(180),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: logic.onClose,
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            tooltip: 'Chiudi',
          ),
        ],
      ),
    );
  }
}

// Content section component - Aggiornato per essere più responsive
class _ContentSection extends StatelessWidget {
  final KmDetailLogic logic;
  final List<KmEntry> entries;
  final double availableHeight;

  const _ContentSection({
    required this.logic,
    required this.entries,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: availableHeight.clamp(200.0, double.infinity),
      ),
      child: entries.isEmpty
          ? _EmptyState(logic: logic)
          : _EntriesList(
              logic: logic, 
              entries: entries,
              maxHeight: availableHeight - 40, // Sottrai il padding
            ),
    );
  }
}

// Empty state component
class _EmptyState extends StatelessWidget {
  final KmDetailLogic logic;

  const _EmptyState({
    required this.logic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.route,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun viaggio registrato',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi il tuo primo viaggio per questa data',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _AddButton(logic: logic, isEmpty: true),
        ],
      ),
    );
  }
}

// Entries list component - Migliorato per la gestione dello spazio
class _EntriesList extends StatelessWidget {
  final KmDetailLogic logic;
  final List<KmEntry> entries;
  final double maxHeight;

  const _EntriesList({
    required this.logic,
    required this.entries,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(entries.length, (index) {
              final entry = entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EntryCard(
                  logic: logic,
                  entry: entry,
                  index: index
                ),
              );
            }),
            const SizedBox(height: 16),
            _AddButton(logic: logic, isEmpty: false),
          ],
        ),
      ),
    );
  }
}

// Entry card component
class _EntryCard extends StatelessWidget {
  final KmDetailLogic logic;
  final KmEntry entry;
  final int index;

  const _EntryCard({
    required this.logic,
    required this.entry,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = logic.getCategoryColor(entry.category);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => logic.showAddEditDialog(entry: entry, index: index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  logic.getCategoryIcon(entry.category),
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.category.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.kilometers} km',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _EntryPopupMenu(
                  logic: logic,
                  entry: entry,
                  index: index),
            ],
          ),
        ),
      ),
    );
  }
}

// Entry popup menu component
class _EntryPopupMenu extends StatelessWidget {
  final KmDetailLogic logic;
  final KmEntry entry;
  final int index;

  const _EntryPopupMenu({
    required this.logic,
    required this.entry,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          logic.showAddEditDialog(entry: entry, index: index);
        } else if (value == 'delete') {
          logic.showDeleteConfirmationDialog(entry);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Modifica'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Elimina', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Icon(
        Icons.more_vert,
        color: theme.colorScheme.outline,
      ),
    );
  }
}

// Add button component
class _AddButton extends StatelessWidget {
  final KmDetailLogic logic;
  final bool isEmpty;

  const _AddButton({
    required this.logic,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => logic.showAddEditDialog(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.add),
        label:
            Text(isEmpty ? 'Aggiungi primo viaggio' : 'Aggiungi nuovo viaggio'),
      ),
    );
  }
}