import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseSeeder {
  static Future<void> uploadProducts() async {
    final CollectionReference products = FirebaseFirestore.instance.collection('products');

    // --- PRODUCER UID DEFINITIONS ---
    const String natureCraftId = "Vrrr6NV1EnXr97EdeYd7fyFyUnG3";
    const String greenLifeId = "Lf8F1OZvdLSslYbhsCaI3pDxmRw2";
    const String summerHarvestId = "965lXTvJr1eUZBYo1aPYMAwP9Zh1";

    List<Map<String, dynamic>> productList = [
      // --- DAIRY -> Nature Craft Farms ---
      {
        'name': 'Organic British Milk',
        'price': 4.20,
        'stock': 120,
        'unit': 'Litre',
        'category': 'Dairy',
        'producer': 'Nature Craft Farms',
        'producerId': natureCraftId,
        'description': 'Rich, creamy, and 100% organic milk sourced from grass-fed cows in the British countryside.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/organic_british_milk.jpg',
        'tags': ['best_seller', 'fresh_farm']
      },
      {
        'name': 'Organic Whole Milk',
        'price': 3.80,
        'stock': 90,
        'unit': 'Litre',
        'category': 'Dairy',
        'producer': 'Nature Craft Farms',
        'producerId': natureCraftId,
        'description': 'Full-fat organic milk with no added preservatives. High in calcium.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/organic_whole_milk.jpg',
        'tags': ['fresh_farm']
      },
      {
        'name': 'White Cheese',
        'price': 8.50,
        'stock': 45,
        'unit': 'kg',
        'category': 'Dairy',
        'producer': 'Nature Craft Farms',
        'producerId': natureCraftId,
        'description': 'Traditional soft white cheese, matured in brine for a rich and salty flavor.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/white_cheese.jpg',
        'tags': ['best_seller']
      },
      {
        'name': 'Parmesan Cheese',
        'price': 22.00,
        'stock': 30,
        'unit': 'kg',
        'category': 'Dairy',
        'producer': 'Nature Craft Farms',
        'producerId': natureCraftId,
        'description': 'Aged hard cheese with a gritty texture and nutty flavor.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/parmesan_cheese.jpg',
        'tags': ['best_seller']
      },
      {
        'name': 'Tofu Cheese',
        'price': 6.50,
        'stock': 60,
        'unit': 'Piece',
        'category': 'Dairy',
        'producer': 'Nature Craft Farms',
        'producerId': natureCraftId,
        'description': 'Organic firm tofu, a great plant-based protein alternative.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/tofu_cheese.jpg',
        'tags': ['fresh_farm']
      },
      {
        'name': 'Roquefort Cheese',
        'price': 28.00,
        'stock': 25,
        'unit': 'kg',
        'category': 'Dairy',
        'producer': 'Nature Craft Farms',
        'producerId': natureCraftId,
        'description': 'Sheep milk blue cheese from the south of France. Tangy and aromatic.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/roquefort_cheese.jpg',
        'tags': ['best_seller']
      },
      {
        'name': 'Clotted Cream',
        'price': 5.00,
        'stock': 40,
        'unit': 'Pack',
        'category': 'Dairy',
        'producer': 'Nature Craft Farms',
        'producerId': natureCraftId,
        'description': 'Authentic clotted cream made from water buffalo milk.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/kaymak.jpg',
        'tags': ['best_seller', 'fresh_farm']
      },
      {
        'name': 'Yogurt',
        'price': 4.00,
        'stock': 85,
        'unit': 'kg',
        'category': 'Dairy',
        'producer': 'Nature Craft Farms',
        'producerId': natureCraftId,
        'description': 'Strained probiotic yogurt with a smooth and thick consistency.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/yogurt.jpg',
        'tags': ['best_seller']
      },
      {
        'name': 'Tulum Cheese',
        'price': 14.00,
        'stock': 35,
        'unit': 'kg',
        'category': 'Dairy',
        'producer': 'Nature Craft Farms',
        'producerId': natureCraftId,
        'description': 'Traditional Turkish goat milk cheese ripened in a goatskin casing.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/tulum_cheese.jpg',
        'tags': ['fresh_farm']
      },
      {
        'name': 'Stilton Cheese',
        'price': 25.00,
        'stock': 20,
        'unit': 'kg',
        'category': 'Dairy',
        'producer': 'Nature Craft Farms',
        'producerId': natureCraftId,
        'description': 'English blue cheese known for its strong taste. Perfect for platters.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/stilton_cheese.jpg',
        'tags': ['fresh_farm']
      },
      {
        'name': 'Farm Fresh Eggs',
        'price': 6.00,
        'stock': 150,
        'unit': 'Dozen',
        'category': 'Dairy',
        'producer': 'Nature Craft Farms',
        'producerId': natureCraftId,
        'description': 'Pasture-raised, free-range organic eggs with deep orange yolks.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/farm_fresh_eggs.jpg',
        'tags': ['fresh_farm']
      },

      // --- FRUITS -> Green Life Organics ---
      {
        'name': 'Green Apples',
        'price': 2.50,
        'stock': 100,
        'unit': 'kg',
        'category': 'Fruits',
        'producer': 'Green Life Organics',
        'producerId': greenLifeId,
        'description': 'Crisp and tart Granny Smith apples. High in fiber and Vitamin C.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/green_apples.jpg',
        'tags': ['fresh_farm']
      },
      {
        'name': 'Banana',
        'price': 1.80,
        'stock': 200,
        'unit': 'kg',
        'category': 'Fruits',
        'producer': 'Green Life Organics',
        'producerId': greenLifeId,
        'description': 'Sweet and creamy premium bananas. Great natural energy booster.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/banana.jpg',
        'tags': ['best_seller']
      },
      {
        'name': 'Strawberry',
        'price': 5.00,
        'stock': 80,
        'unit': 'kg',
        'category': 'Fruits',
        'producer': 'Green Life Organics',
        'producerId': greenLifeId,
        'description': 'Freshly picked, juicy red strawberries. Ideal for desserts.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/strawberry.jpg',
        'tags': ['best_seller']
      },
      {
        'name': 'Cherry',
        'price': 7.50,
        'stock': 50,
        'unit': 'kg',
        'category': 'Fruits',
        'producer': 'Green Life Organics',
        'producerId': greenLifeId,
        'description': 'Sweet dark cherries with a firm texture. High in antioxidants.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/cherry.jpg',
        'tags': ['fresh_farm']
      },
      {
        'name': 'Watermelon',
        'price': 0.90,
        'stock': 70,
        'unit': 'kg',
        'category': 'Fruits',
        'producer': 'Green Life Organics',
        'producerId': greenLifeId,
        'description': 'Deep red, seedless watermelon. The ultimate refreshing summer fruit with high water content.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/watermelon.jpg',
        'tags': ['best_seller', 'fresh_farm']
      },
      {
        'name': 'Orange',
        'price': 2.20,
        'stock': 140,
        'unit': 'kg',
        'category': 'Fruits',
        'producer': 'Green Life Organics',
        'producerId': greenLifeId,
        'description': 'Sweet and juicy oranges packed with Vitamin C. Perfect for fresh juice or snacking.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/orange.jpg',
        'tags': ['best_seller']
      },

      // --- VEGETABLES -> Summer Harvest ---
      {
        'name': 'Tomato',
        'price': 3.00,
        'stock': 160,
        'unit': 'kg',
        'category': 'Vegetables',
        'producer': 'Summer Harvest',
        'producerId': summerHarvestId,
        'description': 'Vine-ripened organic tomatoes. Perfect for sauces and salads.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/tomato.jpg',
        'tags': ['best_seller', 'fresh_farm']
      },
      {
        'name': 'Potato',
        'price': 1.20,
        'stock': 300,
        'unit': 'kg',
        'category': 'Vegetables',
        'producer': 'Summer Harvest',
        'producerId': summerHarvestId,
        'description': 'Versatile all-purpose potatoes. Ideal for mashing or roasting.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/patato.jpg',
        'tags': ['fresh_farm']
      },
      {
        'name': 'Carrot',
        'price': 1.50,
        'stock': 110,
        'unit': 'kg',
        'category': 'Vegetables',
        'producer': 'Summer Harvest',
        'producerId': summerHarvestId,
        'description': 'Bright and sweet organic carrots. Great for juicing or stews.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/carrot.jpg',
        'tags': ['fresh_farm']
      },
      {
        'name': 'Fresh Broccoli',
        'price': 2.00,
        'stock': 65,
        'unit': 'Piece',
        'category': 'Vegetables',
        'producer': 'Summer Harvest',
        'producerId': summerHarvestId,
        'description': 'Nutrient-dense organic broccoli heads. Steam for a healthy side.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/fresh_broccoli.jpg',
        'tags': ['fresh_farm']
      },
      {
        'name': 'Parsley',
        'price': 0.80,
        'stock': 200,
        'unit': 'Piece',
        'category': 'Vegetables',
        'producer': 'Summer Harvest',
        'producerId': summerHarvestId,
        'description': 'Fresh curly parsley, a versatile herb to garnish dishes.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/parsley.jpg',
        'tags': ['fresh_farm']
      },
      {
        'name': 'Onion',
        'price': 1.10,
        'stock': 250,
        'unit': 'kg',
        'category': 'Vegetables',
        'producer': 'Summer Harvest',
        'producerId': summerHarvestId,
        'description': 'Crispy yellow onions with a sharp flavor. A fundamental ingredient for almost any savory dish.',
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/onion.jpg',
        'tags': ['fresh_farm']
      },

      // --- CATEGORY THUMBNAILS ---
      {
        'name': 'Fruits Category',
        'price': 0,
        'stock': 0,
        'unit': 'N/A',
        'category': 'Internal',
        'producer': 'System',
        'producerId': 'system_internal',
        'description': 'Thumbnail for fruits category.',
        'rating': 0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/fruits.jpg',
        'tags': ['category_thumb']
      },
      {
        'name': 'Dairy Category',
        'price': 0,
        'stock': 0,
        'unit': 'N/A',
        'category': 'Internal',
        'producer': 'System',
        'producerId': 'system_internal',
        'description': 'Thumbnail for dairy category.',
        'rating': 0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/dairy.jpg',
        'tags': ['category_thumb']
      },
      {
        'name': 'Vegetables Category',
        'price': 0,
        'stock': 0,
        'unit': 'N/A',
        'category': 'Internal',
        'producer': 'System',
        'producerId': 'system_internal',
        'description': 'Thumbnail for vegetables category.',
        'rating': 0,
        'reviewCount': 0,
        'imageUrl': 'assets/images/vegetables1.jpg',
        'tags': ['category_thumb']
      },
    ];

    try {
      for (var product in productList) {
        final existingProduct = await products
            .where('name', isEqualTo: product['name'])
            .get();

        if (existingProduct.docs.isEmpty) {
          await products.add(product);
          debugPrint("New product added to database: ${product['name']}");
        } else {
          debugPrint("Product already exists, skipping: ${product['name']}");
        }
      }
      debugPrint("Database synchronization completed successfully.");
    } catch (e) {
      debugPrint("Error during database synchronization: $e");
    }
  }
}