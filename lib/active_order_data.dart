import 'package:flutter/material.dart';

class ActiveOrderData {
  final String categoryName;
  final Map<String, dynamic> orderData;
  final Map<String, dynamic> productData;
  final String orderId;
  final String productId;

  ActiveOrderData({
    required this.categoryName,
    required this.orderData,
    required this.productData,
    required this.orderId,
    required this.productId,
  });
}

final ValueNotifier<ActiveOrderData?> activeOrderNotifier = ValueNotifier<ActiveOrderData?>(null);