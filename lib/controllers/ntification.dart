import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Notification Types Enum
enum NotificationType {
  requestAccepted,
  requestDeclined,
  paymentRequired,
  paymentConfirmed,
  bookingDeleted,
  meetingLink,
  reminder,
  system,
  chat
}

// Notification Priority Enum
enum NotificationPriority { low, normal, high, urgent }

// Notification Model
class NotificationModel {
  final String? id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data; // Additional data (chatId, bookingId, etc.)
  final String? actionUrl; // Deep link or route
  final DateTime? expiresAt; // Auto-delete after this time

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.actionUrl,
    this.expiresAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'data': data,
      'actionUrl': actionUrl,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'],
      title: data['title'],
      message: data['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      data: data['data'],
      actionUrl: data['actionUrl'],
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }
}

// Notification Service Class
class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  // Create a new notification
  static Future<String> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    String? actionUrl,
    DateTime? expiresAt,
  }) async {
    final notification = NotificationModel(
      userId: userId,
      title: title,
      message: message,
      type: type,
      priority: priority,
      timestamp: DateTime.now(),
      data: data,
      actionUrl: actionUrl,
      expiresAt: expiresAt,
    );

    final docRef = await _firestore
        .collection(_collection)
        .add(notification.toFirestore());

    // Update user's unread notification count
    await _incrementUserNotificationCount(userId, 1);

    return docRef.id;
  }

  // Get notifications for a specific user
  static Stream<List<NotificationModel>> getUserNotifications(
    String userId, {
    int limit = 50,
    bool unreadOnly = false,
  }) {
    Query query = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList());
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    final doc =
        await _firestore.collection(_collection).doc(notificationId).get();
    if (doc.exists) {
      final notification = NotificationModel.fromFirestore(doc);
      if (!notification.isRead) {
        await _firestore.collection(_collection).doc(notificationId).update({
          'isRead': true,
        });

        // Decrement user's unread count
        await _incrementUserNotificationCount(notification.userId, -1);
      }
    }
  }

  // Mark all notifications as read for a user
  static Future<void> markAllAsRead(String userId) async {
    final unreadNotifications = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    int unreadCount = 0;

    for (var doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
      unreadCount++;
    }

    if (unreadCount > 0) {
      await batch.commit();
      await _setUserNotificationCount(userId, 0);
    }
  }

  // Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    final doc =
        await _firestore.collection(_collection).doc(notificationId).get();
    if (doc.exists) {
      final notification = NotificationModel.fromFirestore(doc);
      await _firestore.collection(_collection).doc(notificationId).delete();

      // If it was unread, decrement user's unread count
      if (!notification.isRead) {
        await _incrementUserNotificationCount(notification.userId, -1);
      }
    }
  }

  // Delete all notifications for a user
  static Future<void> deleteAllUserNotifications(String userId) async {
    final notifications = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    if (notifications.docs.isNotEmpty) {
      await batch.commit();
      await _setUserNotificationCount(userId, 0);
    }
  }

  // Get unread notification count
  static Future<int> getUnreadCount(String userId) async {
    final unreadNotifications = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    return unreadNotifications.docs.length;
  }

  // Clean up expired notifications
  static Future<void> cleanupExpiredNotifications() async {
    final now = Timestamp.now();
    final expiredNotifications = await _firestore
        .collection(_collection)
        .where('expiresAt', isLessThan: now)
        .get();

    final batch = _firestore.batch();
    final userCounts = <String, int>{};

    for (var doc in expiredNotifications.docs) {
      final notification = NotificationModel.fromFirestore(doc);
      batch.delete(doc.reference);

      // Count unread notifications per user
      if (!notification.isRead) {
        userCounts[notification.userId] =
            (userCounts[notification.userId] ?? 0) + 1;
      }
    }

    if (expiredNotifications.docs.isNotEmpty) {
      await batch.commit();

      // Update user notification counts
      for (var entry in userCounts.entries) {
        await _incrementUserNotificationCount(entry.key, -entry.value);
      }
    }
  }

  // Helper method to safely increment user notification count
  static Future<void> _incrementUserNotificationCount(
      String userId, int increment) async {
    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final currentCount = data['unreadNotifications'] ?? 0;
        final newCount =
            (currentCount + increment).clamp(0, double.infinity).toInt();

        transaction.update(userRef, {
          'unreadNotifications': newCount,
        });
      } else {
        // Create user document with initial count
        transaction.set(
            userRef,
            {
              'unreadNotifications':
                  increment.clamp(0, double.infinity).toInt(),
            },
            SetOptions(merge: true));
      }
    });
  }

  // Helper method to set user notification count
  static Future<void> _setUserNotificationCount(
      String userId, int count) async {
    await _firestore.collection('users').doc(userId).set({
      'unreadNotifications': count.clamp(0, double.infinity).toInt(),
    }, SetOptions(merge: true));
  }

  // Predefined notification creators for common scenarios

  // Request accepted notification
  static Future<String> createRequestAcceptedNotification({
    required String userId,
    required String eventName,
    String? chatId,
  }) async {
    return createNotification(
      userId: userId,
      title: 'Request Accepted',
      message:
          'Your interpretation request for "$eventName" has been accepted.',
      type: NotificationType.requestAccepted,
      priority: NotificationPriority.high,
      data: {'eventName': eventName, 'chatId': chatId},
      actionUrl: chatId != null ? '/chat/$chatId' : null,
    );
  }

  // Payment required notification
  static Future<String> createPaymentRequiredNotification({
    required String userId,
    required String eventName,
    required String amount,
    String? chatId,
  }) async {
    return createNotification(
      userId: userId,
      title: 'Payment Required',
      message:
          'Your request for "$eventName" requires payment of UGX $amount. Check chat for payment details.',
      type: NotificationType.paymentRequired,
      priority: NotificationPriority.high,
      data: {
        'eventName': eventName,
        'amount': amount,
        'chatId': chatId,
      },
      actionUrl: chatId != null ? '/chat/$chatId' : null,
    );
  }

  // Payment confirmed notification
  static Future<String> createPaymentConfirmedNotification({
    required String userId,
    required String eventName,
    String? chatId,
  }) async {
    return createNotification(
      userId: userId,
      title: 'Payment Confirmed',
      message:
          'Your payment for "$eventName" has been confirmed. You will receive the meeting link soon.',
      type: NotificationType.paymentConfirmed,
      priority: NotificationPriority.high,
      data: {'eventName': eventName, 'chatId': chatId},
      actionUrl: chatId != null ? '/chat/$chatId' : null,
    );
  }

  // Request declined notification
  static Future<String> createRequestDeclinedNotification({
    required String userId,
    required String eventName,
  }) async {
    return createNotification(
      userId: userId,
      title: 'Request Declined',
      message:
          'Your interpretation request for "$eventName" has been declined.',
      type: NotificationType.requestDeclined,
      priority: NotificationPriority.normal,
      data: {'eventName': eventName},
    );
  }

  // Booking deleted notification
  static Future<String> createBookingDeletedNotification({
    required String userId,
    required String eventName,
  }) async {
    return createNotification(
      userId: userId,
      title: 'Booking Deleted',
      message:
          'Your interpretation request for "$eventName" has been deleted by the administrator.',
      type: NotificationType.bookingDeleted,
      priority: NotificationPriority.high,
      data: {'eventName': eventName},
    );
  }

  // Meeting link notification
  static Future<String> createMeetingLinkNotification({
    required String userId,
    required String eventName,
    required String meetingLink,
    DateTime? eventDate,
  }) async {
    return createNotification(
      userId: userId,
      title: 'Meeting Link Ready',
      message: 'Your meeting link for "$eventName" is ready. Tap to join.',
      type: NotificationType.meetingLink,
      priority: NotificationPriority.urgent,
      data: {
        'eventName': eventName,
        'meetingLink': meetingLink,
        'eventDate': eventDate?.toIso8601String(),
      },
      actionUrl: meetingLink,
    );
  }

  // Reminder notification
  static Future<String> createReminderNotification({
    required String userId,
    required String eventName,
    required DateTime eventDate,
    required String meetingLink,
    int minutesBefore = 15,
  }) async {
    return createNotification(
      userId: userId,
      title: 'Upcoming Meeting',
      message:
          'Your interpretation session "$eventName" starts in $minutesBefore minutes.',
      type: NotificationType.reminder,
      priority: NotificationPriority.urgent,
      data: {
        'eventName': eventName,
        'eventDate': eventDate.toIso8601String(),
        'meetingLink': meetingLink,
        'minutesBefore': minutesBefore,
      },
      actionUrl: meetingLink,
      expiresAt:
          eventDate.add(Duration(hours: 2)), // Auto-delete 2 hours after event
    );
  }
}
