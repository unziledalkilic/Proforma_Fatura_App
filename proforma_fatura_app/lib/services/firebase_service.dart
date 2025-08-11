import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/company_info.dart';
import '../utils/id_converter.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isOnline = true;
  DateTime? _lastSyncTime;

  // Getters
  firebase_auth.FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  bool get isOnline => _isOnline;
  DateTime? get lastSyncTime => _lastSyncTime;
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Initialize Firebase service
  Future<void> initialize() async {
    await _checkConnectivity();
    _lastSyncTime = DateTime.now();
  }

  // Check internet connectivity
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;
    } catch (e) {
      _isOnline = false;
    }
  }

  // Authentication Methods
  Future<firebase_auth.UserCredential?> registerUser(
    String email,
    String password,
    String name, [
    String? phone,
  ]) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user was created successfully
      if (userCredential.user != null) {
        try {
          // Update display name
          await userCredential.user?.updateDisplayName(name);

          // Create user document in Firestore
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'email': email,
                'name': name,
                'phone': phone,
                'createdAt': FieldValue.serverTimestamp(),
                'lastLogin': FieldValue.serverTimestamp(),
              });
        } catch (firestoreError) {
          debugPrint('Firestore setup error (non-critical): $firestoreError');
          // Don't fail registration if Firestore setup fails
        }

        debugPrint(
          'User registered successfully: ${userCredential.user?.email}',
        );
        return userCredential;
      } else {
        return null;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Şifre çok zayıf';
          break;
        case 'email-already-in-use':
          errorMessage = 'Bu e-posta adresi zaten kullanımda';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi';
          break;
        default:
          errorMessage = 'Kayıt hatası: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Firebase Auth Error: $e');
      // Check if user was actually created despite the error
      if (_auth.currentUser != null) {
        debugPrint('User was created despite error, returning success');
        return null; // The provider will check _auth.currentUser instead
      }
      throw Exception('Kayıt işlemi başarısız: $e');
    }
  }

  Future<firebase_auth.UserCredential?> loginUser(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user is actually authenticated
      if (userCredential.user != null) {
        try {
          // Update last login
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({'lastLogin': FieldValue.serverTimestamp()});
        } catch (firestoreError) {
          debugPrint('Firestore update error (non-critical): $firestoreError');
          // Don't fail the login if Firestore update fails
        }

        debugPrint(
          'User logged in successfully: ${userCredential.user?.email}',
        );
        return userCredential;
      } else {
        return null;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
          break;
        case 'wrong-password':
          errorMessage = 'Hatalı şifre';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi';
          break;
        case 'user-disabled':
          errorMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış';
          break;
        case 'too-many-requests':
          errorMessage =
              'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin';
          break;
        default:
          errorMessage = 'Giriş hatası: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Firebase Auth Error: $e');
      // Check if user is actually authenticated despite the error
      if (_auth.currentUser != null) {
        debugPrint('User is authenticated despite error, returning success');
        // Return a mock UserCredential since we can't create one directly
        // The important thing is that the user is authenticated
        return null; // The provider will check _auth.currentUser instead
      }
      throw Exception('Giriş işlemi başarısız: $e');
    }
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  // Customer Methods
  Future<String?> addCustomer(Customer customer) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('customers')
          .add({
            'name': customer.name,
            'email': customer.email,
            'phone': customer.phone,
            'address': customer.address,
            'taxNumber': customer.taxNumber,

            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return docRef.id;
    } catch (e) {
      debugPrint('Firebase Customer Error: $e');
      return null;
    }
  }

  // Helpers to avoid duplicates by finding existing remote docs
  Future<String?> findExistingCustomerId({
    String? email,
    String? phone,
    String? taxNumber,
    String? name,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final base = _firestore
          .collection('users')
          .doc(userId)
          .collection('customers');
      QuerySnapshot<Map<String, dynamic>> snap;

      if (email != null && email.isNotEmpty) {
        snap = await base.where('email', isEqualTo: email).limit(1).get();
        if (snap.docs.isNotEmpty) return snap.docs.first.id;
      }
      if (phone != null && phone.isNotEmpty) {
        snap = await base.where('phone', isEqualTo: phone).limit(1).get();
        if (snap.docs.isNotEmpty) return snap.docs.first.id;
      }
      if (taxNumber != null && taxNumber.isNotEmpty) {
        snap = await base
            .where('taxNumber', isEqualTo: taxNumber)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) return snap.docs.first.id;
      }
      if (name != null && name.isNotEmpty) {
        snap = await base.where('name', isEqualTo: name).limit(1).get();
        if (snap.docs.isNotEmpty) return snap.docs.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('findExistingCustomerId error: $e');
      return null;
    }
  }

  Future<List<Customer>> getCustomers() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('customers')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Customer(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'],
          phone: data['phone'],
          address: data['address'],
          taxNumber: data['taxNumber'],

          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Firebase Customer Error: $e');
      return [];
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('customers')
          .doc(customer.id.toString())
          .update({
            'name': customer.name,
            'email': customer.email,
            'phone': customer.phone,
            'address': customer.address,
            'taxNumber': customer.taxNumber,

            'updatedAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      debugPrint('Firebase Customer Error: $e');
      return false;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('customers')
          .doc(customerId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Firebase Customer Error: $e');
      return false;
    }
  }

  // Product Methods
  Future<String?> addProduct(Product product) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('products')
          .add({
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'category': product.category,
            'unit': product.unit,
            'companyId': product.companyId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return docRef.id;
    } catch (e) {
      debugPrint('Firebase Product Error: $e');
      return null;
    }
  }

  Future<String?> findExistingProductId({
    required String name,
    String? companyId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .doc(userId)
          .collection('products')
          .where('name', isEqualTo: name);
      if (companyId != null && companyId.isNotEmpty) {
        query = query.where('companyId', isEqualTo: companyId);
      }
      final snap = await query.limit(1).get();
      if (snap.docs.isNotEmpty) return snap.docs.first.id;
      return null;
    } catch (e) {
      debugPrint('findExistingProductId error: $e');
      return null;
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          userId: userId,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0.0).toDouble(),
          unit: data['unit'] ?? '',
          category: data['category'] as String?,
          companyId: data['companyId']?.toString(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Firebase Product Error: $e');
      return [];
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('products')
          .doc(product.id.toString())
          .update({
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'category': product.category,
            'unit': product.unit,
            'companyId': product.companyId,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      debugPrint('Firebase Product Error: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('products')
          .doc(productId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Firebase Product Error: $e');
      return false;
    }
  }

  // Invoice Methods
  Future<String?> addInvoice(Invoice invoice) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .add({
            'invoiceNumber': invoice.invoiceNumber,
            'customer_id': invoice.customer.id, // SQLite uyumlu snake_case
            'customerName': invoice.customer.name,
            'invoiceDate': invoice.invoiceDate.toIso8601String(),
            'dueDate': invoice.dueDate.toIso8601String(),
            'notes': invoice.notes,
            'terms': invoice.terms,
            'discountRate': invoice.discountRate,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Add invoice items
      for (var item in invoice.items) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('invoices')
            .doc(docRef.id)
            .collection('items')
            .add({
              'product_id': item.product.id, // SQLite uyumlu snake_case
              'productName': item.product.name,
              'description': item.product.description,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'discountRate': item.discountRate,
              'taxRate': item.taxRate,
              'notes': item.notes,
            });
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Firebase Invoice Error: $e');
      return null;
    }
  }

  Future<String?> findExistingInvoiceId({required String invoiceNumber}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .where('invoiceNumber', isEqualTo: invoiceNumber)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return snap.docs.first.id;
      return null;
    } catch (e) {
      debugPrint('findExistingInvoiceId error: $e');
      return null;
    }
  }

  Future<List<Invoice>> getInvoices() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .orderBy('createdAt', descending: true)
          .get();

      List<Invoice> invoices = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // Get customer
        final customerDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('customers')
            .doc(
              IdConverter.mixedToString(
                data['customer_id'] ?? data['customerId'],
              ),
            )
            .get();

        Customer customer;
        if (customerDoc.exists) {
          final customerData = customerDoc.data()!;
          customer = Customer(
            id: customerDoc.id,
            name: customerData['name'] ?? '',
            email: customerData['email'],
            phone: customerData['phone'],
            address: customerData['address'],
            taxNumber: customerData['taxNumber'],

            createdAt: (customerData['createdAt'] as Timestamp).toDate(),
            updatedAt: (customerData['updatedAt'] as Timestamp).toDate(),
          );
        } else {
          // Fallback customer if not found
          customer = Customer(
            id: IdConverter.mixedToString(
              data['customer_id'] ?? data['customerId'],
            ),
            name: data['customerName'] ?? 'Unknown Customer',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }

        // Get invoice items
        final itemsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('invoices')
            .doc(doc.id)
            .collection('items')
            .get();

        List<InvoiceItem> items = [];
        for (var itemDoc in itemsSnapshot.docs) {
          final itemData = itemDoc.data();

          // Get product
          final productDoc = await _firestore
              .collection('users')
              .doc(userId)
              .collection('products')
              .doc(
                IdConverter.mixedToString(
                  itemData['product_id'] ?? itemData['productId'],
                ),
              )
              .get();

          Product product;
          if (productDoc.exists) {
            final productData = productDoc.data()!;
            product = Product(
              id: productDoc.id,
              userId: userId,
              name: productData['name'] ?? '',
              description: productData['description'] ?? '',
              price: (productData['price'] ?? 0.0).toDouble(),
              unit: productData['unit'] ?? '',
              category: null,
              createdAt: (productData['createdAt'] as Timestamp).toDate(),
              updatedAt: (productData['updatedAt'] as Timestamp).toDate(),
            );
          } else {
            // Fallback product if not found
            product = Product(
              id: IdConverter.mixedToString(
                itemData['product_id'] ?? itemData['productId'],
              ),
              userId: userId,
              name: itemData['productName'] ?? 'Unknown Product',
              description: itemData['description'] ?? '',
              price: (itemData['unitPrice'] ?? 0.0).toDouble(),
              unit: '',
              category: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }

          items.add(
            InvoiceItem(
              id: itemDoc.id,
              product: product,
              quantity: (itemData['quantity'] ?? 0).toDouble(),
              unitPrice: (itemData['unitPrice'] ?? 0.0).toDouble(),
              discountRate: itemData['discountRate']?.toDouble(),
              taxRate: itemData['taxRate']?.toDouble(),
              notes: itemData['notes'],
            ),
          );
        }

        invoices.add(
          Invoice(
            id: doc.id,
            invoiceNumber: data['invoiceNumber'] ?? '',
            customer: customer,
            invoiceDate: DateTime.parse(
              data['invoiceDate'] ?? DateTime.now().toIso8601String(),
            ),
            dueDate: DateTime.parse(
              data['dueDate'] ?? DateTime.now().toIso8601String(),
            ),
            items: items,
            notes: data['notes'],
            terms: data['terms'],
            discountRate: data['discountRate']?.toDouble(),
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          ),
        );
      }

      return invoices;
    } catch (e) {
      debugPrint('Firebase Invoice Error: $e');
      return [];
    }
  }

  Future<bool> updateInvoice(Invoice invoice) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoice.id.toString())
          .update({
            'invoiceNumber': invoice.invoiceNumber,
            'customer_id': invoice.customer.id
                .toString(), // SQLite uyumlu snake_case
            'customerName': invoice.customer.name,
            'invoiceDate': invoice.invoiceDate.toIso8601String(),
            'dueDate': invoice.dueDate.toIso8601String(),
            'notes': invoice.notes,
            'terms': invoice.terms,
            'discountRate': invoice.discountRate,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update invoice items
      final itemsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoice.id.toString())
          .collection('items');

      // Delete existing items
      final existingItems = await itemsRef.get();
      for (var doc in existingItems.docs) {
        await doc.reference.delete();
      }

      // Add new items
      for (var item in invoice.items) {
        await itemsRef.add({
          'product_id': item.product.id.toString(), // SQLite uyumlu snake_case
          'productName': item.product.name,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'discountRate': item.discountRate,
          'taxRate': item.taxRate,
          'notes': item.notes,
        });
      }

      return true;
    } catch (e) {
      debugPrint('Firebase Update Invoice Error: $e');
      return false;
    }
  }

  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Delete invoice items first
      final itemsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId)
          .collection('items');

      final items = await itemsRef.get();
      for (var doc in items.docs) {
        await doc.reference.delete();
      }

      // Delete invoice
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Firebase Delete Invoice Error: $e');
      return false;
    }
  }

  // Company Info Methods
  Future<bool> saveCompanyInfo(CompanyInfo companyInfo) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Backward-compatible single company save (legacy)
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('company_info')
          .doc('info')
          .set({
            'name': companyInfo.name,
            'address': companyInfo.address,
            'phone': companyInfo.phone,
            'email': companyInfo.email,
            'website': companyInfo.website,
            'taxNumber': companyInfo.taxNumber,
            'logo': companyInfo.logo,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      debugPrint('Firebase Company Info Error: $e');
      return false;
    }
  }

  Future<CompanyInfo?> getCompanyInfo() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('company_info')
          .doc('info')
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return CompanyInfo(
        id: 1,
        name: data['name'] ?? '',
        address: data['address'] ?? '',
        phone: data['phone'] ?? '',
        email: data['email'] ?? '',
        website: data['website'] ?? '',
        taxNumber: data['taxNumber'] ?? '',
        logo: data['logo'] ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Firebase Company Info Error: $e');
      return null;
    }
  }

  // Multi-company profiles
  Future<String?> addCompanyProfile(CompanyInfo company) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('companies')
          .add({
            'name': company.name,
            'address': company.address,
            'phone': company.phone,
            'email': company.email,
            'website': company.website,
            'taxNumber': company.taxNumber,
            'logo': company.logo,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return docRef.id;
    } catch (e) {
      debugPrint('Firebase addCompanyProfile Error: $e');
      return null;
    }
  }

  Future<List<CompanyInfo>> getCompanyProfiles() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('companies')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CompanyInfo(
          id: 0,
          firebaseId: doc.id,
          userId: userId,
          name: data['name'] ?? '',
          address: data['address'],
          phone: data['phone'],
          email: data['email'],
          website: data['website'],

          logo: data['logo'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Firebase getCompanyProfiles Error: $e');
      return [];
    }
  }

  Future<bool> updateCompanyProfile(CompanyInfo company) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null || company.firebaseId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('companies')
          .doc(company.firebaseId!)
          .update({
            'name': company.name,
            'address': company.address,
            'phone': company.phone,
            'email': company.email,
            'website': company.website,
            'taxNumber': company.taxNumber,
            'logo': company.logo,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      debugPrint('Firebase updateCompanyProfile Error: $e');
      return false;
    }
  }

  Future<bool> deleteCompanyProfile(String firebaseId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('companies')
          .doc(firebaseId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Firebase deleteCompanyProfile Error: $e');
      return false;
    }
  }

  // File Upload Methods (Disabled for free plan)
  Future<String?> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<bool> deleteFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
      return true;
    } catch (e) {
      debugPrint('Delete file error: $e');
      return false;
    }
  }

  // Sync Methods
  Future<void> performSync() async {
    await _checkConnectivity();
    if (_isOnline) {
      _lastSyncTime = DateTime.now();
      // Additional sync logic can be added here
    }
  }
}
