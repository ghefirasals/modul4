import 'package:get/get.dart';
import '../controllers/network_location_controller.dart';
import '../services/location_service.dart';

/// Binding untuk Network Location Module
/// Menginisialisasi NetworkLocationController dan LocationService
class NetworkLocationBinding extends Bindings {
  @override
  void dependencies() {
    // Register LocationService sebagai singleton
    Get.lazyPut<LocationService>(() => LocationService(), fenix: true);

    // Register NetworkLocationController
    Get.lazyPut<NetworkLocationController>(
      () => NetworkLocationController(),
      fenix: true,
    );
  }
}