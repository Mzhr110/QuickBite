class FoodItem {
  String name;
  double price;
  String description;
  String imagePath;
  bool isInCart;
  bool isFavorite;
  int? quantity;

  FoodItem({
    required this.name,
    required this.price,
    required this.description,
    required this.imagePath,
    this.isInCart = false,
    this.isFavorite = false,
    this.quantity = 1,
  });
}
