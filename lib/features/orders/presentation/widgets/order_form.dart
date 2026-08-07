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
import 'initials_avatar.dart';

enum _CustomerMode { existing, newCustomer }

enum _DateMode { today, tomorrow, custom }

/// Mahsulot qatori — controller'lar qatorda saqlanadi, shunda har harf
/// yozilganda input qayta yaratilmaydi va fokus yo'qolmaydi.
class OrderFormItemRow {
  OrderFormItemRow({
    this.breadCategoryId,
    int quantity = 1,
    String unitPrice = '',
  })  : qtyCtl = TextEditingController(text: '$quantity'),
        priceCtl = TextEditingController(text: unitPrice);

  String? breadCategoryId;
  final TextEditingController qtyCtl;
  final TextEditingController priceCtl;

  int get quantity => int.tryParse(qtyCtl.text.trim()) ?? 1;
  String get unitPrice => priceCtl.text.trim();

  void dispose() {
    qtyCtl.dispose();
    priceCtl.dispose();
  }
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

  _CustomerMode _customerMode = _CustomerMode.existing;
  _DateMode _dateMode = _DateMode.today;
  DateTime _customDate = todayDateOnly();
  String? _deliveryTime;
  CustomerModel? _selectedCustomer;
  final List<OrderFormItemRow> _items = [OrderFormItemRow()];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(breadCategoryProvider.notifier).load());

    final order = widget.order;
    if (order != null) {
      _noteCtl.text = order.note ?? '';
      _deliveryTime = formatDeliveryTime(order.deliveryTime);
      for (final row in _items) {
        row.dispose();
      }
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
    for (final row in _items) {
      row.dispose();
    }
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
      final price = double.tryParse(row.unitPrice) ?? 0;
      sum += roundMoney(row.quantity * price);
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
        _items[index].priceCtl.text = cat.sellingPrice;
      }
    });
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate,
      firstDate: todayDateOnly(),
      lastDate: todayDateOnly().add(const Duration(days: 365 * 2)),
      // Faqat kalendar — qo'lda yozish rejimida noto'g'ri format xatosi chiqadi.
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (!mounted) return;
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
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _deliveryTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
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
      if (_deliveryTime != null && _deliveryTime!.isNotEmpty)
        'delivery_time': _deliveryTime,
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
        // Pastga surilganda klaviatura yopiladi — foydalanuvchi qulay scroll qiladi.
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          // ─── Mijoz ───
          if (!widget.isEdit) ...[
            _SectionTitle(icon: Icons.person_outline, label: s.ordersCustomerTitle),
            const SizedBox(height: AppSpacing.sm),
            if (_selectedCustomer != null &&
                _customerMode == _CustomerMode.existing)
              _SelectedCustomerTile(
                customer: _selectedCustomer!,
                onClear: () {
                  setState(() => _selectedCustomer = null);
                  _ensureCustomerPickerLoaded();
                },
              )
            else ...[
              Row(
                children: [
                  _ModeChip(
                    label: s.ordersExistingCustomer,
                    selected: _customerMode == _CustomerMode.existing,
                    onTap: () {
                      setState(() => _customerMode = _CustomerMode.existing);
                      _ensureCustomerPickerLoaded();
                    },
                  ),
                  const SizedBox(width: 8),
                  _ModeChip(
                    label: s.ordersNewCustomer,
                    selected: _customerMode == _CustomerMode.newCustomer,
                    onTap: () => setState(
                      () => _customerMode = _CustomerMode.newCustomer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              if (_customerMode == _CustomerMode.existing) ...[
                AppTextField(
                  hint: s.ordersSearchCustomer,
                  controller: _searchCtl,
                  prefixIcon: const Icon(Icons.search, size: 20),
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
                      return Text(ordersUserErrorMessage(picker.error!, s));
                    }
                    if (picker.items.isEmpty) {
                      return Text(s.ordersNoCustomers);
                    }
                    final items = picker.items.take(30).toList();
                    // Ro'yxat sahifani cho'zmaydi — o'z ichida scroll bo'ladi.
                    return Container(
                      constraints: const BoxConstraints(maxHeight: 248),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        primary: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                        itemBuilder: (context, index) {
                          final c = items[index];
                          return _CustomerPickTile(
                            customer: c,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              FocusScope.of(context).unfocus();
                              setState(() => _selectedCustomer = c);
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ] else ...[
                AppTextField(
                  label: s.ordersCustomerNameLabel,
                  controller: _customerNameCtl,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? s.fieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                CountryPhoneInput(phoneController: _customerPhoneCtl),
              ],
            ],
            const SizedBox(height: AppSpacing.lg),
          ] else if (_selectedCustomer != null) ...[
            _SectionTitle(icon: Icons.person_outline, label: s.ordersCustomerTitle),
            const SizedBox(height: AppSpacing.sm),
            _SelectedCustomerTile(customer: _selectedCustomer!),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ─── Mahsulotlar ───
          _SectionTitle(
            icon: Icons.shopping_basket_outlined,
            label: s.ordersItemsTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (categories.isEmpty)
            Text(s.ordersNoProducts)
          else ...[
            for (var index = 0; index < _items.length; index++)
              Padding(
                key: ObjectKey(_items[index]),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                child: _ItemCard(
                  row: _items[index],
                  categories: categories,
                  productLabel: s.ordersProductLabel,
                  priceLabel: s.ordersUnitPriceLabel,
                  requiredMessage: s.fieldRequired,
                  canDelete: _items.length > 1,
                  onCategoryChanged: (v) => _onCategorySelected(index, v),
                  onValuesChanged: () => setState(() {}),
                  onDelete: () {
                    final row = _items[index];
                    setState(() => _items.removeAt(index));
                    // Frame tugagach dispose — fokusdagi widget xatosini oldini oladi.
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => row.dispose(),
                    );
                  },
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _items.add(OrderFormItemRow())),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(s.ordersAddItem),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // ─── Topshirish: sana + vaqt bitta qatorda ───
          _SectionTitle(
            icon: Icons.local_shipping_outlined,
            label: s.ordersDeliveryTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ModeChip(
                label: s.ordersTabToday,
                selected: _dateMode == _DateMode.today,
                onTap: () => setState(() => _dateMode = _DateMode.today),
              ),
              _ModeChip(
                label: s.ordersTabTomorrow,
                selected: _dateMode == _DateMode.tomorrow,
                onTap: () => setState(() => _dateMode = _DateMode.tomorrow),
              ),
              _ModeChip(
                icon: Icons.event_outlined,
                label: _dateMode == _DateMode.custom
                    ? formatDateOnlyLocale(
                        toDateString(_customDate),
                        localeTag: _localeTag(context),
                      )
                    : s.ordersOtherDate,
                selected: _dateMode == _DateMode.custom,
                onTap: _pickCustomDate,
              ),
              _ModeChip(
                icon: Icons.schedule_outlined,
                label: _deliveryTime ?? s.ordersDeliveryTimeLabel,
                selected: _deliveryTime != null,
                onTap: _pickTime,
                onClear: _deliveryTime != null
                    ? () => setState(() => _deliveryTime = null)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Izoh va zaklad ───
          AppTextField(
            hint: s.ordersNotePlaceholder,
            controller: _noteCtl,
            prefixIcon: const Icon(Icons.notes_outlined, size: 20),
          ),
          if (!widget.isEdit) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            AppTextField(
              hint: s.ordersAdvanceLabel,
              controller: _advanceCtl,
              prefixIcon: const Icon(Icons.payments_outlined, size: 20),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // ─── Jami va saqlash ───
          _TotalBar(
            totalLabel: s.ordersTotalLabel,
            totalValue: _fmtMoney(context, _total),
            remainingLabel: (!widget.isEdit && _advance > 0)
                ? s.ordersRemainingAfterAdvance
                : null,
            remainingValue: (!widget.isEdit && _advance > 0)
                ? _fmtMoney(context, roundMoney(_total - _advance))
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
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

/// Bo'lim sarlavhasi — kichik icon + matn.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 17, color: cs.primary),
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Ixcham tanlov chipi (rejim/sana/vaqt uchun).
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.onClear,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.65);

    return Material(
      color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onClear!();
                  },
                  child: Icon(Icons.close_rounded, size: 15, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tanlangan mijoz — ixcham tile, X bilan almashtirish mumkin.
class _SelectedCustomerTile extends StatelessWidget {
  const _SelectedCustomerTile({required this.customer, this.onClear});

  final CustomerModel customer;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          InitialsAvatar(name: customer.name, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (customer.phone != null && customer.phone!.isNotEmpty)
                  Text(
                    customer.phone!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onClear!();
              },
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}

/// Qidiruv natijasidagi mijoz qatori — zich.
class _CustomerPickTile extends StatelessWidget {
  const _CustomerPickTile({required this.customer, required this.onTap});

  final CustomerModel customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: InitialsAvatar(name: customer.name, size: 34),
      title: Text(
        customer.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: customer.phone != null ? Text(customer.phone!) : null,
      trailing: Icon(
        Icons.add_circle_outline,
        size: 20,
        color: cs.primary.withValues(alpha: 0.6),
      ),
      onTap: onTap,
    );
  }
}

/// Bitta mahsulot qatori: mahsulot + [− soni +] + narx + o'chirish.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.row,
    required this.categories,
    required this.productLabel,
    required this.priceLabel,
    required this.requiredMessage,
    required this.canDelete,
    required this.onCategoryChanged,
    required this.onValuesChanged,
    required this.onDelete,
  });

  final OrderFormItemRow row;
  final List<BreadCategoryModel> categories;
  final String productLabel;
  final String priceLabel;
  final String requiredMessage;
  final bool canDelete;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onValuesChanged;
  final VoidCallback onDelete;

  void _step(int delta) {
    final next = (int.tryParse(row.qtyCtl.text.trim()) ?? 1) + delta;
    if (next < 1) return;
    row.qtyCtl.text = '$next';
    onValuesChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: row.breadCategoryId,
                  isDense: true,
                  decoration: InputDecoration(
                    hintText: productLabel,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: onCategoryChanged,
                  validator: (v) => v == null ? requiredMessage : null,
                ),
              ),
              if (canDelete)
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onDelete();
                  },
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: cs.error.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepperButton(icon: Icons.remove_rounded, onTap: () => _step(-1)),
              SizedBox(
                width: 52,
                child: TextFormField(
                  controller: row.qtyCtl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  scrollPadding: const EdgeInsets.only(bottom: 140),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  // Bo'sh yoki 0 — qizil belgilanadi, forma yuborilmaydi.
                  validator: (v) =>
                      (int.tryParse(v?.trim() ?? '') ?? 0) < 1 ? '' : null,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    // Xato matni o'rniga faqat qizil chiziq ko'rsatiladi.
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: cs.error, width: 1.5),
                    ),
                    focusedErrorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: cs.error, width: 1.5),
                    ),
                  ),
                  onChanged: (_) => onValuesChanged(),
                ),
              ),
              _StepperButton(icon: Icons.add_rounded, onTap: () => _step(1)),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: row.priceCtl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  scrollPadding: const EdgeInsets.only(bottom: 140),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: InputDecoration(
                    hintText: priceLabel,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => onValuesChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 19, color: cs.primary),
        ),
      ),
    );
  }
}

/// Jami summa paneli.
class _TotalBar extends StatelessWidget {
  const _TotalBar({
    required this.totalLabel,
    required this.totalValue,
    this.remainingLabel,
    this.remainingValue,
  });

  final String totalLabel;
  final String totalValue;
  final String? remainingLabel;
  final String? remainingValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(totalLabel, style: const TextStyle(fontSize: 14)),
              Text(
                totalValue,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          if (remainingLabel != null && remainingValue != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(remainingLabel!, style: const TextStyle(fontSize: 13)),
                Text(
                  remainingValue!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
