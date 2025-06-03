// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:quickbite_project/models/food_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Color themeColor = const Color.fromARGB(255, 129, 22, 1);

  List<FoodItem> _cartItems = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadCartFromFirestore();
  }

  Future<void> _loadCartFromFirestore() async {
    final user = auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view your cart')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cartSnapshot =
          await firestore
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .get();

      final cartItems =
          cartSnapshot.docs.map((doc) {
            final data = doc.data();
            return FoodItem(
              name: data['foodName'] ?? '',
              price: (data['price'] as num?)?.toDouble() ?? 0.0,
              description: data['description'] ?? '',
              imagePath: data['imagePath'] ?? '',
              isInCart: true,
              quantity: (data['quantity'] as num?)?.toInt() ?? 1,
            );
          }).toList();

      setState(() {
        _cartItems = cartItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load cart: $e')));
    }
  }

  Future<void> removeFromCart(int index) async {
    final user = auth.currentUser;
    if (user == null) return;

    setState(() {
      _isProcessing = true;
    });

    final item = _cartItems[index];

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(item.name)
          .delete();

      setState(() {
        _cartItems.removeAt(index);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove item: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> updateQuantity(int index, int newQuantity) async {
    if (newQuantity < 1) return; // Prevent quantity less than 1

    final user = auth.currentUser;
    if (user == null) return;

    setState(() {
      _isProcessing = true;
    });

    final item = _cartItems[index];

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(item.name)
          .update({'quantity': newQuantity});

      setState(() {
        _cartItems[index].quantity = newQuantity;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update quantity: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  double getTotalPrice() {
    return _cartItems.fold(
      0.0,
      (total, item) => total + (item.price * (item.quantity ?? 1)),
    );
  }

  Future<void> confirmOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to confirm your order')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final deliveryAddress = _addressController.text.trim();

    try {
      // Save order details to Firestore
      final orderRef = firestore.collection('orders').doc();
      await orderRef.set({
        'userId': user.uid,
        'address': deliveryAddress,
        'items':
            _cartItems
                .map(
                  (item) => {
                    'foodName': item.name,
                    'price': item.price,
                    'description': item.description,
                    'imagePath': item.imagePath,
                    'quantity': item.quantity ?? 1,
                  },
                )
                .toList(),
        'totalPrice': getTotalPrice(),
        'orderDate': Timestamp.now(),
        'status': 'pending',
      });

      // Clear cart
      final cartRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart');
      final cartDocs = await cartRef.get();
      for (var doc in cartDocs.docs) {
        await doc.reference.delete();
      }

      setState(() {
        _cartItems.clear();
        _addressController.clear();
      });

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Order Confirmed!'),
              content: Text(
                'Your order has been placed and will be delivered to:\n\n$deliveryAddress',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to confirm order: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cartItems.isEmpty
              ? Center(
                child: Text(
                  'Your cart is empty!',
                  style: TextStyle(fontSize: 18, color: themeColor),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 8,
                              ),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.asset(
                                        item.imagePath,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              color: themeColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.description,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '₨ ${(item.price * (item.quantity ?? 1)).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: themeColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                                color: Colors.red,
                                                size: 28,
                                              ),
                                              onPressed:
                                                  _isProcessing
                                                      ? null
                                                      : () {
                                                        int currentQty =
                                                            item.quantity ?? 1;
                                                        if (currentQty > 1) {
                                                          updateQuantity(
                                                            index,
                                                            currentQty - 1,
                                                          );
                                                        }
                                                      },
                                            ),
                                            Text(
                                              '${item.quantity ?? 1}',
                                              style: TextStyle(
                                                color: themeColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                                color: Colors.green,
                                                size: 28,
                                              ),
                                              onPressed:
                                                  _isProcessing
                                                      ? null
                                                      : () {
                                                        int currentQty =
                                                            item.quantity ?? 1;
                                                        updateQuantity(
                                                          index,
                                                          currentQty + 1,
                                                        );
                                                      },
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red.shade700,
                                            size: 28,
                                          ),
                                          onPressed:
                                              _isProcessing
                                                  ? null
                                                  : () => removeFromCart(index),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total: ₨ ${getTotalPrice().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Delivery Address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your delivery address';
                          }
                          return null;
                        },
                        maxLines: 2,
                        enabled: !_isProcessing,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isProcessing ? null : confirmOrder,
                          child:
                              _isProcessing
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text(
                                    'Confirm Order',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
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
