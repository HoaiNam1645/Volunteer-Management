import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
          'Chính sách bảo mật',
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
                  colors: [Color(0xFF198754), Color(0xFF157347)],
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
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chính sách bảo mật',
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
            _buildSectionWithList(
              context,
              number: '1',
              title: 'Mục đích thu thập thông tin',
              intro:
                  'VMS-AI thu thập thông tin cá nhân của người dùng (bao gồm Họ tên, Số điện thoại, Email, Địa chỉ, Kỹ năng) nhằm mục đích:',
              color: const Color(0xFF198754),
              items: [
                'Quản lý hồ sơ Tình nguyện viên và Kiểm duyệt viên.',
                'Gợi ý các chiến dịch tình nguyện phù hợp với năng lực và vị trí thông qua hệ thống AI.',
                'Liên hệ, gửi thông báo và điều phối trong các hoạt động tình nguyện.',
                'Phân tích dữ liệu ẩn danh để cải thiện chất lượng dịch vụ của nền tảng.',
              ],
            ),
            const SizedBox(height: 20),

            // Section 2
            _buildSectionWithList(
              context,
              number: '2',
              title: 'Bảo vệ và Lưu trữ dữ liệu',
              intro:
                  'Chúng tôi cam kết bảo vệ thông tin cá nhân của bạn bằng các biện pháp an ninh mạng tiên tiến nhất:',
              color: const Color(0xFF198754),
              items: [
                'Mật khẩu được mã hóa an toàn (Hashing) trước khi lưu vào cơ sở dữ liệu.',
                'Sử dụng giao thức HTTPS để mã hóa dữ liệu truyền tải trên mạng.',
                'Truy cập vào dữ liệu cá nhân bị hạn chế nghiêm ngặt, chỉ dành cho những nhân sự có thẩm quyền (Admin, Kiểm duyệt viên của chiến dịch bạn tham gia).',
              ],
            ),
            const SizedBox(height: 20),

            // Section 3
            _buildSectionWithList(
              context,
              number: '3',
              title: 'Chia sẻ thông tin',
              intro:
                  'Chúng tôi KHÔNG bán, trao đổi hoặc cho thuê thông tin cá nhân của bạn cho bên thứ ba. Thông tin của bạn chỉ được chia sẻ trong các trường hợp sau:',
              color: const Color(0xFF198754),
              items: [
                'Với các Kiểm duyệt viên tổ chức chiến dịch mà bạn đăng ký tham gia (để phục vụ mục đích quản lý và liên lạc).',
                'Khi có yêu cầu hợp pháp từ cơ quan nhà nước có thẩm quyền.',
              ],
            ),
            const SizedBox(height: 20),

            // Section 4
            _buildSectionWithList(
              context,
              number: '4',
              title: 'Quyền lợi của bạn',
              intro:
                  'Bạn có toàn quyền kiểm soát dữ liệu cá nhân của mình, bao gồm:',
              color: const Color(0xFF198754),
              items: [
                'Quyền truy cập và yêu cầu trích xuất dữ liệu cá nhân đang được lưu trữ.',
                'Quyền chỉnh sửa, cập nhật khi có sai sót về thông tin.',
                'Quyền yêu cầu xóa tài khoản và toàn bộ dữ liệu liên quan khỏi hệ thống VMS-AI.',
              ],
            ),
            const SizedBox(height: 20),

            // Section 5
            _buildSection(
              context,
              number: '5',
              title: 'Liên hệ',
              content:
                  'Mọi thắc mắc về Chính sách bảo mật hoặc yêu cầu xử lý dữ liệu cá nhân, vui lòng liên hệ hệ thống qua email: contact@vms-ai.vn.',
              color: const Color(0xFF198754),
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
                        side: const BorderSide(color: Color(0xFF198754)),
                        foregroundColor: const Color(0xFF198754),
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
    String? intro,
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
          if (intro != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Text(
                intro,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ],
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
