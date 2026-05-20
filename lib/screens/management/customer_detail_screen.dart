import 'package:defsystem/core/theme/app_colors.dart';
import 'package:defsystem/core/theme/app_spacing.dart';
import 'package:defsystem/screens/shared/buttons/app_back_button.dart';
import 'package:defsystem/screens/shared/components/app_card.dart';
import 'package:defsystem/screens/shared/components/date_time_header.dart';
import 'package:defsystem/screens/shared/status/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerID;
  final String customerName;

  const CustomerDetailScreen({
    super.key,
    required this.customerID,
    required this.customerName,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _customer;
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    Map<String, dynamic>? customerData;
    List<Map<String, dynamic>> deliveryData = [];

    try {
      final customerResponse = await _supabase
          .from('customer')
          .select()
          .eq('customerid', widget.customerID)
          .maybeSingle();

      if (customerResponse != null) {
        customerData = Map<String, dynamic>.from(customerResponse);
      }
    } catch (e) {
      debugPrint('LOAD CUSTOMER INFO ERROR: $e');
    }

    try {
      final deliveriesResponse = await _supabase
          .from('delivery_request')
          .select('''
            *,
            customer(*),
            delivery_status(*),
            dispatcher:staff_profiles!delivery_request_dispatcher_id_fkey(*),
            delivery_assignment(
              *,
              rider:staff_profiles!delivery_assignment_rider_id_fkey(*),
              assignment_dispatcher:staff_profiles!delivery_assignment_dispatcher_id_fkey(*)
            )
          ''')
          .eq('customerid', widget.customerID)
          .order('requestdatetime', ascending: false);

      deliveryData = List<Map<String, dynamic>>.from(deliveriesResponse);
    } catch (e) {
      debugPrint('LOAD CUSTOMER DELIVERIES JOIN ERROR: $e');

      try {
        final fallbackDeliveries = await _supabase
            .from('delivery_request')
            .select('''
              *,
              customer(*),
              delivery_status(*),
              delivery_assignment(*)
            ''')
            .eq('customerid', widget.customerID)
            .order('requestdatetime', ascending: false);

        deliveryData = List<Map<String, dynamic>>.from(fallbackDeliveries);
      } catch (fallbackError) {
        debugPrint('LOAD CUSTOMER DELIVERIES FALLBACK ERROR: $fallbackError');

        try {
          final simpleDeliveries = await _supabase
              .from('delivery_request')
              .select()
              .eq('customerid', widget.customerID)
              .order('requestdatetime', ascending: false);

          deliveryData = List<Map<String, dynamic>>.from(simpleDeliveries);
        } catch (simpleError) {
          debugPrint('LOAD SIMPLE DELIVERIES ERROR: $simpleError');
        }
      }
    }

    deliveryData = await _hydrateDeliveryRecords(deliveryData);

    if (customerData == null && deliveryData.isNotEmpty) {
      customerData = _nestedMap(deliveryData.first['customer']);
    }

    if (!mounted) return;

    setState(() {
      _customer = customerData;
      _deliveries = deliveryData;
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _hydrateDeliveryRecords(
      List<Map<String, dynamic>> records,
      ) async {
    final hydrated = <Map<String, dynamic>>[];

    for (final record in records) {
      final updated = Map<String, dynamic>.from(record);

      Map<String, dynamic>? assignment = _latestAssignment(updated);

      if (assignment == null) {
        assignment = await _loadAssignmentForDelivery(updated);

        if (assignment != null) {
          updated['delivery_assignment'] = [assignment];
        }
      }

      if (assignment != null) {
        final cleanAssignment = Map<String, dynamic>.from(assignment);

        final joinedRider = _nestedMap(cleanAssignment['rider']);
        if (joinedRider == null) {
          final rider = await _loadStaffProfile(
            _firstValue(cleanAssignment, ['rider_id', 'riderid']),
          );

          if (rider != null) {
            cleanAssignment['rider'] = rider;
          }
        }

        final joinedAssignmentDispatcher =
        _nestedMap(cleanAssignment['assignment_dispatcher']);

        if (joinedAssignmentDispatcher == null) {
          final assignmentDispatcher = await _loadStaffProfile(
            _firstValue(cleanAssignment, ['dispatcher_id', 'dispatcherid']),
          );

          if (assignmentDispatcher != null) {
            cleanAssignment['assignment_dispatcher'] = assignmentDispatcher;
          }
        }

        updated['delivery_assignment'] = [cleanAssignment];
      }

      final joinedDeliveryDispatcher = _nestedMap(updated['dispatcher']);
      if (joinedDeliveryDispatcher == null) {
        final dispatcher = await _loadStaffProfile(
          _firstValue(updated, ['dispatcher_id', 'dispatcherid']),
        );

        if (dispatcher != null) {
          updated['dispatcher'] = dispatcher;
        }
      }

      hydrated.add(updated);
    }

    return hydrated;
  }

  Future<Map<String, dynamic>?> _loadAssignmentForDelivery(
      Map<String, dynamic> delivery,
      ) async {
    final requestID = _firstValue(delivery, ['requestid', 'request_id']);

    if (requestID == null) return null;

    try {
      final response = await _supabase
          .from('delivery_assignment')
          .select('''
            *,
            rider:staff_profiles!delivery_assignment_rider_id_fkey(*),
            assignment_dispatcher:staff_profiles!delivery_assignment_dispatcher_id_fkey(*)
          ''')
          .eq('requestid', requestID)
          .order('assignmentdatetime', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('LOAD ASSIGNMENT JOIN ERROR: $e');

      try {
        final fallback = await _supabase
            .from('delivery_assignment')
            .select()
            .eq('requestid', requestID)
            .order('assignmentdatetime', ascending: false)
            .limit(1)
            .maybeSingle();

        if (fallback == null) return null;
        return Map<String, dynamic>.from(fallback);
      } catch (fallbackError) {
        debugPrint('LOAD ASSIGNMENT FALLBACK ERROR: $fallbackError');
        return null;
      }
    }
  }

  Future<Map<String, dynamic>?> _loadStaffProfile(String? staffID) async {
    if (staffID == null || staffID.trim().isEmpty) return null;

    try {
      final response = await _supabase
          .from('staff_profiles')
          .select()
          .eq('id', staffID)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('LOAD STAFF PROFILE ERROR [$staffID]: $e');
      return null;
    }
  }

  String? _firstValue(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;

    for (final key in keys) {
      final value = source[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return null;
  }

  Map<String, dynamic>? _nestedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is List && value.isNotEmpty) {
      final first = value.first;

      if (first is Map<String, dynamic>) return first;

      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    return null;
  }

  Map<String, dynamic>? _latestAssignment(Map<String, dynamic> delivery) {
    final assignment = delivery['delivery_assignment'];

    if (assignment is List) {
      if (assignment.isEmpty) return null;

      final first = assignment.first;

      if (first is Map<String, dynamic>) return first;

      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }

      return null;
    }

    if (assignment is Map<String, dynamic>) return assignment;

    if (assignment is Map) {
      return Map<String, dynamic>.from(assignment);
    }

    return null;
  }

  String _formatDateTime(dynamic dateValue) {
    if (dateValue == null || dateValue.toString().trim().isEmpty) {
      return 'N/A';
    }

    try {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(
        DateTime.parse(dateValue.toString()).toLocal(),
      );
    } catch (_) {
      return 'N/A';
    }
  }

  String _safeText(dynamic value, {String fallback = 'N/A'}) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  String _customerFullName() {
    Map<String, dynamic>? source = _customer;

    if (source == null && _deliveries.isNotEmpty) {
      source = _nestedMap(_deliveries.first['customer']);
    }

    if (source == null) return widget.customerName;

    final parts = [
      source['custfname'],
      source['custmname'],
      source['custlname'],
    ].where((value) {
      return value != null && value.toString().trim().isNotEmpty;
    }).toList();

    if (parts.isEmpty) return widget.customerName;
    return parts.join(' ');
  }

  String _customerIDDisplay() {
    return _customer?['customerid']?.toString() ??
        (_deliveries.isNotEmpty
            ? _deliveries.first['customerid']?.toString()
            : null) ??
        widget.customerID;
  }

  String _customerContact() {
    return _customer?['contactnumber']?.toString() ?? 'N/A';
  }

  String _customerEmail() {
    return _customer?['email']?.toString() ?? 'N/A';
  }

  String _customerAddress() {
    return _customer?['address']?.toString() ?? 'N/A';
  }

  String _personName(Map<String, dynamic>? person, String fallback) {
    if (person == null) return fallback;

    final parts = [
      person['first_name'],
      person['middle_name'],
      person['last_name'],
    ].where((value) {
      return value != null && value.toString().trim().isNotEmpty;
    }).toList();

    if (parts.isNotEmpty) return parts.join(' ');

    return person['name']?.toString() ??
        person['full_name']?.toString() ??
        fallback;
  }

  String _dispatcherName(Map<String, dynamic>? dispatcher) {
    return _personName(dispatcher, 'N/A');
  }

  String _riderName(Map<String, dynamic>? rider) {
    return _personName(rider, 'Not assigned');
  }

  String _statusName(Map<String, dynamic> delivery) {
    final joinedStatus = delivery['delivery_status']?['statusname'];

    if (joinedStatus != null && joinedStatus.toString().trim().isNotEmpty) {
      return joinedStatus.toString();
    }

    final statusID = delivery['statusid']?.toString();

    switch (statusID) {
      case '1':
        return 'Pending';
      case '2':
        return 'Assigned';
      case '3':
        return 'In Transit';
      case '4':
        return 'Completed';
      case '5':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  int _countByStatus(List<String> statuses) {
    return _deliveries.where((delivery) {
      final statusName = _statusName(delivery).trim().toLowerCase();
      final statusID = delivery['statusid']?.toString().trim();

      if (statuses.contains(statusName)) return true;

      if (statuses.contains('in transit') && statusName == 'in-transit') {
        return true;
      }

      if (statuses.contains('in-transit') && statusName == 'in transit') {
        return true;
      }

      if (statuses.contains('completed') && statusName == 'delivered') {
        return true;
      }

      if (statuses.contains('delivered') && statusName == 'completed') {
        return true;
      }

      if (statuses.contains('cancelled') && statusName == 'canceled') {
        return true;
      }

      if (statuses.contains('canceled') && statusName == 'cancelled') {
        return true;
      }

      if (statusID == null || statusID.isEmpty) return false;

      if (statuses.contains('pending') && statusID == '1') return true;
      if (statuses.contains('assigned') && statusID == '2') return true;

      if ((statuses.contains('in transit') ||
          statuses.contains('in-transit')) &&
          statusID == '3') {
        return true;
      }

      if ((statuses.contains('completed') || statuses.contains('delivered')) &&
          statusID == '4') {
        return true;
      }

      if ((statuses.contains('cancelled') || statuses.contains('canceled')) &&
          statusID == '5') {
        return true;
      }

      return false;
    }).length;
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();

    if (normalized == 'pending') return AppColors.pending;
    if (normalized == 'assigned') return AppColors.assigned;

    if (normalized == 'in-transit' || normalized == 'in transit') {
      return AppColors.inTransit;
    }

    if (normalized == 'completed' || normalized == 'delivered') {
      return AppColors.completed;
    }

    if (normalized == 'cancelled' || normalized == 'canceled') {
      return AppColors.cancelled;
    }

    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 760;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 32,
                isMobile ? 18 : 32,
                isMobile ? 16 : 32,
                isMobile ? 110 : 32,
              ),
              child: _isLoading
                  ? SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(isMobile),
                  SizedBox(height: isMobile ? 18 : 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AppBackButton(label: 'Back to Customers'),
                  ),
                  SizedBox(height: isMobile ? 14 : 18),
                  _buildCustomerProfile(isMobile),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildSummaryStats(isMobile),
                  SizedBox(height: isMobile ? 18 : 24),
                  _buildDeliveryHistoryHeader(),
                  const SizedBox(height: 14),
                  if (_deliveries.isEmpty)
                    _buildEmptyState()
                  else
                    _buildDeliveryList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    final name = _customerFullName();

    if (isMobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.20),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _HeaderIcon(icon: Icons.person_outline_rounded),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Customer Details',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const DateTimeHeader(compact: true),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              name,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Review customer profile, contact information, and delivery history.',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _HeaderStatPill(
                    icon: Icons.inventory_2_outlined,
                    label: 'Deliveries',
                    value: '${_deliveries.length}',
                  ),
                  const SizedBox(width: 10),
                  _HeaderStatPill(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Completed',
                    value: '${_countByStatus(['completed', 'delivered'])}',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const _HeaderIcon(
            icon: Icons.person_outline_rounded,
            large: true,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Review customer profile, contact information, and delivery history.',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _HeaderStatPill(
                        icon: Icons.inventory_2_outlined,
                        label: 'Deliveries',
                        value: '${_deliveries.length}',
                      ),
                      const SizedBox(width: 10),
                      _HeaderStatPill(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Completed',
                        value:
                        '${_countByStatus(['completed', 'delivered'])}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const DateTimeHeader(),
        ],
      ),
    );
  }

  Widget _buildCustomerProfile(bool isMobile) {
    final name = _customerFullName();

    final profileInfo = [
      _ProfileInfo(
        icon: Icons.phone_outlined,
        label: 'Contact Number',
        value: _customerContact(),
        color: AppColors.completed,
      ),
      _ProfileInfo(
        icon: Icons.email_outlined,
        label: 'Email',
        value: _customerEmail(),
        color: AppColors.assigned,
      ),
      _ProfileInfo(
        icon: Icons.location_on_outlined,
        label: 'Address',
        value: _customerAddress(),
        color: AppColors.inTransit,
      ),
      _ProfileInfo(
        icon: Icons.inventory_2_outlined,
        label: 'Total Deliveries',
        value: '${_deliveries.length}',
        color: AppColors.primary,
      ),
    ];

    return AppCard(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  _initial(name),
                  style: const TextStyle(
                    fontSize: 26,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Customer ID: ${_customerIDDisplay()}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
              : Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  _initial(name),
                  style: const TextStyle(
                    fontSize: 26,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Customer ID: ${_customerIDDisplay()}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(profileInfo.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == profileInfo.length - 1 ? 0 : 12,
                    ),
                    child: _InfoBox(
                      icon: profileInfo[index].icon,
                      label: profileInfo[index].label,
                      value: profileInfo[index].value,
                      color: profileInfo[index].color,
                      width: isMobile ? 250 : 280,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(bool isMobile) {
    final stats = [
      _SummaryStat(
        label: 'Total',
        value: '${_deliveries.length}',
        icon: Icons.inventory_2_outlined,
        color: AppColors.primary,
      ),
      _SummaryStat(
        label: 'Pending',
        value: '${_countByStatus(['pending'])}',
        icon: Icons.access_time_rounded,
        color: AppColors.pending,
      ),
      _SummaryStat(
        label: 'Assigned',
        value: '${_countByStatus(['assigned'])}',
        icon: Icons.assignment_ind_outlined,
        color: AppColors.assigned,
      ),
      _SummaryStat(
        label: 'In Transit',
        value: '${_countByStatus(['in transit', 'in-transit'])}',
        icon: Icons.local_shipping_outlined,
        color: AppColors.inTransit,
      ),
      _SummaryStat(
        label: 'Completed',
        value: '${_countByStatus(['completed', 'delivered'])}',
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.completed,
      ),
      _SummaryStat(
        label: 'Cancelled',
        value: '${_countByStatus(['cancelled', 'canceled'])}',
        icon: Icons.cancel_outlined,
        color: AppColors.cancelled,
      ),
    ];

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(stats.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index == stats.length - 1 ? 0 : 12,
              ),
              child: _SummaryStatCard(
                stat: stats[index],
                width: isMobile ? 210 : 230,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDeliveryHistoryHeader() {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery History',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'All recorded deliveries linked to this customer.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryList() {
    return Column(
      children: _deliveries.map((delivery) {
        return _buildDeliveryCard(delivery);
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return AppCard(
      padding: const EdgeInsets.all(36),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 54,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'No deliveries found',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'This customer has no recorded delivery request yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final status = _statusName(delivery);
    final statusColor = _statusColor(status);

    final assignment = _latestAssignment(delivery);

    final dispatcher = _nestedMap(delivery['dispatcher']) ??
        _nestedMap(assignment?['assignment_dispatcher']);

    final rider = _nestedMap(assignment?['rider']);

    final assignedAt = _firstValue(
      assignment,
      [
        'assignmentdatetime',
        'assigneddatetime',
        'assigned_at',
        'created_at',
      ],
    );

    final completedAt = _firstValue(
      assignment,
      [
        'completeddatetime',
        'completed_datetime',
        'completed_at',
        'delivered_at',
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLg),
                  topRight: Radius.circular(AppSpacing.radiusLg),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: statusColor.withValues(alpha: 0.14),
                  ),
                ),
              ),
              child: Row(
                children: [
                  _StatusIcon(status: status),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery['requestid']?.toString() ?? 'N/A',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Requested: ${_formatDateTime(delivery['requestdatetime'])}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: status, large: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailBox(
                    icon: Icons.inventory_2_outlined,
                    label: 'Item',
                    value: _safeText(delivery['itemdescription']),
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  _DetailBox(
                    icon: Icons.location_on_outlined,
                    label: 'Pickup',
                    value: _safeText(delivery['pickupaddress']),
                    color: AppColors.completed,
                  ),
                  const SizedBox(height: 10),
                  _DetailBox(
                    icon: Icons.flag_outlined,
                    label: 'Delivery',
                    value: _safeText(delivery['deliveryaddress']),
                    color: AppColors.assigned,
                  ),
                  const SizedBox(height: 10),
                  _DetailBox(
                    icon: Icons.headset_mic_outlined,
                    label: 'Dispatcher',
                    value: _dispatcherName(dispatcher),
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 10),
                  _DetailBox(
                    icon: Icons.directions_bike_outlined,
                    label: 'Rider',
                    value: _riderName(rider),
                    color: AppColors.inTransit,
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: [
                      _TimelineBox(
                        icon: Icons.edit_calendar_outlined,
                        label: 'Requested',
                        value: _formatDateTime(delivery['requestdatetime']),
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      _TimelineBox(
                        icon: Icons.assignment_turned_in_outlined,
                        label: 'Assigned',
                        value: _formatDateTime(assignedAt),
                        color: AppColors.assigned,
                      ),
                      const SizedBox(height: 10),
                      _TimelineBox(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Completed',
                        value: _formatDateTime(completedAt),
                        color: AppColors.completed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfo {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final bool large;

  const _HeaderIcon({
    required this.icon,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: large ? 54 : 44,
      width: large ? 54 : 44,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(
          large ? AppSpacing.radiusLg : AppSpacing.radiusMd,
        ),
      ),
      child: Icon(
        icon,
        color: AppColors.white,
        size: large ? 28 : 23,
      ),
    );
  }
}

class _HeaderStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderStatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.white,
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _SummaryStatCard extends StatelessWidget {
  final _SummaryStat stat;
  final double width;

  const _SummaryStatCard({
    required this.stat,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 112,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              stat.icon,
              color: stat.color,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  style: TextStyle(
                    color: stat.color,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  stat.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double width;

  const _InfoBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 104,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;

  const _StatusIcon({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final Color iconColor;
    final Color bgColor;

    if (normalized == 'pending') {
      iconColor = AppColors.pending;
      bgColor = AppColors.pendingBg;
    } else if (normalized == 'assigned') {
      iconColor = AppColors.assigned;
      bgColor = AppColors.assignedBg;
    } else if (normalized == 'in-transit' || normalized == 'in transit') {
      iconColor = AppColors.inTransit;
      bgColor = AppColors.inTransitBg;
    } else if (normalized == 'completed' || normalized == 'delivered') {
      iconColor = AppColors.completed;
      bgColor = AppColors.completedBg;
    } else if (normalized == 'cancelled' || normalized == 'canceled') {
      iconColor = AppColors.cancelled;
      bgColor = AppColors.cancelledBg;
    } else {
      iconColor = AppColors.primary;
      bgColor = AppColors.primaryLight;
    }

    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.16),
        ),
      ),
      child: Icon(
        Icons.receipt_long_outlined,
        color: iconColor,
        size: 22,
      ),
    );
  }
}

class _DetailBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TimelineBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}