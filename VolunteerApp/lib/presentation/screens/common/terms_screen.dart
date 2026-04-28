import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.canPop() ? context.pop() : context.go('/register'),
        ),
        title: const Text(
          'Điều khoản sử dụng',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D6EFD), Color(0xFF0D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Điều khoản sử dụng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cập nhật lần cuối: ${DateTime.now().toLocal().day}/${DateTime.now().toLocal().month}/${DateTime.now().toLocal().year}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 1
            _buildSection(
              context,
              number: '1',
              title: 'Giới thiệu',
              content:
                  'Chào mừng bạn đến với VMS-AI. Bằng việc truy cập và sử dụng nền tảng của chúng tôi, bạn đồng ý tuân thủ các Điều khoản sử dụng này. Vui lòng đọc kỹ trước khi sử dụng dịch vụ.',
              color: const Color(0xFF0D6EFD),
            ),
            const SizedBox(height: 20),

            // Section 2
            _buildSectionWithList(
              context,
              number: '2',
              title: 'Tài khoản người dùng',
              color: const Color(0xFF0D6EFD),
              items: [
                'Bạn phải cung cấp thông tin chính xác, đầy đủ khi đăng ký tài khoản.',
                'Bạn chịu trách nhiệm bảo mật thông tin đăng nhập của mình.',
                'Không được chia sẻ tài khoản hoặc sử dụng tài khoản của người khác.',
                'Ban quản trị có quyền đình chỉ hoặc xóa tài khoản nếu phát hiện vi phạm.',
              ],
            ),
            const SizedBox(height: 20),

            // Section 3
            _buildSectionWithList(
              context,
              number: '3',
              title: 'Trách nhiệm của Tình nguyện viên',
              color: const Color(0xFF0D6EFD),
              items: [
                'Tuân thủ các quy định, hướng dẫn của Kiểm duyệt viên trong mỗi chiến dịch.',
                'Tham gia đầy đủ và có trách nhiệm với các hoạt động đã đăng ký.',
                'Giữ gìn hình ảnh, uy tín của tổ chức và cộng đồng tình nguyện.',
                'Thông báo trước nếu không thể tham gia chiến dịch đã đăng ký.',
              ],
            ),
            const SizedBox(height: 20),

            // Section 4
            _buildSection(
              context,
              number: '4',
              title: 'Quyền sở hữu trí tuệ',
              content:
                  'Toàn bộ nội dung, hình ảnh, mã nguồn và dữ liệu trên hệ thống VMS-AI thuộc quyền sở hữu của chúng tôi. Việc sao chép, phân phối hoặc sử dụng trái phép đều bị nghiêm cấm.',
              color: const Color(0xFF0D6EFD),
            ),
            const SizedBox(height: 20),

            // Section 5
            _buildSection(
              context,
              number: '5',
              title: 'Thay đổi điều khoản',
              content:
                  'Chúng tôi có quyền cập nhật và thay đổi các Điều khoản này bất kỳ lúc nào. Những thay đổi sẽ có hiệu lực ngay khi được đăng tải trên hệ thống. Tiếp tục sử dụng dịch vụ đồng nghĩa với việc bạn chấp nhận các điều khoản sửa đổi.',
              color: const Color(0xFF0D6EFD),
            ),
            const SizedBox(height: 32),

            // Bottom Navigation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/register'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Đăng ký'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF0D6EFD)),
                        foregroundColor: const Color(0xFF0D6EFD),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => context.go('/'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.grey[600],
                      ),
                      child: const Text('Về Trang chủ'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String number,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212529),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWithList(
    BuildContext context, {
    required String number,
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212529),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
