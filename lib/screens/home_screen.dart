import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fav_screen.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import '../models/food_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color themeColor = const Color.fromARGB(255, 129, 22, 1);
  List<FoodItem> foodItems = [];
  List<FoodItem> filteredItems = [];
  String searchQuery = "";
  int _currentIndex = 0;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    foodItems = [
      FoodItem(
        name: 'Classic Burger',
        description: 'Juicy beef patty with cheese & lettuce',
        price: 499,
        imagePath: 'assets/beef-burger.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Caesar Salad',
        description: 'Fresh lettuce with Caesar dressing & croutons',
        price: 399,
        imagePath: 'assets/caesar-salad.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Cheese Sandwich',
        description: 'Toasted sandwich with melted cheese and herbs',
        price: 249,
        imagePath: 'assets/cheese-sandwich.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Chicken Nuggets',
        description: 'Crunchy golden nuggets served with ketchup',
        price: 350,
        imagePath: 'assets/chicken-nuggets.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Chocolate Cake',
        description: 'Rich and moist chocolate cake slice',
        price: 299,
        imagePath: 'assets/chocolate-cake.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Coca-Cola',
        description: 'Chilled can of classic Coca-Cola',
        price: 80,
        imagePath: 'assets/coca-cola.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Fish & Chips',
        description: 'Crispy fish fillets with golden fries',
        price: 699,
        imagePath: 'assets/fish-chips.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Crispy Fries',
        description: 'Golden fries with peri peri sprinkle',
        price: 299,
        imagePath: 'assets/fries.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Grilled Chicken',
        description: 'Tender grilled chicken breast with herbs',
        price: 749,
        imagePath: 'assets/grilled-chicken.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Ice Cream',
        description: 'Scoops of vanilla & chocolate ice cream',
        price: 199,
        imagePath: 'assets/ice-cream.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Iced Tea',
        description: 'Chilled lemon iced tea with mint',
        price: 120,
        imagePath: 'assets/iced-tea.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Lemonade',
        description: 'Refreshing homemade lemonade',
        price: 100,
        imagePath: 'assets/lemonade.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Mushroom Soup',
        description: 'Creamy soup made with fresh mushrooms',
        price: 270,
        imagePath: 'assets/mushroom-soup.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Orange Juice',
        description: 'Freshly squeezed orange juice',
        price: 150,
        imagePath: 'assets/orange-juice.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Pasta Alfredo',
        description: 'Creamy Alfredo pasta with herbs',
        price: 649,
        imagePath: 'assets/pasta-alfredo.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Pepsi',
        description: 'Chilled can of Pepsi',
        price: 80,
        imagePath: 'assets/pepsi.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Cheese Pizza',
        description: 'Mozzarella cheese with crispy crust',
        price: 799,
        imagePath: 'assets/pizza.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Spaghetti',
        description: 'Spaghetti in tomato sauce with minced meat',
        price: 599,
        imagePath: 'assets/spaghetti.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Spicy Tacos',
        description: 'Loaded spicy beef tacos with salsa',
        price: 599,
        imagePath: 'assets/tacos.jpg',
        isInCart: false,
      ),
      FoodItem(
        name: 'Veggie Wrap',
        description: 'Fresh vegetables wrapped in soft tortilla',
        price: 399,
        imagePath: 'assets/veggie-wrap.jpg',
        isInCart: false,
      ),
    ];
    filteredItems = foodItems;
    // Load initial cart state from Firestore
    _loadCartState();
  }

  Future<void> _loadCartState() async {
    final user = auth.currentUser;
    if (user == null) return;

    final cartSnapshot =
        await firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .get();

    final cartItems = cartSnapshot.docs.map((doc) => doc.id).toList();

    setState(() {
      for (var item in foodItems) {
        item.isInCart = cartItems.contains(item.name);
      }
      filteredItems = List.from(foodItems);
    });
  }

  Future<void> toggleCart(int index) async {
    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to manage your cart')),
      );
      return;
    }

    final item = filteredItems[index];
    setState(() {
      item.isInCart = !item.isInCart;
    });

    try {
      final cartRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(item.name);

      if (item.isInCart) {
        // Add to Firestore
        await cartRef.set({
          'foodName': item.name,
          'price': item.price,
          'description': item.description,
          'imagePath': item.imagePath,
          'quantity': item.quantity ?? 1,
        });
      } else {
        // Remove from Firestore
        await cartRef.delete();
      }
    } catch (e) {
      // Revert state on error
      setState(() {
        item.isInCart = !item.isInCart;
      });
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update cart: $e')));
    }
  }

  void toggleFavorite(int index) {
    setState(() {
      filteredItems[index].isFavorite = !filteredItems[index].isFavorite;
    });
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredItems =
          foodItems.where((item) {
            return item.name.toLowerCase().contains(searchQuery) ||
                item.description.toLowerCase().contains(searchQuery);
          }).toList();
    });
  }

  void onBottomNavTap(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => FavoritesScreen(
                favoriteItems:
                    foodItems.where((item) => item.isFavorite).toList(),
              ),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AccountScreen(username: '')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickBite', style: TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              onChanged: updateSearch,
              decoration: InputDecoration(
                hintText: 'Search food...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            item.imagePath,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₨ ${item.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: themeColor,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          item.isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color:
                                              item.isFavorite
                                                  ? Colors.red
                                                  : Colors.grey,
                                        ),
                                        onPressed: () => toggleFavorite(index),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          item.isInCart
                                              ? Icons.shopping_cart
                                              : Icons.add_shopping_cart,
                                          color:
                                              item.isInCart
                                                  ? themeColor
                                                  : Colors.grey,
                                        ),
                                        onPressed: () => toggleCart(index),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: themeColor,
        onTap: onBottomNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
