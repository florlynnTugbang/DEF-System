class SupabaseConstants {
  static const String supabaseUrl =
      'https://pscmiopfkramzbonwfml.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzY21pb3Bma3JhbXpib253Zm1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwMTkzNzcsImV4cCI6MjA5MzU5NTM3N30.2_DGqQRUOg44JO7qlQOf5WoIaxnSGtF8NtjMv_GFkL4';

  static const String customerTable = 'customer';
  static const String dispatcherTable = 'dispatcher';
  static const String riderTable = 'rider';
  static const String adminTable = 'admin';
  static const String deliveryRequestTable = 'delivery_request';
  static const String deliveryAssignmentTable = 'delivery_assignment';
  static const String deliveryStatusTable = 'delivery_status';
  static const String staffProfilesTable = 'staff_profiles';

  // Single unified issues table — replaces both delivery_issue and customer_issue
  static const String deliveryIssueTable = 'delivery_issue';
}