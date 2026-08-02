import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/country_phone_input.dart';
import '../../../setup/domain/models/bread_category_model.dart';
import '../../../setup/domain/providers/setup_provider.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/models/customer_order_model.dart';
import '../../domain/providers/customer_provider.dart';
import '../../domain/utils/orders_api_utils.dart';
import '../../domain/utils/money_utils.dart';

enum _CustomerMode { existing, newCustomer }

enum _DateMode { today, tomorrow, custom }

class OrderFormItemRow {
  OrderFormItemRow({
    this.breadCategoryId,
    this.quantity = 1,
    this.unitPrice = '',
  });

  String? breadCategoryId;
  int quantity;
  String unitPrice;
}

class OrderForm extends ConsumerStatefulWidget {
  const OrderForm({
    super.key,
    this.order,
    this.initialCustomer,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  final CustomerOrderModel? order;
  final CustomerModel? initialCustomer;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;
  final bool isSubmitting;

  bool get isEdit => order != null;

  @override
  ConsumerState<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends ConsumerState<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _searchCtl = TextEditingController();
  final _customerNameCtl = TextEditingController();
  final _customerPhoneCtl = TextEditingController();
  final _noteCtl = TextEditingController();
  final _advanceCtl = TextEditingController();
  final _timeCtl = TextEditingController();

  _CustomerMode _customerMode = _CustomerMode.existing;
  _DateMode _dateMode = _DateMode.today;
  DateTime _customDate = todayDateOnly();
  CustomerModel? _selectedCustomer;
  final List<OrderFormItemRow> _items = [OrderFormItemRow()];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(breadCategoryProvider.notifier).load());

    final order = widget.order;
    if (order != null) {
      _noteCtl.text = order.note ?? '';
      _timeCtl.text = formatDeliveryTime(order.deliveryTime) ?? '';
      _items
        ..clear()
        ..addAll(
          order.items.map(
            (i) => OrderFormItemRow(
              breadCategoryId: i.breadCategoryId,
              quantity: i.quantity,
              unitPrice: i.unitPrice,
            ),
          ),
        );
      if (_items.isEmpty) _items.add(OrderFormItemRow());
      _selectedCustomer = order.customer;
      _dateMode = _DateMode.custom;
      _customDate = parseApiDateOnly(order.deliveryDate) ?? todayDateOnly();
    } else if (widget.initialCustomer != null) {
      _selectedCustomer = widget.initialCustomer;
      _customerMode = _CustomerMode.existing;
      Future.microtask(_ensureCustomerPickerLoaded);
    } else {
      Future.microtask(_ensureCustomerPickerLoaded);
    }
  }

  void _ensureCustomerPickerLoaded() {
    if (!mounted || widget.isEdit) return;
    if (_customerMode != _CustomerMode.existing) return;
    ref.read(customerPickerProvider.notifier).ensureLoaded();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _customerNameCtl.dispose();
    _customerPhoneCtl.dispose();
    _noteCtl.dispose();
    _advanceCtl.dispose();
    _timeCtl.dispose();
    super.dispose();
  }

  List<BreadCategoryModel> get _activeCategories {
    return ref
        .watch(breadCategoryProvider)
        .items
        .where((c) => c.isActive)
        .toList();
  }

  String _localeTag(BuildContext context) {
    final l = Localizations.localeOf(context);
    return localeTagFrom(l.languageCode, l.countryCode);
  }

  String _fmtMoney(BuildContext context, num value) {
    return formatMoneyAmount(value, localeTag: _localeTag(context));
  }

  double get _total {
    var sum = 0.0;
    for (final row in _items) {
      final qty = row.quantity;
      final price = double.tryParse(row.unitPrice) ?? 0;
      sum += roundMoney(qty * price);
    }
    return roundMoney(sum);
  }

  double get _advance {
    return roundMoney(double.tryParse(_advanceCtl.text.trim()) ?? 0);
  }

  String get _deliveryDate {
    return switch (_dateMode) {
      _DateMode.today => toDateString(todayDateOnly()),
      _DateMode.tomorrow => toDateString(tomorrowDateOnly()),
      _DateMode.custom => toDateString(_customDate),
    };
  }

  void _onCategorySelected(int index, String? id) {
    setState(() {
      _items[index].breadCategoryId = id;
      if (id != null) {
        final cat = _activeCategories.firstWhere((c) => c.id == id);
        _items[index].unitPrice = cat.sellingPrice;
      }
    });
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate,
      firstDate: todayDateOnly(),
      lastDate: todayDateOnly().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _dateMode = _DateMode.custom;
        _customDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeCtl.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final s = S.of(context);
    final validItems = _items.where((r) => r.breadCategoryId != null).toList();
    if (validItems.isEmpty) return;

    final total = _total;
    final advance = _advance;
    if (!widget.isEdit && advance > 0 && advance > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.ordersAdvanceExceeds)),
      );
      return;
    }

    if (widget.isEdit) {
      final paid = roundMoney(parseAmount(widget.order!.paidAmount));
      if (total < paid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.ordersTotalBelowPaid.replaceAll('{paid}', _fmtMoney(context, paid)),
            ),
          ),
        );
        return;
      }
    }

    final payload = <String, dynamic>{
      'delivery_date': _deliveryDate,
      if (_timeCtl.text.trim().isNotEmpty) 'delivery_time': _timeCtl.text.trim(),
      if (_noteCtl.text.trim().isNotEmpty) 'note': _noteCtl.text.trim(),
      'items': validItems
          .map(
            (r) => {
              'bread_category_id': r.breadCategoryId,
              'quantity': r.quantity,
              'unit_price': double.tryParse(r.unitPrice) ?? 0,
            },
          )
          .toList(),
    };

    if (!widget.isEdit) {
      if (_customerMode == _CustomerMode.existing) {
        if (_selectedCustomer == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.ordersSelectCustomerRequired)),
          );
          return;
        }
        payload['customer_id'] = _selectedCustomer!.id;
      } else {
        payload['customer'] = {
          'name': _customerNameCtl.text.trim(),
          if (_customerPhoneCtl.text.trim().isNotEmpty)
            'phone': _normalizePhone(_customerPhoneCtl.text.trim()),
        };
      }
      if (advance > 0) payload['advance_amount'] = advance;
    }

    await widget.onSubmit(payload);
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998')) return '+$digits';
    if (digits.length == 9) return '+998$digits';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final categories = _activeCategories;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (!widget.isEdit) ...[
            Text(
              s.ordersCustomerTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(s.ordersExistingCustomer),
                  selected: _customerMode == _CustomerMode.existing,
                  onSelected: (_) {
                    setState(() => _customerMode = _CustomerMode.existing);
                    _ensureCustomerPickerLoaded();
                  },
                ),
                ChoiceChip(
                  label: Text(s.ordersNewCustomer),
                  selected: _customerMode == _CustomerMode.newCustomer,
                  onSelected: (_) =>
                      setState(() => _customerMode = _CustomerMode.newCustomer),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_customerMode == _CustomerMode.existing) ...[
              AppTextField(
                hint: s.ordersSearchCustomer,
                controller: _searchCtl,
                onChanged: (v) =>
                    ref.read(customerPickerProvider.notifier).setQuery(v),
              ),
              const SizedBox(height: AppSpacing.sm),
              Builder(
                builder: (context) {
                  final picker = ref.watch(customerPickerProvider);
                  if (picker.isLoading) {
                    return const LinearProgressIndicator();
                  }
                  if (picker.error != null) {
                    return Text(
                      ordersUserErrorMessage(picker.error!, s),
                    );
                  }
                  if (picker.items.isEmpty) {
                    return Text(s.ordersNoCustomers);
                  }
                  return Column(
                    children: [
                      for (final c in picker.items.take(12))
                        ListTile(
                          title: Text(c.name),
                          subtitle: c.phone != null ? Text(c.phone!) : null,
                          trailing: _selectedCustomer?.id == c.id
                              ? Icon(Icons.check_circle, color: cs.primary)
                              : null,
                          onTap: () => setState(() => _selectedCustomer = c),
                        ),
                    ],
                  );
                },
              ),
              if (_selectedCustomer != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${s.ordersSelectCustomer}: ${_selectedCustomer!.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ] else ...[
              AppTextField(
                label: s.ordersCustomerNameLabel,
                controller: _customerNameCtl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? s.fieldRequired : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              CountryPhoneInput(phoneController: _customerPhoneCtl),
            ],
          ] else if (_selectedCustomer != null) ...[
            Text(
              s.ordersCustomerTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _selectedCustomer!.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (_selectedCustomer!.phone != null)
              Text(_selectedCustomer!.phone!),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            s.ordersItemsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (categories.isEmpty)
            Text(s.ordersNoProducts)
          else
            ...List.generate(_items.length, (index) {
              final row = _items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: row.breadCategoryId,
                      decoration: InputDecoration(
                        labelText: s.ordersProductLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadius,
                          ),
                        ),
                      ),
                      items: [
                        for (final c in categories)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => _onCategorySelected(index, v),
                      validator: (v) => v == null ? s.fieldRequired : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('qty-$index-${row.quantity}'),
                            initialValue: '${row.quantity}',
                            decoration: InputDecoration(
                              labelText: s.quantityLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.borderRadius,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) {
                              final n = int.tryParse(v) ?? 1;
                              setState(() => _items[index].quantity = n);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('price-$index-${row.unitPrice}'),
                            initialValue: row.unitPrice,
                            decoration: InputDecoration(
                              labelText: s.ordersUnitPriceLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.borderRadius,
                                ),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _items[index].unitPrice = v),
                          ),
                        ),
                        if (_items.length > 1)
                          IconButton(
                            onPressed: () =>
                                setState(() => _items.removeAt(index)),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          if (categories.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => setState(() => _items.add(OrderFormItemRow())),
              icon: const Icon(Icons.add),
              label: Text(s.ordersAddItem),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            s.ordersDeliveryTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(s.ordersTabToday),
                selected: _dateMode == _DateMode.today,
                onSelected: (_) => setState(() => _dateMode = _DateMode.today),
              ),
              ChoiceChip(
                label: Text(s.ordersTabTomorrow),
                selected: _dateMode == _DateMode.tomorrow,
                onSelected: (_) =>
                    setState(() => _dateMode = _DateMode.tomorrow),
              ),
              ChoiceChip(
                label: Text(s.ordersOtherDate),
                selected: _dateMode == _DateMode.custom,
                onSelected: (_) => _pickCustomDate(),
              ),
            ],
          ),
          if (_dateMode == _DateMode.custom) ...[
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              title: Text(s.ordersDeliveryDateLabel),
              subtitle: Text(toDateString(_customDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickCustomDate,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: s.ordersDeliveryTimeLabel,
            controller: _timeCtl,
            readOnly: true,
            onTap: _pickTime,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: s.ordersNoteLabel,
            hint: s.ordersNotePlaceholder,
            controller: _noteCtl,
            maxLines: 2,
          ),
          if (!widget.isEdit) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: s.ordersAdvanceLabel,
              controller: _advanceCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.ordersTotalLabel),
                    Text(
                      _fmtMoney(context, _total),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (!widget.isEdit && _advance > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.ordersRemainingAfterAdvance),
                      Text(_fmtMoney(context, roundMoney(_total - _advance))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: s.actionSave,
            isLoading: widget.isSubmitting,
            onPressed: widget.isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
