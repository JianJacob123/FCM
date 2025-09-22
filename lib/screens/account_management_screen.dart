import 'package:flutter/material.dart';
import '../services/user_api.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  bool _loading = true;
  bool _showActions = false;
  List<UserAccount> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await UserApiService.listUsers();
      setState(() => _users = list);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createOrEdit({UserAccount? existing}) async {
    final fullNameCtrl = TextEditingController(text: existing?.fullName ?? '');
    String role = existing?.userRole ?? 'Driver';
    final usernameCtrl = TextEditingController(text: existing?.username ?? '');
    final passwordCtrl = TextEditingController();
    bool active = existing?.active ?? true;

    final isEdit = existing != null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Account' : 'Add Account'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: fullNameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'Driver', child: Text('Driver')),
                    DropdownMenuItem(value: 'Conductor', child: Text('Conductor')),
                  ],
                  onChanged: (v) => role = v ?? role,
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                const SizedBox(height: 8),
                TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username')),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordCtrl,
                  decoration: InputDecoration(labelText: isEdit ? 'Password (leave blank to keep)' : 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        );
      },
    );

    if (ok != true) return;

    final user = UserAccount(
      userId: existing?.userId ?? 0,
      fullName: fullNameCtrl.text.trim(),
      userRole: role,
      username: usernameCtrl.text.trim(),
      active: active,
    );

    try {
      if (isEdit) {
        final pwd = passwordCtrl.text.trim();
        await UserApiService.updateUser(existing!.userId, user, password: pwd.isEmpty ? null : pwd);
      } else {
        await UserApiService.createUser(user, password: passwordCtrl.text.trim());
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _delete(UserAccount u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete ${u.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await UserApiService.deleteUser(u.userId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _reveal(UserAccount u) async {
    try {
      final pwd = await UserApiService.revealPassword(
        userId: u.userId,
        adminUsername: '',
        adminPassword: '',
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Password'),
          content: SelectableText(pwd),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reveal failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isMobile = MediaQuery.of(context).size.width < 768;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header consistent with Vehicle Assignment
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _showActions = !_showActions),
                          icon: Icon(_showActions ? Icons.edit_off : Icons.edit, color: const Color(0xFF3E4795)),
                          tooltip: _showActions ? 'Exit edit mode' : 'Edit mode',
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _createOrEdit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E4795),
                            minimumSize: const Size(44, 44),
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            elevation: 0,
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Account Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _showActions = !_showActions),
                          icon: Icon(_showActions ? Icons.edit_off : Icons.edit, color: const Color(0xFF3E4795)),
                          tooltip: _showActions ? 'Exit edit mode' : 'Edit mode',
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _createOrEdit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E4795),
                            minimumSize: const Size(44, 44),
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            elevation: 0,
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
          const SizedBox(height: 24),

          // Table-like container consistent with Vehicle Assignment
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3E4795),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: isMobile
                        ? Row(
                            children: [
                              const Expanded(flex: 2, child: Text('Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                              const Expanded(flex: 1, child: Text('Role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                              const Expanded(flex: 2, child: Text('Username', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                              const Expanded(flex: 2, child: Text('Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                              if (_showActions) const Expanded(flex: 1, child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                            ],
                          )
                        : Row(
                            children: [
                              const Expanded(flex: 2, child: Text('Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              const Expanded(flex: 1, child: Text('Role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              const Expanded(flex: 2, child: Text('Username', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              const Expanded(flex: 2, child: Text('Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              if (_showActions) const Expanded(flex: 1, child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            ],
                          ),
                  ),

                  // Content
                  Expanded(
                    child: _users.isEmpty
                        ? const Center(child: Text('No accounts found', style: TextStyle(fontSize: 16, color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final u = _users[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(flex: 2, child: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w500))),
                                    Expanded(flex: 1, child: Text(u.userRole, style: const TextStyle(fontWeight: FontWeight.w500))),
                                    Expanded(flex: 2, child: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w500))),
                                    Expanded(
                                      flex: 2,
                                      child: Row(children: [
                                        const Text('••••••••'),
                                        if (_showActions) ...[
                                          const SizedBox(width: 8),
                                          IconButton(icon: const Icon(Icons.remove_red_eye), onPressed: () => _reveal(u), tooltip: 'Reveal password'),
                                        ],
                                      ]),
                                    ),
                                    if (_showActions)
                                      Expanded(
                                        flex: 1,
                                        child: Row(children: [
                                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 18), onPressed: () => _createOrEdit(existing: u), tooltip: 'Edit'),
                                          IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: () => _delete(u), tooltip: 'Delete'),
                                        ]),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


