import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../providers/vpn_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final InAppPurchase _iap = InAppPurchase.instance;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    final bool isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      setState(() => _isAvailable = false);
      return;
    }

    setState(() => _isAvailable = true);

    // Загружаем продукты (mock-идентификаторы, замените на реальные)
    const Set<String> productIds = {'individual_plan', 'family_plan'};
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(productIds);
    if (response.notFoundIDs.isNotEmpty) {
      // Обработка отсутствующих продуктов
      context.read<VpnProvider>().setPurchaseError('Products not found');
      return;
    }
    setState(() => _products = response.productDetails);
  }

  Future<void> _buyProduct(ProductDetails product) async {
    final vpnProvider = context.read<VpnProvider>();
    vpnProvider.setPurchasing(true);
    vpnProvider.setPurchaseError(null);

    try {
      final PurchaseParam param = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: param);
      vpnProvider.selectPlan(product.id);
    } catch (e) {
      vpnProvider.setPurchaseError('Purchase failed: $e');
    } finally {
      vpnProvider.setPurchasing(false);
    }
  }

  Future<void> _restorePurchases() async {
    final vpnProvider = context.read<VpnProvider>();
    vpnProvider.setPurchasing(true);
    vpnProvider.setPurchaseError(null);

    try {
      await _iap.restorePurchases();
    } catch (e) {
      vpnProvider.setPurchaseError('Restore failed: $e');
    } finally {
      vpnProvider.setPurchasing(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Plan')),
      body: _isAvailable
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a Subscription Plan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (vpnProvider.isPurchasing)
                    const Center(child: CircularProgressIndicator()),
                  if (vpnProvider.purchaseError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        vpnProvider.purchaseError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.description,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Price: ${product.price}',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.green),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: vpnProvider.isPurchasing
                                      ? null
                                      : () => _buyProduct(product),
                                  child: const Text('Buy Now'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed:
                          vpnProvider.isPurchasing ? null : _restorePurchases,
                      child: const Text('Restore Purchases'),
                    ),
                  ),
                ],
              ),
            )
          : const Center(child: Text('Store not available')),
    );
  }
}