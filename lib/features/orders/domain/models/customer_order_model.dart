import '../../../setup/domain/models/bread_category_model.dart';
import 'customer_model.dart';

enum CustomerOrderStatus { active, delivered, cancelled }

CustomerOrderStatus parseCustomerOrderStatus(String raw) {
  return switch (raw) {
    'delivered' => CustomerOrderStatus.delivered,
    'cancelled' => CustomerOrderStatus.cancelled,
    _ => CustomerOrderStatus.active,
  };
}

String customerOrderStatusToApi(CustomerOrderStatus status) {
  return switch (status) {
    CustomerOrderStatus.delivered => 'delivered',
    CustomerOrderStatus.cancelled => 'cancelled',
    CustomerOrderStatus.active => 'active',
  };
}

class CustomerOrderItemModel {
  const CustomerOrderItemModel({
    required this.id,
    required this.customerOrderId,
    required this.breadCategoryId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.breadCategory,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String customerOrderId;
  final String breadCategoryId;
  final int quantity;
  final String unitPrice;
  final String subtotal;
  final BreadCategoryModel? breadCategory;
  final String? createdAt;
  final String? updatedAt;

  factory CustomerOrderItemModel.fromJson(Map<String, dynamic> json) {
    final bcJson = json['bread_category'] as Map<String, dynamic>?;
    return CustomerOrderItemModel(
      id: json['id'] as String,
      customerOrderId: json['customer_order_id'] as String,
      breadCategoryId: json['bread_category_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: json['unit_price'].toString(),
      subtotal: json['subtotal'].toString(),
      breadCategory: bcJson != null
          ? BreadCategoryModel.fromJson(bcJson)
          : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class CustomerOrderPaymentModel {
  const CustomerOrderPaymentModel({
    required this.id,
    required this.customerOrderId,
    required this.shopId,
    required this.amount,
    this.paidAt,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String customerOrderId;
  final String shopId;
  final String amount;
  final String? paidAt;
  final String? note;
  final String? createdAt;
  final String? updatedAt;

  factory CustomerOrderPaymentModel.fromJson(Map<String, dynamic> json) {
    return CustomerOrderPaymentModel(
      id: json['id'] as String,
      customerOrderId: json['customer_order_id'] as String,
      shopId: json['shop_id'] as String,
      amount: json['amount'].toString(),
      paidAt: json['paid_at'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class CustomerOrderModel {
  const CustomerOrderModel({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.status,
    required this.deliveryDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.items,
    required this.payments,
    this.customer,
    this.deliveryTime,
    this.note,
    this.deliveredAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String shopId;
  final String customerId;
  final CustomerOrderStatus status;
  final String deliveryDate;
  final String? deliveryTime;
  final String totalAmount;
  final String paidAmount;
  final String remainingAmount;
  final String? note;
  final String? deliveredAt;
  final CustomerModel? customer;
  final List<CustomerOrderItemModel> items;
  final List<CustomerOrderPaymentModel> payments;
  final String? createdAt;
  final String? updatedAt;

  bool get isActive => status == CustomerOrderStatus.active;

  bool get canDelete => isActive && payments.isEmpty;

  factory CustomerOrderModel.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'] as Map<String, dynamic>?;
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    final paymentsJson = json['payments'] as List<dynamic>? ?? const [];

    return CustomerOrderModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      customerId: json['customer_id'] as String,
      status: parseCustomerOrderStatus(json['status'] as String? ?? 'active'),
      deliveryDate: json['delivery_date'] as String,
      deliveryTime: json['delivery_time'] as String?,
      totalAmount: json['total_amount'].toString(),
      paidAmount: json['paid_amount'].toString(),
      remainingAmount: json['remaining_amount'].toString(),
      note: json['note'] as String?,
      deliveredAt: json['delivered_at'] as String?,
      customer: customerJson != null
          ? CustomerModel.fromJson(customerJson)
          : null,
      items: itemsJson
          .map((e) => CustomerOrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: paymentsJson
          .map(
            (e) =>
                CustomerOrderPaymentModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  String itemsSummary() {
    if (items.isEmpty) return '';
    return items
        .map((i) {
          final name = i.breadCategory?.name ?? '';
          return '$name × ${i.quantity}';
        })
        .join(' · ');
  }
}

class OrderListFilters {
  const OrderListFilters({
    this.dateTab = OrderDateTab.today,
    this.status,
    this.customerId,
  });

  final OrderDateTab dateTab;
  final CustomerOrderStatus? status;
  final String? customerId;

  OrderListFilters copyWith({
    OrderDateTab? dateTab,
    CustomerOrderStatus? status,
    bool clearStatus = false,
    String? customerId,
    bool clearCustomerId = false,
  }) {
    return OrderListFilters(
      dateTab: dateTab ?? this.dateTab,
      status: clearStatus ? null : (status ?? this.status),
      customerId: clearCustomerId ? null : (customerId ?? this.customerId),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OrderListFilters &&
        other.dateTab == dateTab &&
        other.status == status &&
        other.customerId == customerId;
  }

  @override
  int get hashCode => Object.hash(dateTab, status, customerId);
}

enum OrderDateTab { today, tomorrow, all }
