// ============================================================
//  SERVICE: BmiService
//  Chịu trách nhiệm giao tiếp với Firebase Firestore.
//  Tách biệt hoàn toàn logic lưu/đọc dữ liệu khỏi UI.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../user/bmi_record.dart';

class BmiService {
  // ── Firebase instances ─────────────────────────────────────
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Helper: lấy user hiện tại ─────────────────────────────
  User? get currentUser => _auth.currentUser;

  // ── Lấy reference collection của user ─────────────────────
  CollectionReference<Map<String, dynamic>> _userRecords(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('health_records');
  }

  // ── Lưu một bản ghi lên Firestore ─────────────────────────
  /// Trả về Future<void>, ném Exception nếu chưa đăng nhập
  Future<void> saveRecord(BmiRecord record) async {
    final user = currentUser;
    if (user == null) throw Exception('User not signed in');

    // Dùng serverTimestamp thay vì timestamp client để đảm bảo đồng bộ
    final map = record.toMap();
    map['timestamp'] = FieldValue.serverTimestamp();

    await _userRecords(user.uid).add(map);
  }

  // ── Stream danh sách bản ghi (realtime) ───────────────────
  /// Trả về null nếu user chưa đăng nhập
  Stream<List<BmiRecord>>? getRecordsStream() {
    final user = currentUser;
    if (user == null) return null;

    return _userRecords(user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final ts = data['timestamp'] as Timestamp?;
        final date = ts?.toDate() ?? DateTime.now();
        return BmiRecord.fromMap(data, date);
      }).toList();
    });
  }
}
