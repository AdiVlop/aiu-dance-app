class SupabaseConfig {
  // Test configuration with a working Supabase project
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  
  // Fallback configuration for demo purposes
  static const String fallbackUrl = 'https://demo.supabase.co';
  static const String fallbackAnonKey = 'demo-key';
  
  // Check if we should use fallback configuration
  static bool get useFallback => supabaseUrl.contains('your-project-id');
  
  // Get the appropriate URL and key
  static String get effectiveUrl => useFallback ? fallbackUrl : supabaseUrl;
  static String get effectiveAnonKey => useFallback ? fallbackAnonKey : supabaseAnonKey;
}








