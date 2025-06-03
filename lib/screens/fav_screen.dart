import 'package:flutter/material.dart';
import 'package:quickbite_project/models/food_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_screen.dart'; // import your cart screen

class FavoritesScreen extends StatefulWidget {
  final List<FoodItem> favoriteItems;
  final Color themeColor = const Color.fromARGB(255, 129, 22, 1);

  const FavoritesScreen({super.key, required this.favoriteItems});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> addToCart(FoodItem item) async {
    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add items to cart')),
      );
      return;
    }

    try {
      final cartDoc = firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(item.name);

      final docSnapshot = await cartDoc.get();

      if (docSnapshot.exists) {
        // If item already in cart, increase quantity by 1
        final currentQuantity = docSnapshot.data()?['quantity'] ?? 1;
        await cartDoc.update({'quantity': currentQuantity + 1});
      } else {
        // Add new item to cart
        await cartDoc.set({
          'foodName': item.name,
          'price': item.price,
          'description': item.description,
          'imagePath': item.imagePath,
          'quantity': 1,
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${item.name} added to cart')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add item: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body:
          widget.favoriteItems.isEmpty
              ? Center(
                child: Text(
                  'No favorites added yet!',
                  style: TextStyle(fontSize: 18, color: widget.themeColor),
                ),
              )
              : ListView.builder(
                itemCount: widget.favoriteItems.length,
                itemBuilder: (context, index) {
                  final item = widget.favoriteItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          item.imagePath,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          color: widget.themeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(item.description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite, color: Colors.red),
                          IconButton(
                            icon: const Icon(
                              Icons.add_shopping_cart,
                              color: Color.fromARGB(255, 129, 22, 1),
                            ),
                            onPressed: () {
                              addToCart(item);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
