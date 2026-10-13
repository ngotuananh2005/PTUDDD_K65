/// Cấu hình kết nối Supabase (URL & Anon Key)
///
/// HƯỚNG DẪN CẤU HÌNH SUPABASE:
/// 1. Vào https://supabase.com/dashboard và tạo dự án mới (hoặc chọn dự án có sẵn).
/// 2. Vào Project Settings -> API.
/// 3. Sao chép "Project URL" và dán vào supabaseUrl dưới đây.
/// 4. Sao chép "anon public" key và dán vào supabaseAnonKey dưới đây.
/// 5. Chạy mã SQL trong file supabase/schema.sql vào SQL Editor trên Supabase Dashboard.
class SupabaseOptions {
  static const String supabaseUrl = 'https://anpdhzpefablqecqysuz.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_DDtmE_9sq-Z4OrEYqzB-Yg_taPAe34F';

  /// Kiểm tra xem Supabase đã được cấu hình khóa thật hay chưa
  /// Trả về true nếu KHÔNG dùng placeholder mặc định và URL hợp lệ
  static bool get isConfigured =>
      supabaseUrl != 'https://your-project-id.supabase.co' &&
      supabaseAnonKey != 'your-anon-key-placeholder-here' &&
      supabaseUrl.startsWith('https://');
}
