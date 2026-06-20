import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:situkang_app/core/constants/api_endpoints.dart';
import 'package:situkang_app/core/network/api_client.dart';
import 'package:situkang_app/features/worker_home/data/datasources/worker_home_remote_data_source.dart';
import 'package:situkang_app/features/worker_home/data/models/worker_dashboard_model.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late WorkerHomeRemoteDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = WorkerHomeRemoteDataSourceImpl(mockApiClient);
  });

  group('getDashboardData', () {
    final now = DateTime.now();
    final todayStr = now.subtract(const Duration(hours: 2)).toIso8601String();
    final thisWeekStr = now.subtract(const Duration(days: 4)).toIso8601String();
    final thisMonthStr = now.subtract(const Duration(days: 15)).toIso8601String();
    final oldStr = now.subtract(const Duration(days: 45)).toIso8601String();

    final tHomeResponseData = {
      'status': 'success',
      'message': 'Success',
      'data': {
        'worker_summary': {
          'balance': 150000,
          'rating': 4.8,
          'completed_jobs': 25,
          'is_available': true,
        },
        'incoming_orders_count': 3,
      }
    };

    test('should fetch dashboard data and calculate dynamic earnings correctly', () async {
      // Arrange
      final tOrdersResponseData = {
        'status': 'success',
        'data': [
          // Order 1: Completed today, price: 100000 (total_price)
          {
            'id': 'order-1',
            'order_number': 'ORD-001',
            'title': 'Pipa Bocor',
            'status': 'completed',
            'completed_at': todayStr,
            'total_price': 100000,
          },
          // Order 2: Paid this week, price: 200000 (grand_total fallback)
          {
            'id': 'order-2',
            'order_number': 'ORD-002',
            'title': 'Pasang Wastafel',
            'status': 'paid',
            'completed_at': thisWeekStr,
            'grand_total': 200000,
          },
          // Order 3: Completed this month, price: 300000 (estimated_base_price fallback)
          {
            'id': 'order-3',
            'order_number': 'ORD-003',
            'title': 'Instalasi AC',
            'status': 'completed',
            'completed_at': thisMonthStr,
            'estimated_base_price': 300000,
          },
          // Order 4: Completed long ago, price: 400000
          {
            'id': 'order-4',
            'order_number': 'ORD-004',
            'title': 'Pengecatan Tembok',
            'status': 'completed',
            'completed_at': oldStr,
            'total_price': 400000,
          },
          // Order 5: Cancelled today (should not count)
          {
            'id': 'order-5',
            'order_number': 'ORD-005',
            'title': 'Perbaikan Genteng',
            'status': 'cancelled',
            'completed_at': todayStr,
            'total_price': 500000,
          },
          // Order 6: Completed today but completed_at is null (should not count)
          {
            'id': 'order-6',
            'order_number': 'ORD-006',
            'title': 'Bongkar Pasang Keramik',
            'status': 'completed',
            'completed_at': null,
            'total_price': 600000,
          },
        ]
      };

      when(() => mockApiClient.get<Map<String, dynamic>>(ApiEndpoints.workerHome))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: ApiEndpoints.workerHome),
                statusCode: 200,
                data: tHomeResponseData,
              ));

      when(() => mockApiClient.get<Map<String, dynamic>>('/worker/orders', queryParams: {'per_page': 100}))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/worker/orders'),
                statusCode: 200,
                data: tOrdersResponseData,
              ));

      // Act
      final result = await dataSource.getDashboardData();

      // Assert
      expect(result, isA<WorkerDashboardModel>());
      // Earnings today: Order 1 = 100000
      expect(result.earningsToday, 100000);
      // Earnings week: Order 1 (100000) + Order 2 (200000) = 300000
      expect(result.earningsWeek, 300000);
      // Earnings month: Order 1 (100000) + Order 2 (200000) + Order 3 (300000) = 600000
      expect(result.earningsMonth, 600000);

      // Verify other dashboard metrics
      expect(result.walletBalance, 150000);
      expect(result.averageRating, 4.8);
      expect(result.jobsCompleted, 25);
      expect(result.incomingOrderCount, 3);
      expect(result.isAvailable, true);

      verify(() => mockApiClient.get<Map<String, dynamic>>(ApiEndpoints.workerHome)).called(1);
      verify(() => mockApiClient.get<Map<String, dynamic>>('/worker/orders', queryParams: {'per_page': 100})).called(1);
    });
  });

  group('toggleAvailability', () {
    test('should call patch and return availability status', () async {
      // Arrange
      final tResponse = {
        'status': 'success',
        'data': {
          'is_available': true,
        }
      };

      when(() => mockApiClient.patch<Map<String, dynamic>>(
            ApiEndpoints.workerAvailability,
            data: {'is_available': true},
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiEndpoints.workerAvailability),
            statusCode: 200,
            data: tResponse,
          ));

      // Act
      final result = await dataSource.toggleAvailability(isAvailable: true);

      // Assert
      expect(result, true);
      verify(() => mockApiClient.patch<Map<String, dynamic>>(
            ApiEndpoints.workerAvailability,
            data: {'is_available': true},
          )).called(1);
    });
  });
}
