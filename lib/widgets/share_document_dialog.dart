import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/document_model.dart';
import '../models/permission_model.dart';
import '../services/supabase_service.dart';
import '../state/auth_provider.dart';

/// Hộp thoại Chia sẻ tài liệu và quản lý quyền truy cập (Permissions)
class ShareDocumentDialog extends StatefulWidget {
  final DocumentModel document;

  const ShareDocumentDialog({super.key, required this.document});

  static Future<void> show(BuildContext context, DocumentModel document) {
    return showDialog<void>(
      context: context,
      builder: (context) => ShareDocumentDialog(document: document),
    );
  }

  @override
  State<ShareDocumentDialog> createState() => _ShareDocumentDialogState();
}

class _ShareDocumentDialogState extends State<ShareDocumentDialog> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedPermission = 'viewer';
  bool _isLoading = false;
  bool _isLoadingList = true;
  String? _errorMessage;
  List<PermissionModel> _permissions = [];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoadingList = true);
    try {
      final list = await _supabaseService.getDocumentPermissions(widget.document.id);
      if (mounted) {
        setState(() {
          _permissions = list;
          _isLoadingList = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingList = false);
      }
    }
  }

  Future<void> _shareDocument() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Lấy Firebase UID của người dùng hiện tại để truyền vào shareDocument
    final ownerId = context.read<AuthProvider>().user?.uid ?? '';

    try {
      await _supabaseService.shareDocument(
        document: widget.document,
        ownerId: ownerId,
        granteeEmail: _emailController.text.trim(),
        permissionLevel: _selectedPermission,
      );

      _emailController.clear();
      await _loadPermissions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chia sẻ tài liệu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _revokePermission(PermissionModel perm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gỡ quyền truy cập?'),
        content: Text('Bạn có chắc muốn hủy quyền của "${perm.granteeEmail}" đối với tài liệu này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gỡ quyền'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _supabaseService.revokePermission(perm.id);
      await _loadPermissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã gỡ quyền của ${perm.granteeEmail}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.share_rounded, color: theme.colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chia sẻ tài liệu',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Form nhập email và chọn quyền
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email người nhận',
                      hintText: 'vidu@gmail.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!val.contains('@')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPermission,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Quyền hạn',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'viewer', child: Text('Chỉ xem')),
                            DropdownMenuItem(value: 'editor', child: Text('Chỉnh sửa')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPermission = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _shareDocument,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('Chia sẻ ngay'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),
            const Text(
              'Những người có quyền truy cập',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Danh sách phân quyền
            Flexible(
              child: _isLoadingList
                  ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  : Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(50)),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          // Chủ sở hữu
                          ListTile(
                            dense: true,
                            leading: const CircleAvatar(
                              radius: 14,
                              child: Icon(Icons.person, size: 16),
                            ),
                            title: Text(
                              widget.document.ownerEmail ?? 'Chủ sở hữu (Bạn)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Chủ sở hữu',
                                style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          // Danh sách quyền đã cấp
                          ..._permissions.map((perm) {
                            final isEditor = perm.isEditor;
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: isEditor ? Colors.orange.withAlpha(40) : Colors.green.withAlpha(40),
                                child: Icon(
                                  isEditor ? Icons.edit_rounded : Icons.visibility_rounded,
                                  size: 14,
                                  color: isEditor ? Colors.deepOrange : Colors.green,
                                ),
                              ),
                              title: Text(
                                perm.granteeEmail,
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                isEditor ? 'Có quyền chỉnh sửa' : 'Chỉ có quyền xem',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                                tooltip: 'Gỡ quyền',
                                onPressed: () => _revokePermission(perm),
                              ),
                            );
                          }),
                          if (_permissions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                child: Text(
                                  'Chưa có ai khác được chia sẻ tài liệu này',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
