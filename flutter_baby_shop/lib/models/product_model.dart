class Product {
  final String id;
  final String catId;
  final String desc;
  final String image;
  final String name;
  final double price;

  Product({
    required this.id,
    required this.catId,
    required this.desc,
    required this.image,
    required this.name,
    required this.price,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      catId: data['cat_id'],
      desc: data['desc'],
      image: data['image'],
      name: data['name'],
      price: data['price'].toDouble(),
    );
  }
}
