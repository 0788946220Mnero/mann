import '../../core/models/app_user.dart';
import '../../core/models/order_status.dart';

/// صلاحيات التطبيق. مبنية على أدوار الـ Backend الحالية،
/// ومطابقة لما يسمح به الخادم فعلياً (authorize في المسارات).
enum Permission {
  viewOrders,
  acceptOrder,
  changeOrderStatus,
  cancelOrder,
  viewSales,
  manageUsers,
  manageSettings,
  manageContent,
  toggleRestaurantStatus,
  closeShift,
  chat,
  // صلاحيات التوصيل
  viewDeliverySettings,
  editDeliverySettings,
  viewCustomerLocation,
}

class PermissionService {
  static const Map<UserRole, Set<Permission>> _matrix = {
    UserRole.admin: {
      Permission.viewOrders, Permission.acceptOrder, Permission.changeOrderStatus,
      Permission.cancelOrder, Permission.viewSales, Permission.manageUsers,
      Permission.manageSettings, Permission.manageContent,
      Permission.toggleRestaurantStatus, Permission.closeShift, Permission.chat,
      Permission.viewDeliverySettings, Permission.editDeliverySettings,
      Permission.viewCustomerLocation,
    },
    UserRole.manager: {
      Permission.viewOrders, Permission.acceptOrder, Permission.changeOrderStatus,
      Permission.cancelOrder, Permission.viewSales, Permission.manageContent,
      Permission.toggleRestaurantStatus, Permission.closeShift, Permission.chat,
      Permission.viewDeliverySettings, Permission.editDeliverySettings,
      Permission.viewCustomerLocation,
    },
    UserRole.cashier: {
      Permission.viewOrders, Permission.acceptOrder, Permission.changeOrderStatus,
      Permission.cancelOrder, Permission.toggleRestaurantStatus, Permission.chat,
      Permission.viewCustomerLocation,
    },
    // موظف المطبخ: يرى الطلبات ويحرّكها بين التحضير والجاهز فقط
    UserRole.employee: {
      Permission.viewOrders, Permission.changeOrderStatus, Permission.chat,
    },
  };

  static bool can(AppUser? user, Permission p) {
    if (user == null) return false;
    return _matrix[user.role]?.contains(p) ?? false;
  }

  /// الحالات التي يُسمح لهذا المستخدم بنقل الطلب إليها.
  static List<OrderStatus> allowedTransitions(AppUser? user, OrderStatus current) {
    if (user == null) return const [];

    // المطبخ: التحضير والجاهز فقط
    if (user.role == UserRole.employee) {
      switch (current) {
        case OrderStatus.newOrder: return [OrderStatus.preparing];
        case OrderStatus.preparing: return [OrderStatus.ready];
        default: return const [];
      }
    }

    switch (current) {
      case OrderStatus.pending:
        return [OrderStatus.newOrder, OrderStatus.cancelled];
      case OrderStatus.newOrder:
        return [OrderStatus.preparing, OrderStatus.cancelled];
      case OrderStatus.preparing:
        return [OrderStatus.ready, OrderStatus.cancelled];
      case OrderStatus.ready:
        return [OrderStatus.outForDelivery, OrderStatus.delivered, OrderStatus.cancelled];
      case OrderStatus.outForDelivery:
        return [OrderStatus.delivered, OrderStatus.cancelled];
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return const [];
    }
  }
}
