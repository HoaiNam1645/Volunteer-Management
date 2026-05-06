import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/osm_map_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final UserRepository _repo = UserRepository();
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;

  bool _loading = true;
  bool _savingPersonal = false;
  bool _savingPassword = false;

  // Personal form
  final _hoTenCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _idNumberCtl = TextEditingController();
  final _streetCtl = TextEditingController();
  final _bioCtl = TextEditingController();
  String _gender = '';
  DateTime? _dob;
  int? _provinceId;
  int? _wardId;
  String? _viDo;
  String? _kinhDo;
  String? _avatarUrl;
  File? _avatarFile;

  // Password form
  final _currentPwCtl = TextEditingController();
  final _newPwCtl = TextEditingController();
  final _confirmPwCtl = TextEditingController();
  bool _hasExistingPassword = true;
  bool _showCurrentPw = false;
  bool _showNewPw = false;
  bool _showConfirmPw = false;

  // Catalogs
  List<ProvinceItem> _provinces = [];
  List<WardItem> _wards = [];

  // Notifications
  final List<_NotiPref> _notifications = [
    _NotiPref('campaign_new', 'Chiến dịch mới', 'Nhận thông báo khi có chiến dịch mới phù hợp', Icons.campaign, Colors.blue, true),
    _NotiPref('campaign_assign', 'Phân công chiến dịch', 'Khi được phân công vào chiến dịch', Icons.assignment_turned_in, Colors.green, true),
    _NotiPref('campaign_remind', 'Nhắc nhở chiến dịch', 'Trước khi chiến dịch bắt đầu', Icons.access_time, Colors.orange, true),
    _NotiPref('rating', 'Đánh giá mới', 'Khi có đánh giá từ kiểm duyệt viên', Icons.star, Colors.pink, true),
    _NotiPref('email_digest', 'Email tổng hợp hàng tuần', 'Email tóm tắt hoạt động hằng tuần', Icons.email_outlined, Colors.indigo, false),
    _NotiPref('ai_suggest', 'Gợi ý AI', 'Khi AI gợi ý chiến dịch phù hợp', Icons.smart_toy_outlined, Colors.purple, true),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hoTenCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _idNumberCtl.dispose();
    _streetCtl.dispose();
    _bioCtl.dispose();
    _currentPwCtl.dispose();
    _newPwCtl.dispose();
    _confirmPwCtl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    UserResult userRes;
    try {
      final results = await Future.wait([
        _repo.getMyProfile(),
        _repo.getProvinces(),
      ]);
      userRes = results[0] as UserResult;
      _provinces = results[1] as List<ProvinceItem>;
    } catch (e) {
      userRes = UserResult.failure('Lỗi tải dữ liệu: $e');
      _provinces = const [];
    }

    if (userRes.success && userRes.user != null) {
      _applyUser(userRes.user!);
      if (_provinceId != null) {
        _wards = await _repo.getWards(_provinceId!);
      }
    } else if (mounted) {
      // Fallback: dùng user đang cache trong AuthProvider để không hiển thị form trống
      final cached = context.read<AuthProvider>().currentUser;
      if (cached != null) _applyUser(cached);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userRes.message ?? 'Không tải được thông tin'), backgroundColor: Colors.orange),
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  void _applyUser(User u) {
    _hoTenCtl.text = u.hoTen;
    _emailCtl.text = u.email;
    _phoneCtl.text = u.soDienThoai ?? '';
    _idNumberCtl.text = u.soCccd ?? '';
    _streetCtl.text = u.diaChiDuong ?? '';
    _bioCtl.text = u.gioiThieu ?? '';
    _gender = u.gioiTinh ?? '';
    _dob = u.ngaySinh != null && u.ngaySinh!.isNotEmpty ? DateTime.tryParse(u.ngaySinh!) : null;
    _provinceId = u.tinhThanhId;
    _wardId = u.phuongXaId;
    _viDo = u.viDo?.toString();
    _kinhDo = u.kinhDo?.toString();
    _avatarUrl = u.anhDaiDien;
    _hasExistingPassword = u.coMatKhau;
  }

  bool get _canManageAccount {
    final user = context.read<AuthProvider>().currentUser;
    return user?.hasPermission('account_center.manage') ?? false;
  }

  Future<void> _pickAvatar() async {
    if (!_canManageAccount) return;
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
      if (picked != null) {
        setState(() => _avatarFile = File(picked.path));
      }
    } catch (_) {/* ignore */}
  }

  Future<void> _pickDob() async {
    final initial = _dob ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _onProvinceChanged(int? id) async {
    setState(() {
      _provinceId = id;
      _wardId = null;
      _wards = [];
    });
    if (id != null) {
      final wards = await _repo.getWards(id);
      if (mounted) setState(() => _wards = wards);
      // Default lat/lng to province center if no specific one set
      final prov = _provinces.firstWhere((p) => p.id == id, orElse: () => const ProvinceItem(id: 0, ten: ''));
      if (prov.viDo != null && prov.kinhDo != null) {
        setState(() {
          _viDo = prov.viDo!.toStringAsFixed(7);
          _kinhDo = prov.kinhDo!.toStringAsFixed(7);
        });
      }
    }
  }

  void _onWardChanged(int? id) {
    setState(() => _wardId = id);
    if (id != null) {
      final ward = _wards.firstWhere((w) => w.id == id, orElse: () => const WardItem(id: 0, ten: ''));
      if (ward.viDo != null && ward.kinhDo != null) {
        setState(() {
          _viDo = ward.viDo!.toStringAsFixed(7);
          _kinhDo = ward.kinhDo!.toStringAsFixed(7);
        });
      }
    }
  }

  Future<void> _savePersonal() async {
    if (!_canManageAccount) return;
    setState(() => _savingPersonal = true);
    final notiMap = {for (final n in _notifications) n.key: n.enabled};
    final res = await _repo.updateProfile(
      hoTen: _hoTenCtl.text.trim(),
      soDienThoai: _phoneCtl.text.trim(),
      gioiTinh: _gender,
      ngaySinh: _dob != null ? _dob!.toIso8601String().split('T').first : '',
      soCccd: _idNumberCtl.text.trim(),
      gioiThieu: _bioCtl.text.trim(),
      tinhThanhId: _provinceId?.toString(),
      phuongXaId: _wardId?.toString(),
      diaChiDuong: _streetCtl.text.trim(),
      viDo: _viDo,
      kinhDo: _kinhDo,
      tuyChonThongBao: notiMap,
      avatarFile: _avatarFile,
    );
    if (!mounted) return;
    setState(() => _savingPersonal = false);
    if (res.success) {
      // Refresh AuthProvider so name/avatar update across app
      await context.read<AuthProvider>().refreshCurrentUser();
      if (res.user != null) _applyUser(res.user!);
      _avatarFile = null;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success ? (res.message ?? 'Đã lưu thông tin') : (res.message ?? 'Lỗi cập nhật')),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ),
    );
  }

  int get _passwordStrength {
    final pw = _newPwCtl.text;
    if (pw.isEmpty) return 0;
    int score = 0;
    if (pw.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pw)) score++;
    if (RegExp(r'[0-9]').hasMatch(pw)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) score++;
    return score;
  }

  String _strengthLabel(int s) => switch (s) {
        0 => '',
        1 => 'Rất yếu',
        2 => 'Yếu',
        3 => 'Trung bình',
        _ => 'Mạnh',
      };

  Color _strengthColor(int s) => switch (s) {
        <= 1 => Colors.red,
        2 => Colors.orange,
        3 => Colors.blue,
        _ => Colors.green,
      };

  bool get _canChangePassword {
    final hasCurrent = _hasExistingPassword ? _currentPwCtl.text.isNotEmpty : true;
    final isDifferent = _hasExistingPassword ? _newPwCtl.text != _currentPwCtl.text : true;
    return hasCurrent &&
        _newPwCtl.text.length >= 8 &&
        _confirmPwCtl.text == _newPwCtl.text &&
        isDifferent;
  }

  Future<void> _changePassword() async {
    if (!_canManageAccount || !_canChangePassword) return;
    setState(() => _savingPassword = true);
    final res = await _repo.changePassword(
      currentPassword: _hasExistingPassword ? _currentPwCtl.text : null,
      newPassword: _newPwCtl.text,
      newPasswordConfirmation: _confirmPwCtl.text,
    );
    if (!mounted) return;
    setState(() => _savingPassword = false);
    if (res.success) {
      _currentPwCtl.clear();
      _newPwCtl.clear();
      _confirmPwCtl.clear();
      _hasExistingPassword = true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message ?? (res.success ? 'Đã đổi mật khẩu' : 'Lỗi')),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDialog(
        title: 'Đăng xuất',
        content: 'Bạn có chắc muốn đăng xuất?',
        confirmText: 'Đăng xuất',
        isDestructive: true,
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Tài khoản'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.person, size: 18), text: 'Thông tin'),
            Tab(icon: Icon(Icons.lock, size: 18), text: 'Mật khẩu'),
            Tab(icon: Icon(Icons.notifications, size: 18), text: 'Thông báo'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalTab(),
                _buildPasswordTab(),
                _buildNotificationsTab(),
              ],
            ),
    );
  }

  Widget _buildPersonalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAvatarHeader(),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Thông tin cơ bản',
          icon: Icons.person_pin,
          color: AppTheme.primaryColor,
          children: [
            _labeledField('Họ và tên *', TextField(controller: _hoTenCtl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
            _labeledField(
              'Ngày sinh',
              InkWell(
                onTap: _pickDob,
                child: InputDecorator(
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  child: Text(_dob != null
                      ? '${_dob!.day.toString().padLeft(2, '0')}/${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}'
                      : 'Chọn ngày'),
                ),
              ),
            ),
            _labeledField(
              'Giới tính',
              DropdownButtonFormField<String>(
                initialValue: _gender.isEmpty ? null : _gender,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: const [
                  DropdownMenuItem(value: 'nam', child: Text('Nam')),
                  DropdownMenuItem(value: 'nu', child: Text('Nữ')),
                  DropdownMenuItem(value: 'khac', child: Text('Khác')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? ''),
              ),
            ),
            _labeledField('Số CCCD', TextField(controller: _idNumberCtl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
          ],
        ),
        _sectionCard(
          title: 'Liên hệ',
          icon: Icons.contact_mail,
          color: Colors.green,
          children: [
            _labeledField(
              'Email *',
              TextField(
                controller: _emailCtl,
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  fillColor: Colors.grey[100],
                  filled: true,
                  helperText: 'Email không thể thay đổi',
                ),
              ),
            ),
            _labeledField('Số điện thoại *', TextField(controller: _phoneCtl, keyboardType: TextInputType.phone, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
          ],
        ),
        _sectionCard(
          title: 'Địa chỉ',
          icon: Icons.location_on,
          color: Colors.red,
          children: [
            _labeledField(
              'Tỉnh / Thành phố *',
              DropdownButtonFormField<int>(
                initialValue: _provinceId,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: _provinces.map((p) => DropdownMenuItem(value: p.id, child: Text(p.ten, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: _onProvinceChanged,
              ),
            ),
            _labeledField(
              'Phường / Xã',
              DropdownButtonFormField<int>(
                initialValue: _wardId,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: _wards.map((w) => DropdownMenuItem(value: w.id, child: Text(w.ten, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: _wards.isEmpty ? null : _onWardChanged,
              ),
            ),
            _labeledField('Số nhà, đường', TextField(controller: _streetCtl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
            if (_viDo != null && _kinhDo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.map, size: 16, color: AppTheme.primaryColor),
                  SizedBox(width: 6),
                  Text('Vị trí trên bản đồ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Spacer(),
                  Text('Chạm để di chuyển', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 6),
              OsmMapWidget(
                latitude: double.tryParse(_viDo!),
                longitude: double.tryParse(_kinhDo!),
                height: 200,
                draggable: _canManageAccount,
                onPositionChanged: (lat, lng) => setState(() {
                  _viDo = lat.toStringAsFixed(7);
                  _kinhDo = lng.toStringAsFixed(7);
                }),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _readOnlyField('Vĩ độ', _viDo!)),
                  const SizedBox(width: 8),
                  Expanded(child: _readOnlyField('Kinh độ', _kinhDo!)),
                ],
              ),
            ],
          ],
        ),
        _sectionCard(
          title: 'Giới thiệu bản thân',
          icon: Icons.edit_note,
          color: Colors.blueGrey,
          children: [
            TextField(
              controller: _bioCtl,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Vài dòng về bạn...'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Đặt lại'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_canManageAccount && !_savingPersonal) ? _savePersonal : null,
                icon: _savingPersonal
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_savingPersonal ? 'Đang lưu...' : 'Lưu thông tin'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAvatarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                backgroundImage: _avatarFile != null
                    ? FileImage(_avatarFile!)
                    : (_avatarUrl != null && _avatarUrl!.isNotEmpty ? NetworkImage(_avatarUrl!) : null) as ImageProvider?,
                child: (_avatarFile == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                    ? const Icon(Icons.person, size: 32, color: AppTheme.primaryColor)
                    : null,
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_hoTenCtl.text.isEmpty ? '—' : _hoTenCtl.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(_emailCtl.text, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }

  Widget _labeledField(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          field,
        ],
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildPasswordTab() {
    final s = _passwordStrength;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Đổi mật khẩu',
          icon: Icons.shield,
          color: Colors.orange,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFC107), Color(0xFFFD7E14)])),
                child: const Icon(Icons.lock, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _hasExistingPassword
                    ? 'Mật khẩu mạnh giúp bảo vệ tài khoản của bạn'
                    : 'Bạn chưa có mật khẩu (đăng nhập bằng Google). Tạo mật khẩu mới ở dưới.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            if (_hasExistingPassword)
              _labeledField(
                'Mật khẩu hiện tại *',
                TextField(
                  controller: _currentPwCtl,
                  obscureText: !_showCurrentPw,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(_showCurrentPw ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: () => setState(() => _showCurrentPw = !_showCurrentPw),
                    ),
                  ),
                ),
              ),
            _labeledField(
              'Mật khẩu mới *',
              TextField(
                controller: _newPwCtl,
                obscureText: !_showNewPw,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(_showNewPw ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setState(() => _showNewPw = !_showNewPw),
                  ),
                ),
              ),
            ),
            if (_newPwCtl.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(4, (i) {
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                            height: 4,
                            decoration: BoxDecoration(
                              color: i < s ? _strengthColor(s) : Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(_strengthLabel(s), style: TextStyle(fontSize: 11, color: _strengthColor(s))),
                  ],
                ),
              ),
            _labeledField(
              'Xác nhận mật khẩu mới *',
              TextField(
                controller: _confirmPwCtl,
                obscureText: !_showConfirmPw,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirmPw ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setState(() => _showConfirmPw = !_showConfirmPw),
                  ),
                  errorText: (_confirmPwCtl.text.isNotEmpty && _confirmPwCtl.text != _newPwCtl.text)
                      ? 'Mật khẩu xác nhận không khớp'
                      : null,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_canManageAccount && _canChangePassword && !_savingPassword) ? _changePassword : null,
                icon: _savingPassword
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.shield),
                label: Text(_savingPassword ? 'Đang xử lý...' : 'Đổi mật khẩu'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Tuỳ chọn thông báo',
          icon: Icons.notifications,
          color: Colors.blue,
          children: [
            for (int i = 0; i < _notifications.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: _notifications[i].color.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(_notifications[i].icon, color: _notifications[i].color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_notifications[i].title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(_notifications[i].desc, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Switch(
                      value: _notifications[i].enabled,
                      onChanged: _canManageAccount
                          ? (v) => setState(() => _notifications[i] = _notifications[i].copyWith(enabled: v))
                          : null,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_canManageAccount && !_savingPersonal) ? _savePersonal : null,
                icon: const Icon(Icons.save),
                label: const Text('Lưu thông báo'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotiPref {
  final String key;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final bool enabled;
  const _NotiPref(this.key, this.title, this.desc, this.icon, this.color, this.enabled);
  _NotiPref copyWith({bool? enabled}) => _NotiPref(key, title, desc, icon, color, enabled ?? this.enabled);
}
