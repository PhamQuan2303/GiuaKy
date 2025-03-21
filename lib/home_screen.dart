import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final CollectionReference products = FirebaseFirestore.instance.collection(
    'products',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Colors.blue[200],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showProductDialog();
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: products.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Lỗi khi tải dữ liệu"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var product = docs[index];
              return Card(
                color: Colors.blue[50],
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading:
                      product['imageUrl'] != null &&
                              product['imageUrl'].isNotEmpty
                          ? Image.network(
                            product['imageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                          : const Icon(Icons.image, color: Colors.grey),
                  title: Text(
                    product['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${product['price']} VND",
                        style: const TextStyle(color: Colors.blue),
                      ),
                      Text(product['category']),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showProductDialog(product);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmDelete(product.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showProductDialog([DocumentSnapshot? product]) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();
    final TextEditingController imageUrlController = TextEditingController();

    if (product != null) {
      nameController.text = product['name'];
      priceController.text = product['price'].toString();
      categoryController.text = product['category'];
      imageUrlController.text = product['imageUrl'] ?? "";
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? "Thêm sản phẩm" : "Chỉnh sửa sản phẩm"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Tên sản phẩm"),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Giá"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: "Loại sản phẩm"),
              ),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(labelText: "URL Ảnh"),
              ),
              const SizedBox(height: 10),
              imageUrlController.text.isNotEmpty
                  ? Image.network(
                    imageUrlController.text,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                  : const SizedBox.shrink(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            TextButton(
              onPressed: () async {
                if (product == null) {
                  _addProduct(
                    nameController.text,
                    priceController.text,
                    categoryController.text,
                    imageUrlController.text,
                  );
                } else {
                  _updateProduct(
                    product.id,
                    nameController.text,
                    priceController.text,
                    categoryController.text,
                    imageUrlController.text,
                  );
                }
                Navigator.pop(context);
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addProduct(
    String name,
    String price,
    String category,
    String? imageUrl,
  ) async {
    await products.add({
      'name': name,
      'price': int.tryParse(price) ?? 0,
      'category': category,
      'imageUrl': imageUrl ?? "",
    });
  }

  Future<void> _updateProduct(
    String id,
    String name,
    String price,
    String category,
    String? imageUrl,
  ) async {
    await products.doc(id).update({
      'name': name,
      'price': int.tryParse(price) ?? 0,
      'category': category,
      'imageUrl': imageUrl ?? "",
    });
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Bạn chắc chắn muốn xoá?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng", style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () async {
                await _deleteProduct(id);
                Navigator.pop(context);
              },
              child: const Text("Xoá", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(String id) async {
    await products.doc(id).delete();
  }
}
