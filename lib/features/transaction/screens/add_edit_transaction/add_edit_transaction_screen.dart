import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:equity_tracker/features/category/providers/category_notifier.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/features/category/widgets/common/category_grid.dart';
import 'package:equity_tracker/core/widgets/calculator_pad.dart';
import 'package:equity_tracker/core/widgets/pickers/date_time_wheel_picker.dart';
import 'package:equity_tracker/core/widgets/pickers/premium_calendar_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';
import 'package:equity_tracker/features/transaction/screens/add_edit_transaction/transaction_header.dart';
import 'package:equity_tracker/features/transaction/screens/add_edit_transaction/transaction_date_selector.dart';
import 'package:equity_tracker/core/widgets/segmented_type_tab.dart';
import 'package:equity_tracker/features/transaction/screens/add_edit_transaction/transaction_footer.dart';
import 'package:equity_tracker/core/widgets/inline_delete_button.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/controllers/add_edit_transaction_controller.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? transaction;
  final DateTime? initialDate;

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
    this.initialDate,
  });

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends ConsumerState<AddEditTransactionScreen> {
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _noteController;

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _noteFocusNode = FocusNode();
  final ScrollController _suggestionsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    
    _amountController = TextEditingController(
      text: t != null ? t.amount.toString() : '',
    );
    _titleController = TextEditingController(text: t?.title ?? '');
    _noteController = TextEditingController(text: t?.note ?? '');

    // Removed global setState on focus change to prevent lag

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addEditTransactionControllerProvider.notifier).init(widget.transaction, widget.initialDate);
      if (widget.transaction == null) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _showCalculatorSheet();
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _titleFocusNode.dispose();
    _noteFocusNode.dispose();
    _suggestionsScrollController.dispose();
    super.dispose();
  }

  void _showCalculatorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      clipBehavior: Clip.hardEdge,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return CalculatorPad(
              value: _amountController.text,
              onChanged: (val) {
                setState(() {
                  _amountController.text = val;
                });
                setSheetState(() {});
              },
              onSubmit: () {
                Navigator.pop(context);
                _titleFocusNode.requestFocus();
              },
            );
          },
        );
      },
    );
  }

  Future<void> _saveTransaction() async {
    final success = await ref.read(addEditTransactionControllerProvider.notifier).saveTransaction(
      titleText: _titleController.text,
      amountText: _amountController.text,
      noteText: _noteController.text,
    );

    if (success && mounted) {
      ref.read(inAppNotificationServiceProvider).showSuccess('Transaction saved');
      Navigator.pop(context);
    } else if (mounted) {
      final error = ref.read(addEditTransactionControllerProvider).error;
      if (error != null) {
        ref.read(inAppNotificationServiceProvider).showError(error);
      }
    }
  }

  void _deleteTransaction() async {
    await ref.read(addEditTransactionControllerProvider.notifier).deleteTransaction();
    if (mounted) {
      ref.read(inAppNotificationServiceProvider).showSuccess('Transaction deleted');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addEditTransactionControllerProvider);
    final controller = ref.read(addEditTransactionControllerProvider.notifier);

    final categoriesAsync = ref.watch(categoryListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final txtColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: txtColor, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (widget.transaction != null)
                      InlineDeleteButton(
                        onDelete: _deleteTransaction,
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),

              TransactionHeader(
                type: state.type,
                amountController: _amountController,
                titleController: _titleController,
                titleFocusNode: _titleFocusNode,
                suggestionsScrollController: _suggestionsScrollController,
                onAmountTap: _showCalculatorSheet,
              ),

              const SizedBox(height: 12),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TransactionDateSelector(
                        date: state.date,
                        onPreviousDay: () => controller.updateDate(state.date.subtract(const Duration(days: 1))),
                        onNextDay: () => controller.updateDate(state.date.add(const Duration(days: 1))),
                        onPickDate: () async {
                          final DateTime? pickedDate = await showPremiumCalendarPicker(
                            context: context,
                            initialDate: state.date,
                          );
                          if (pickedDate != null) {
                            controller.updateDate(DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              state.date.hour,
                              state.date.minute,
                              state.date.second,
                            ));
                          }
                        },
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: SegmentedTypeTab(
                                selectedType: state.type,
                                onChanged: controller.updateType,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black26 : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () => context.push('/manage-categories'),
                                icon: const Icon(Icons.settings_outlined, size: 20),
                                color: txtColor,
                                tooltip: 'Manage Categories',
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: categoriesAsync.when(
                          data: (categories) {
                            final filtered = categories.where((c) => c.type == state.type && c.isEnabled).toList();

                            if (state.categoryId == null && filtered.isNotEmpty) {
                              final defaultCat = filtered.firstWhere(
                                (c) => c.name == '伙食',
                                orElse: () => filtered.first,
                              );
                              Future.microtask(() {
                                if (mounted && state.categoryId == null) {
                                  controller.updateCategory(defaultCat.id);
                                }
                              });
                            }

                            if (filtered.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No Categories',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }
                            return SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: CategoryGrid(
                                categories: filtered,
                                selectedCategoryId: state.categoryId,
                                onSelected: controller.updateCategory,
                              ),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const Center(child: Text('Error')),
                        ),
                      ),

                      TransactionFooter(
                        noteController: _noteController,
                        onSave: _saveTransaction,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
