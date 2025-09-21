import 'package:flutter/material.dart';
import '../services/employee_api.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  List<Employee> _employees = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _showAddForm = false;
  Employee? _editingEmployee;
  
  // Sort and filter functionality
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  String _searchQuery = '';
  String? _selectedPosition;
  bool? _selectedStatus;
  bool _showActions = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedPositionForm = 'Driver';
  bool _isActiveForm = true;
  bool _isCustomPosition = false;
  final TextEditingController _customPositionController = TextEditingController();

  final List<String> _positions = ['Driver', 'Conductor', 'Admin', 'Manager', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _customPositionController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response = await EmployeeApiService.getAllEmployees(
        page: _currentPage,
        position: _selectedPosition,
        active: _selectedStatus,
      );
      if (response.success && response.data != null) {
        setState(() {
          _employees = response.data!;
          if (response.pagination != null) {
            _totalPages = response.pagination!.totalPages;
          }
        });
      } else {
        _showErrorSnackBar(response.message ?? 'Failed to load employees');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading employees: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
              const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Name'),
                value: 'name',
                groupValue: _sortBy,
                onChanged: (String? value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Position'),
                value: 'position',
                groupValue: _sortBy,
                onChanged: (String? value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Status'),
                value: 'status',
                groupValue: _sortBy,
                onChanged: (String? value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
              const Divider(),
              const Text('Order:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Ascending'),
                value: 'asc',
                groupValue: _sortOrder,
                onChanged: (String? value) {
                  setState(() {
                    _sortOrder = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Descending'),
                value: 'desc',
                groupValue: _sortOrder,
                onChanged: (String? value) {
                  setState(() {
                    _sortOrder = value!;
                  });
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
              onPressed: () {
                Navigator.of(context).pop();
                _applySorting();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _applySorting() {
    setState(() {
      _employees.sort((a, b) {
        int comparison = 0;
        switch (_sortBy) {
          case 'name':
            comparison = a.fullName.compareTo(b.fullName);
            break;
          case 'position':
            comparison = a.position.compareTo(b.position);
            break;
          case 'status':
            comparison = a.active.toString().compareTo(b.active.toString());
            break;
        }
        return _sortOrder == 'asc' ? comparison : -comparison;
      });
    });
  }

  List<Employee> get _filteredEmployees {
    List<Employee> filtered = _employees;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((employee) =>
        employee.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        employee.position.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  void _filterEmployees() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }


  Future<void> _showAddFormDialog() async {
    _nameController.clear();
    _customPositionController.clear();
    _selectedPositionForm = 'Driver';
    _isActiveForm = true;
    _isCustomPosition = false;
    
    setState(() {
      _showAddForm = true;
    });
  }

  Future<void> _showEditFormDialog(Employee employee) async {
    _nameController.text = employee.fullName;
    _isActiveForm = employee.active;
    
    // Check if the position is in our predefined list
    if (_positions.contains(employee.position)) {
      _selectedPositionForm = employee.position;
      _isCustomPosition = false;
      _customPositionController.clear();
    } else {
      _selectedPositionForm = 'Other';
      _isCustomPosition = true;
      _customPositionController.text = employee.position;
    }
    
    setState(() {
      _editingEmployee = employee;
      _showAddForm = true;
    });
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    // Get the final position value
    final String finalPosition = _isCustomPosition 
        ? _customPositionController.text.trim()
        : _selectedPositionForm;

    try {
      if (_editingEmployee != null) {
        // Update existing employee
        final response = await EmployeeApiService.updateEmployee(
          id: _editingEmployee!.id,
          fullName: _nameController.text.trim(),
          position: finalPosition,
          active: _isActiveForm,
        );
        
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee updated successfully')),
          );
          _loadEmployees();
        } else {
          _showErrorSnackBar(response.message ?? 'Failed to update employee');
        }
      } else {
        // Create new employee
        final response = await EmployeeApiService.createEmployee(
          fullName: _nameController.text.trim(),
          position: finalPosition,
          active: _isActiveForm,
        );
        
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee created successfully')),
          );
          _loadEmployees();
        } else {
          _showErrorSnackBar(response.message ?? 'Failed to create employee');
        }
      }
      
      setState(() {
        _showAddForm = false;
        _editingEmployee = null;
        _isCustomPosition = false;
        _customPositionController.clear();
      });
    } catch (e) {
      _showErrorSnackBar('Error saving employee: $e');
    }
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await EmployeeApiService.deleteEmployee(employee.id);
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee deleted successfully')),
          );
          _loadEmployees();
        } else {
          _showErrorSnackBar(response.message ?? 'Failed to delete employee');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting employee: $e');
      }
    }
  }

  Future<void> _toggleEmployeeStatus(Employee employee) async {
    try {
      final response = await EmployeeApiService.toggleEmployeeStatus(employee.id);
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Employee status updated')),
        );
        _loadEmployees();
      } else {
        _showErrorSnackBar(response.message ?? 'Failed to update employee status');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating employee status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                          // Edit mode toggle (shows Actions column)
                          IconButton(
                            onPressed: () => setState(() => _showActions = !_showActions),
                            icon: Icon(
                              _showActions ? Icons.edit_off : Icons.edit,
                              color: const Color(0xFF3E4795),
                            ),
                            tooltip: _showActions ? 'Exit edit mode' : 'Edit mode',
                          ),
                          const SizedBox(width: 8),
                          // Add employee as + icon
                          ElevatedButton(
                            onPressed: _showAddFormDialog,
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
                        'Employee Management',
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
                            icon: Icon(
                              _showActions ? Icons.edit_off : Icons.edit,
                              color: const Color(0xFF3E4795),
                            ),
                            tooltip: _showActions ? 'Exit edit mode' : 'Edit mode',
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _showAddFormDialog,
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
              
              // Search and Filter Controls
              Container(
                padding: const EdgeInsets.all(16),
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
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => _filterEmployees(),
                                decoration: InputDecoration(
                                  hintText: 'Search employees',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF3E4795)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.filter_list),
                              onPressed: () => _showSortOptions(context),
                              tooltip: 'Sort Options',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedPosition,
                                decoration: const InputDecoration(
                                  labelText: 'Position',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Positions')),
                                  ..._positions.map((position) {
                                    return DropdownMenuItem(value: position, child: Text(position));
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPosition = value;
                                    _currentPage = 1;
                                  });
                                  _loadEmployees();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<bool>(
                                value: _selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('All Status')),
                                  DropdownMenuItem(value: true, child: Text('Active')),
                                  DropdownMenuItem(value: false, child: Text('Inactive')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value;
                                    _currentPage = 1;
                                  });
                                  _loadEmployees();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => _filterEmployees(),
                            decoration: InputDecoration(
                              hintText: 'Search employees',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF3E4795)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            value: _selectedPosition,
                            decoration: const InputDecoration(
                              labelText: 'Position',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Positions')),
                              ..._positions.map((position) {
                                return DropdownMenuItem(value: position, child: Text(position));
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedPosition = value;
                                _currentPage = 1;
                              });
                              _loadEmployees();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<bool>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('All Status')),
                              DropdownMenuItem(value: true, child: Text('Active')),
                              DropdownMenuItem(value: false, child: Text('Inactive')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value;
                                _currentPage = 1;
                              });
                              _loadEmployees();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showSortOptions(context),
                          icon: const Icon(Icons.sort, size: 18),
                          label: const Text('Sort'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E4795),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 16),
              
              // Table
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
                      // Table Header
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
                                if (_showActions)
                                  const Expanded(flex: 1, child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                              ],
                            )
                          : Row(
                              children: [
                                const Expanded(flex: 2, child: Text('Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                const Expanded(flex: 2, child: Text('Position', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                const Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                if (_showActions)
                                  const Expanded(flex: 2, child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              ],
                            ),
                      ),
                      
                      // Table Content
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _filteredEmployees.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No employees found',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _filteredEmployees.length,
                                    itemBuilder: (context, index) {
                                      final employee = _filteredEmployees[index];
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: isMobile 
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        employee.fullName,
                                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                                                      ),
                                                    ),
                                                    if (_showActions)
                                                      Row(
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                            onPressed: () => _showEditFormDialog(employee),
                                                            tooltip: 'Edit',
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                              employee.active ? Icons.pause : Icons.play_arrow,
                                                              color: employee.active ? Colors.orange : Colors.green,
                                                              size: 20,
                                                            ),
                                                            onPressed: () => _toggleEmployeeStatus(employee),
                                                            tooltip: employee.active ? 'Deactivate' : 'Activate',
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                            onPressed: () => _deleteEmployee(employee),
                                                            tooltip: 'Delete',
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Position: ${employee.position}',
                                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Status: ${employee.active ? 'Active' : 'Inactive'}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: employee.active ? Colors.green : Colors.red,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    employee.fullName,
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(employee.position),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: BoxDecoration(
                                                          color: employee.active ? Colors.green : Colors.red,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        employee.active ? 'Active' : 'Inactive',
                                                        style: TextStyle(
                                                          color: employee.active ? Colors.green : Colors.red,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (_showActions)
                                                  Expanded(
                                                    flex: 2,
                                                    child: Row(
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                                          onPressed: () => _showEditFormDialog(employee),
                                                          tooltip: 'Edit',
                                                        ),
                                                        IconButton(
                                                          icon: Icon(
                                                            employee.active ? Icons.pause : Icons.play_arrow,
                                                            color: employee.active ? Colors.orange : Colors.green,
                                                            size: 18,
                                                          ),
                                                          onPressed: () => _toggleEmployeeStatus(employee),
                                                          tooltip: employee.active ? 'Deactivate' : 'Activate',
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                          onPressed: () => _deleteEmployee(employee),
                                                          tooltip: 'Delete',
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
                      
                      // Pagination
                      if (_totalPages > 1)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 1
                                    ? () {
                                        setState(() => _currentPage--);
                                        _loadEmployees();
                                      }
                                    : null,
                              ),
                              Text(
                                'Page $_currentPage of $_totalPages',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _currentPage < _totalPages
                                    ? () {
                                        setState(() => _currentPage++);
                                        _loadEmployees();
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Add/Edit Form Modal
        if (_showAddForm)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  width: isMobile ? MediaQuery.of(context).size.width - 32 : 500,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingEmployee != null ? 'Edit Employee' : 'Add New Employee',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E4795),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedPositionForm,
                          decoration: const InputDecoration(
                            labelText: 'Position',
                            border: OutlineInputBorder(),
                          ),
                          items: _positions.map((position) {
                            return DropdownMenuItem(
                              value: position,
                              child: Text(position),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPositionForm = value!;
                              _isCustomPosition = (value == 'Other');
                              if (!_isCustomPosition) {
                                _customPositionController.clear();
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a position';
                            }
                            if (value == 'Other' && _isCustomPosition && _customPositionController.text.trim().isEmpty) {
                              return 'Please enter a custom position';
                            }
                            return null;
                          },
                        ),
                        if (_isCustomPosition) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customPositionController,
                            decoration: const InputDecoration(
                              labelText: 'Custom Position',
                              border: OutlineInputBorder(),
                              hintText: 'Enter custom position',
                            ),
                            validator: (value) {
                              if (_isCustomPosition && (value == null || value.trim().isEmpty)) {
                                return 'Please enter a custom position';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Active: '),
                            Switch(
                              value: _isActiveForm,
                              onChanged: (value) {
                                setState(() {
                                  _isActiveForm = value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showAddForm = false;
                                  _editingEmployee = null;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _saveEmployee,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3E4795),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(_editingEmployee != null ? 'Update' : 'Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}