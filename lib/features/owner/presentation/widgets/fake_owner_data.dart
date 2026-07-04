
class InventoryItem {
  final String id;
  final String name;
  final double currentStock;
  final double minRequired;
  final String unit;
  final String supplierName;
  final String expiryDate;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.minRequired,
    required this.unit,
    required this.supplierName,
    required this.expiryDate,
  });

  bool get isLowStock => currentStock <= minRequired;
}

class SupplierProfile {
  final String id;
  final String name;
  final String contactName;
  final String phone;
  final String email;
  final List<String> suppliedCategories;
  final double rating;

  const SupplierProfile({
    required this.id,
    required this.name,
    required this.contactName,
    required this.phone,
    required this.email,
    required this.suppliedCategories,
    required this.rating,
  });
}

class StaffProfile {
  final String id;
  final String name;
  final String role;
  final String phone;
  final double salary;
  final String shift;
  final bool isPresent;
  final double rating;

  const StaffProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.salary,
    required this.shift,
    required this.isPresent,
    required this.rating,
  });
}

class Promotion {
  final String id;
  final String code;
  final String description;
  final double discountPercent;
  final bool isActive;
  final String expiryDate;

  const Promotion({
    required this.id,
    required this.code,
    required this.description,
    required this.discountPercent,
    required this.isActive,
    required this.expiryDate,
  });
}

class CustomerProfile {
  final String id;
  final String name;
  final String email;
  final int loyaltyPoints;
  final int totalOrders;
  final String tier;

  const CustomerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.loyaltyPoints,
    required this.totalOrders,
    required this.tier,
  });
}

class CustomerFeedbackModel {
  final String id;
  final String customerName;
  final double rating;
  final String comment;
  final String date;
  String? reply;

  CustomerFeedbackModel({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.date,
    this.reply,
  });
}

class SocialFeedItem {
  final String id;
  final String title;
  final String mediaType; // 'video' or 'image'
  final int views;
  final int likes;
  final int commentsCount;
  final String uploadDate;

  const SocialFeedItem({
    required this.id,
    required this.title,
    required this.mediaType,
    required this.views,
    required this.likes,
    required this.commentsCount,
    required this.uploadDate,
  });
}

class FakeOwnerData {
  static final List<InventoryItem> initialInventory = [
    const InventoryItem(id: 'inv_1', name: 'Premium Wheat Flour', currentStock: 120.0, minRequired: 150.0, unit: 'kg', supplierName: 'Agro Foods Ltd.', expiryDate: '2026-10-15'),
    const InventoryItem(id: 'inv_2', name: 'Fresh Italian Mozzarella', currentStock: 45.0, minRequired: 20.0, unit: 'kg', supplierName: 'Milkyway Dairy', expiryDate: '2026-07-20'),
    const InventoryItem(id: 'inv_3', name: 'Organic Roma Tomatoes', currentStock: 8.5, minRequired: 15.0, unit: 'kg', supplierName: 'Eco Farmers Co.', expiryDate: '2026-07-10'),
    const InventoryItem(id: 'inv_4', name: 'Extra Virgin Olive Oil', currentStock: 25.0, minRequired: 10.0, unit: 'liters', supplierName: 'Tuscany Imports', expiryDate: '2027-02-28'),
    const InventoryItem(id: 'inv_5', name: 'Fresh Basil Leaves', currentStock: 1.2, minRequired: 3.0, unit: 'kg', supplierName: 'Eco Farmers Co.', expiryDate: '2026-07-08'),
  ];

  static final List<SupplierProfile> suppliers = [
    const SupplierProfile(id: 'sup_1', name: 'Eco Farmers Co.', contactName: 'John Miller', phone: '+1 555-0199', email: 'orders@ecofarmers.com', suppliedCategories: ['Produce', 'Herbs'], rating: 4.8),
    const SupplierProfile(id: 'sup_2', name: 'Milkyway Dairy', contactName: 'Sarah Jenkins', phone: '+1 555-0245', email: 'sales@milkyway.com', suppliedCategories: ['Dairy', 'Cheese'], rating: 4.5),
    const SupplierProfile(id: 'sup_3', name: 'Agro Foods Ltd.', contactName: 'Robert Vance', phone: '+1 555-0322', email: 'wholesale@agrofoods.com', suppliedCategories: ['Flour', 'Grains'], rating: 4.2),
    const SupplierProfile(id: 'sup_4', name: 'Tuscany Imports', contactName: 'Marco Rossi', phone: '+1 555-0811', email: 'marco@tuscanyimports.it', suppliedCategories: ['Olive Oil', 'Wine'], rating: 4.9),
  ];

  static final List<StaffProfile> staff = [
    const StaffProfile(id: 'st_1', name: 'Alessandro Russo', role: 'Head Chef', phone: '+1 555-1100', salary: 4500.0, shift: 'Morning (8 AM - 4 PM)', isPresent: true, rating: 4.9),
    const StaffProfile(id: 'st_2', name: 'Jessica Vance', role: 'Sous Chef', phone: '+1 555-1101', salary: 3200.0, shift: 'Evening (4 PM - 12 AM)', isPresent: true, rating: 4.7),
    const StaffProfile(id: 'st_3', name: 'Marcus Sterling', role: 'POS Cashier / Manager', phone: '+1 555-1102', salary: 2800.0, shift: 'Morning (8 AM - 4 PM)', isPresent: true, rating: 4.8),
    const StaffProfile(id: 'st_4', name: 'Elena Rostova', role: 'Senior Waitress', phone: '+1 555-1103', salary: 1800.0, shift: 'Evening (4 PM - 12 AM)', isPresent: false, rating: 4.6),
    const StaffProfile(id: 'st_5', name: 'David Kim', role: 'Delivery Driver', phone: '+1 555-1104', salary: 1600.0, shift: 'Evening (5 PM - 11 PM)', isPresent: true, rating: 4.4),
  ];

  static final List<Promotion> promotions = [
    const Promotion(id: 'promo_1', code: 'BISTRO20', description: '20% off all main courses on weekends', discountPercent: 20.0, isActive: true, expiryDate: '2026-08-31'),
    const Promotion(id: 'promo_2', code: 'SWEET15', description: '15% off dessert platters during lunch hours', discountPercent: 15.0, isActive: false, expiryDate: '2026-06-30'),
    const Promotion(id: 'promo_3', code: 'WELCOME50', description: 'Flat 50% discount on first meal checkout', discountPercent: 50.0, isActive: true, expiryDate: '2026-12-31'),
    const Promotion(id: 'promo_4', code: 'MIDWEEK10', description: '10% off entire bill on Tuesdays & Wednesdays', discountPercent: 10.0, isActive: true, expiryDate: '2026-09-15'),
  ];

  static final List<CustomerProfile> customers = [
    const CustomerProfile(id: 'cust_1', name: 'Emily Watson', email: 'emily.w@gmail.com', loyaltyPoints: 1250, totalOrders: 28, tier: 'Gold'),
    const CustomerProfile(id: 'cust_2', name: 'Michael Chang', email: 'chang.m@outlook.com', loyaltyPoints: 620, totalOrders: 14, tier: 'Silver'),
    const CustomerProfile(id: 'cust_3', name: 'Sophia Martinez', email: 'sophia.m@icloud.com', loyaltyPoints: 1950, totalOrders: 42, tier: 'Platinum'),
    const CustomerProfile(id: 'cust_4', name: 'Daniel Brooks', email: 'dbrooks@yahoo.com', loyaltyPoints: 180, totalOrders: 5, tier: 'Bronze'),
    const CustomerProfile(id: 'cust_5', name: 'Amanda Cooper', email: 'cooper.a@gmail.com', loyaltyPoints: 850, totalOrders: 19, tier: 'Silver'),
  ];

  static final List<CustomerFeedbackModel> initialFeedback = [
    CustomerFeedbackModel(id: 'fb_1', customerName: 'Emily Watson', rating: 5.0, comment: 'The wood-fired Neapolitan pizza was phenomenal! The crust had the perfect char and lightness. Service was prompt too.', date: '2026-07-03 20:15', reply: 'Thank you Emily! We source our mozzarella straight from Italy to give you that authentic Neapolitan taste.'),
    CustomerFeedbackModel(id: 'fb_2', customerName: 'Daniel Brooks', rating: 3.5, comment: 'Good quality ingredients, but the lasagna took almost 30 minutes to arrive at our table. Tasted wonderful though.', date: '2026-07-02 18:30'),
    CustomerFeedbackModel(id: 'fb_3', customerName: 'Sophia Martinez', rating: 5.0, comment: 'Outstanding ambiance and high-tech table ordering! Scanning the QR code is so easy and seamless.', date: '2026-07-02 14:10', reply: 'Glad you loved the BistroOS gateway, Sophia! We strive to make ordering fun and fast.'),
    CustomerFeedbackModel(id: 'fb_4', customerName: 'Alex Mercer', rating: 4.0, comment: 'Really liked the Tiramisu, it had strong espresso tones. Mains were delicious. Will visit again.', date: '2026-06-30 21:05'),
  ];

  static final List<SocialFeedItem> socialFeed = [
    const SocialFeedItem(id: 'soc_1', title: 'Chefs Special: Sizzling Penne Arrabiata live cooking', mediaType: 'video', views: 3240, likes: 890, commentsCount: 54, uploadDate: '2026-07-02'),
    const SocialFeedItem(id: 'soc_2', title: 'Behind the Scenes: Sourcing our organic garden fresh basil', mediaType: 'video', views: 1850, likes: 450, commentsCount: 22, uploadDate: '2026-06-28'),
    const SocialFeedItem(id: 'soc_3', title: 'Weekend vibes at Gourmet Bistro terrace seating', mediaType: 'image', views: 950, likes: 310, commentsCount: 15, uploadDate: '2026-06-25'),
  ];

  static final List<VirtualShop> virtualShops = [
    VirtualShop(
      shopId: 'SHOP-001',
      shopName: 'Gourmet Bistro',
      email: 'owner@restaurantos.com',
      password: 'password123',
      tableCapacity: 8,
      staffQuantity: 5,
    ),
    VirtualShop(
      shopId: 'SHOP-002',
      shopName: 'Little Italy Pizzeria',
      email: 'italy@restaurantos.com',
      password: 'password123',
      tableCapacity: 5,
      staffQuantity: 3,
    ),
  ];
}

class VirtualShop {
  final String shopId;
  final String shopName;
  final String email;
  final String password;
  int tableCapacity;
  int staffQuantity;

  VirtualShop({
    required this.shopId,
    required this.shopName,
    required this.email,
    required this.password,
    required this.tableCapacity,
    required this.staffQuantity,
  });
}
