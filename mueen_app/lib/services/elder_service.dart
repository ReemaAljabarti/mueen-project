import '../models/elder.dart';

/// خدمة إدارة بيانات كبار السن (stub — جميع البيانات الحقيقية تأتي من ApiService)
class ElderService {
  /// حذف كبير السن
  /// TODO: استبدل بـ API call: DELETE /api/elders/{id}
  Future<bool> deleteElder(int? id) async {
    if (id == null) return false;
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  /// جلب كبير السن بالمعرّف (stub)
  Future<Elder?> getElderById(int? id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return null;
  }
}
