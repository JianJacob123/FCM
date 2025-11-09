import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/user_api.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  bool _loading = true;
  bool _showActions = false;
  List<UserAccount> _users = [];
  // Search & Sort
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name'; // name | role | username
  bool _sortAsc = true;
  // Role filter
  List<String> _selectedRoles = [];

  void _finishEditAndNotify() {
    setState(() => _showActions = false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saved'),
        content: const Text('Edits were saved successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _cancelEdit() {
    setState(() => _showActions = false);
  }

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  void _showSortOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sort Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Name'),
                value: 'name',
                groupValue: _sortBy,
                onChanged: (String? value) {
                  setState(() => _sortBy = value!);
                },
              ),
              RadioListTile<String>(
                title: const Text('Role'),
                value: 'role',
                groupValue: _sortBy,
                onChanged: (String? value) {
                  setState(() => _sortBy = value!);
                },
              ),
              RadioListTile<String>(
                title: const Text('Username'),
                value: 'username',
                groupValue: _sortBy,
                onChanged: (String? value) {
                  setState(() => _sortBy = value!);
                },
              ),
              const Divider(),
              const Text(
                'Order:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Ascending'),
                value: 'asc',
                groupValue: _sortAsc ? 'asc' : 'desc',
                onChanged: (String? value) {
                  setState(() => _sortAsc = value == 'asc');
                },
              ),
              RadioListTile<String>(
                title: const Text('Descending'),
                value: 'desc',
                groupValue: _sortAsc ? 'asc' : 'desc',
                onChanged: (String? value) {
                  setState(() => _sortAsc = value == 'asc');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await UserApiService.listUsers();
      setState(() => _users = list);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<UserAccount> _getFilteredSorted() {
    List<UserAccount> list = _users.where((u) {
      if (_searchQuery.isEmpty) return true;
      return u.fullName.toLowerCase().contains(_searchQuery) ||
          u.userRole.toLowerCase().contains(_searchQuery) ||
          u.username.toLowerCase().contains(_searchQuery);
    }).toList();

    // Apply role filter if any selected
    if (_selectedRoles.isNotEmpty) {
      list = list.where((u) => _selectedRoles.contains(u.userRole)).toList();
    }

    int cmp<T extends Comparable>(T a, T b) =>
        _sortAsc ? a.compareTo(b) : b.compareTo(a);
    list.sort((a, b) {
      switch (_sortBy) {
        case 'role':
          return cmp(a.userRole.toLowerCase(), b.userRole.toLowerCase());
        case 'username':
          return cmp(a.username.toLowerCase(), b.username.toLowerCase());
        case 'name':
        default:
          return cmp(a.fullName.toLowerCase(), b.fullName.toLowerCase());
      }
    });
    return list;
  }

  void _showRoleFilterModal() {
    final roles = _users.map((u) => u.userRole).toSet().toList()..sort();
    List<String> tempSelected = List.from(_selectedRoles);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allSelected = roles.isNotEmpty && tempSelected.length == roles.length;
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.filter_list, color: Color(0xFF3E4795)),
                  SizedBox(width: 8),
                  Text('Filter by Role'),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width < 520
                    ? MediaQuery.of(context).size.width * 0.9
                    : 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Select all toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: allSelected,
                              activeColor: const Color(0xFF3E4795),
                              onChanged: (v) {
                                setModalState(() {
                                  if (v == true) {
                                    tempSelected = List.from(roles);
                                  } else {
                                    tempSelected.clear();
                                  }
                                });
                              },
                            ),
                            const Text('Select All'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        itemCount: roles.length,
                        itemBuilder: (context, index) {
                          final role = roles[index];
                          final checked = tempSelected.contains(role);
                          return CheckboxListTile(
                            title: Text(role),
                            value: checked,
                            activeColor: const Color(0xFF3E4795),
                            onChanged: (v) {
                              setModalState(() {
                                if (v == true) {
                                  tempSelected.add(role);
                                } else {
                                  tempSelected.remove(role);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _selectedRoles = List.from(tempSelected));
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E4795),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply Filter'),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createOrEdit({UserAccount? existing}) async {
    final fullNameCtrl = TextEditingController(text: existing?.fullName ?? '');
    String role = existing?.userRole ?? 'Driver';
    final usernameCtrl = TextEditingController(text: existing?.username ?? '');
    final passwordCtrl = TextEditingController();
    bool active = existing?.active ?? true;
    bool _obscurePassword = true;

    final isEdit = existing != null;
    final isAdmin = existing?.userRole?.toLowerCase() == 'admin';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            isEdit ? 'Edit Employee Account' : 'Add Employee Account',
            style: const TextStyle(
              color: Color(0xFF3E4795),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameCtrl,
                  enabled: !isAdmin,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s,\.]')), // Letters, spaces, commas, and periods
                  ],
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: Colors.black87),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF3E4795)),
                    ),
                    disabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: role,
                  items: [
                    if (isAdmin)
                      const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    const DropdownMenuItem(value: 'Driver', child: Text('Driver')),
                    const DropdownMenuItem(
                      value: 'Conductor',
                      child: Text('Conductor'),
                    ),
                  ],
                  onChanged: isAdmin ? null : (v) => role = v ?? role,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    labelStyle: const TextStyle(color: Colors.black87),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF3E4795)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: const TextStyle(color: Colors.black87),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF3E4795)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) {
                    return TextField(
                      controller: passwordCtrl,
                      decoration: InputDecoration(
                        labelText: isEdit
                            ? 'Password (leave blank to keep)'
                            : 'Password',
                        labelStyle: const TextStyle(color: Colors.black87),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF3E4795)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Active toggle removed; new users default to active=true and edits preserve existing state
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3E4795),
                side: const BorderSide(color: Color(0xFF3E4795)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                final fullName = fullNameCtrl.text.trim();
                final username = usernameCtrl.text.trim();
                
                // Validate full name: must not be empty and contain only letters, spaces, commas, and periods
                if (fullName.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Full Name is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (!RegExp(r'^[a-zA-Z\s,\.]+$').hasMatch(fullName)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Full Name can only contain letters, spaces, commas, and periods'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Validate username: must not be empty
                if (username.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Username is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Check for duplicate username (excluding current user if editing)
                final duplicateUser = _users.firstWhere(
                  (user) => user.username.toLowerCase() == username.toLowerCase() && 
                           (existing == null || user.userId != existing.userId),
                  orElse: () => UserAccount(
                    userId: -1,
                    fullName: '',
                    userRole: '',
                    username: '',
                    active: false,
                  ),
                );
                
                if (duplicateUser.userId != -1) {
                  // Close modal first, then show error
                  Navigator.pop(ctx, false);
                  // Use a small delay to ensure modal is closed before showing snackbar
                  Future.delayed(const Duration(milliseconds: 100), () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Username already exists. Please choose a different username.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  });
                  return;
                }
                
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E4795),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: const Text('Save'),
            ),
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
        await UserApiService.updateUser(
          existing!.userId,
          user,
          password: pwd.isEmpty ? null : pwd,
        );
      } else {
        await UserApiService.createUser(
          user,
          password: passwordCtrl.text.trim(),
        );
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _delete(UserAccount u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete ${u.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await UserApiService.deleteUser(u.userId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _archive(UserAccount u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Account'),
        content: Text('Are you sure you want to archive ${u.fullName}? This will move the account to the archive page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await UserApiService.archiveUser(u.userId);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${u.fullName} has been archived'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Archive failed: $e')));
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reveal failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isMobile = MediaQuery.of(context).size.width < 768;
    final filtered = _getFilteredSorted();
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
                      'Employee Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _showActions
                            ? Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: _finishEditAndNotify,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3E4795),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Save'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: _cancelEdit,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF3E4795),
                                      side: const BorderSide(color: Color(0xFF3E4795)),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              )
                            : IconButton(
                                onPressed: () =>
                                    setState(() => _showActions = true),
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF3E4795),
                                ),
                                tooltip: 'Edit mode',
                              ),
                        if (!_showActions) ...[
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
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Employee Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    Row(
                      children: [
                        _showActions
                            ? Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: _finishEditAndNotify,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3E4795),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Save'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: _cancelEdit,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF3E4795),
                                      side: const BorderSide(color: Color(0xFF3E4795)),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              )
                            : IconButton(
                                onPressed: () =>
                                    setState(() => _showActions = true),
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF3E4795),
                                ),
                                tooltip: 'Edit mode',
                              ),
                        if (!_showActions) ...[
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
                      ],
                    ),
                  ],
                ),
          const SizedBox(height: 24),

          // Search/sort block under title (inline like Trip History controls)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
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
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search employees...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sortBy,
                              onChanged: (v) => setState(() => _sortBy = v ?? _sortBy),
                              decoration: InputDecoration(
                                labelText: 'Sort by',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'name', child: Text('Name')),
                                DropdownMenuItem(value: 'role', child: Text('Role')),
                                DropdownMenuItem(value: 'username', child: Text('Username')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sortAsc ? 'asc' : 'desc',
                              onChanged: (v) => setState(() => _sortAsc = (v ?? 'asc') == 'asc'),
                              decoration: InputDecoration(
                                labelText: 'Order',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'asc', child: Text('Asc')),
                                DropdownMenuItem(value: 'desc', child: Text('Desc')),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search employees...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _sortBy,
                          onChanged: (v) => setState(() => _sortBy = v ?? _sortBy),
                          decoration: InputDecoration(
                            labelText: 'Sort by',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'name', child: Text('Name')),
                            DropdownMenuItem(value: 'role', child: Text('Role')),
                            DropdownMenuItem(value: 'username', child: Text('Username')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _sortAsc ? 'asc' : 'desc',
                          onChanged: (v) => setState(() => _sortAsc = (v ?? 'asc') == 'asc'),
                          decoration: InputDecoration(
                            labelText: 'Order',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'asc', child: Text('Asc')),
                            DropdownMenuItem(value: 'desc', child: Text('Desc')),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'Name',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Role',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: _showRoleFilterModal,
                                      child: const Icon(
                                        Icons.filter_list,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'Username',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'Password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (_showActions)
                                const Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Actions',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Row(
                            children: [
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'Name',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Role',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: _showRoleFilterModal,
                                      child: const Icon(
                                        Icons.filter_list,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'Username',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'Password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_showActions)
                                const Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Actions',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),

                  // Content
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No accounts found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final u = filtered[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        u.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        u.userRole,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        u.username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          const Text('••••••••'),
                                          if (_showActions) ...[
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_red_eye,
                                              ),
                                              onPressed: () => _reveal(u),
                                              tooltip: 'Reveal password',
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (_showActions)
                                      Expanded(
                                        flex: 1,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _createOrEdit(existing: u),
                                              tooltip: 'Edit',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.archive,
                                                color: Colors.orange,
                                                size: 18,
                                              ),
                                              onPressed: () => _archive(u),
                                              tooltip: 'Archive',
                                            ),
                                          ],
                                        ),
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
