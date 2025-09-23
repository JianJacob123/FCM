import 'package:flutter/material.dart';
import '../services/vehicle_assignment_api.dart';

class VehicleAssignmentScreen extends StatefulWidget {
  const VehicleAssignmentScreen({Key? key}) : super(key: key);

  @override
  State<VehicleAssignmentScreen> createState() => _VehicleAssignmentScreenState();
}

class _VehicleAssignmentScreenState extends State<VehicleAssignmentScreen> {
  List<VehicleAssignment> _assignments = [];
  List<VehicleInfo> _availableVehicles = [];
  List<UserInfo> _availableDrivers = [];
  List<UserInfo> _availableConductors = [];
  bool _isLoading = false;
  bool _showAddForm = false;
  bool _showActions = false;
  VehicleAssignment? _editingAssignment;
  // Search & sort
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'vehicle'; // vehicle | driver | conductor | assigned
  bool _sortAsc = true;

  final _formKey = GlobalKey<FormState>();
  int? _selectedVehicleId;
  int? _selectedDriverId;
  int? _selectedConductorId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadAssignments(),
        _loadAvailableVehicles(),
        _loadAvailableUsers(),
      ]);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<VehicleAssignment> _getFilteredSorted() {
    List<VehicleAssignment> items = _assignments.where((a) {
      if (_searchQuery.isEmpty) return true;
      final v = 'vehicle ${a.vehicleId}'.toLowerCase();
      final d = (a.driverName ?? '').toLowerCase();
      final c = (a.conductorName ?? '').toLowerCase();
      return v.contains(_searchQuery) || d.contains(_searchQuery) || c.contains(_searchQuery);
    }).toList();

    int cmp<T extends Comparable>(T a, T b) => _sortAsc ? a.compareTo(b) : b.compareTo(a);

    items.sort((a, b) {
      switch (_sortBy) {
        case 'driver':
          return cmp((a.driverName ?? ''), (b.driverName ?? ''));
        case 'conductor':
          return cmp((a.conductorName ?? ''), (b.conductorName ?? ''));
        case 'assigned':
          return cmp(a.assignedAt, b.assignedAt);
        case 'vehicle':
        default:
          return cmp(a.vehicleId, b.vehicleId);
      }
    });
    return items;
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
                title: const Text('Vehicle'),
                value: 'vehicle',
                groupValue: _sortBy,
                onChanged: (String? value) { setState(() => _sortBy = value!); },
              ),
              RadioListTile<String>(
                title: const Text('Driver'),
                value: 'driver',
                groupValue: _sortBy,
                onChanged: (String? value) { setState(() => _sortBy = value!); },
              ),
              RadioListTile<String>(
                title: const Text('Conductor'),
                value: 'conductor',
                groupValue: _sortBy,
                onChanged: (String? value) { setState(() => _sortBy = value!); },
              ),
              RadioListTile<String>(
                title: const Text('Assigned At'),
                value: 'assigned',
                groupValue: _sortBy,
                onChanged: (String? value) { setState(() => _sortBy = value!); },
              ),
              const Divider(),
              const Text('Order:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Ascending'),
                value: 'asc',
                groupValue: _sortAsc ? 'asc' : 'desc',
                onChanged: (String? value) { setState(() => _sortAsc = value == 'asc'); },
              ),
              RadioListTile<String>(
                title: const Text('Descending'),
                value: 'desc',
                groupValue: _sortAsc ? 'asc' : 'desc',
                onChanged: (String? value) { setState(() => _sortAsc = value == 'asc'); },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Apply')),
          ],
        );
      },
    );
  }

  Future<void> _loadAssignments() async {
    try {
      final response = await VehicleAssignmentApiService.getAllAssignments();
      if (response.success && response.data != null) {
        setState(() {
          _assignments = response.data!;
        });
      } else {
        _showErrorSnackBar(response.message ?? 'Failed to load assignments');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading assignments: $e');
    }
  }

  Future<void> _loadAvailableVehicles() async {
    try {
      final vehicles = await VehicleAssignmentApiService.getAvailableVehicles();
      setState(() {
        _availableVehicles = vehicles;
      });
    } catch (e) {
      print('Error loading available vehicles: $e');
    }
  }

  Future<void> _loadAvailableUsers() async {
    try {
      final drivers = await VehicleAssignmentApiService.getAvailableDrivers();
      final conductors = await VehicleAssignmentApiService.getAvailableConductors();
      setState(() {
        _availableDrivers = drivers;
        _availableConductors = conductors;
      });
    } catch (e) {
      print('Error loading available users: $e');
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showAddFormDialog() async {
    _selectedVehicleId = null;
    _selectedDriverId = null;
    _selectedConductorId = null;
    _editingAssignment = null;
    
    setState(() {
      _showAddForm = true;
    });
  }

  Future<void> _showEditFormDialog(VehicleAssignment assignment) async {
    _selectedVehicleId = assignment.vehicleId;
    _selectedDriverId = assignment.driverId;
    _selectedConductorId = assignment.conductorId;
    _editingAssignment = assignment;
    
    setState(() {
      _showAddForm = true;
    });
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that at least one user is selected
    if (_selectedDriverId == null && _selectedConductorId == null) {
      _showErrorSnackBar('Please select at least one driver or conductor');
      return;
    }

    try {
      if (_editingAssignment != null) {
        // Update existing assignment
        final response = await VehicleAssignmentApiService.updateAssignment(
          assignmentId: _editingAssignment!.assignmentId,
          vehicleId: _selectedVehicleId,
          driverId: _selectedDriverId,
          conductorId: _selectedConductorId,
        );

        if (response.success) {
          _showSuccessSnackBar('Assignment updated successfully');
          _loadData();
          setState(() {
            _showAddForm = false;
            _editingAssignment = null;
          });
        } else {
          _showErrorSnackBar(response.message ?? 'Failed to update assignment');
        }
      } else {
        // Create new assignment
        final response = await VehicleAssignmentApiService.createAssignment(
          vehicleId: _selectedVehicleId!,
          driverId: _selectedDriverId,
          conductorId: _selectedConductorId,
        );

        if (response.success) {
          _showSuccessSnackBar('Assignment created successfully');
          _loadData();
          setState(() {
            _showAddForm = false;
          });
        } else {
          _showErrorSnackBar(response.message ?? 'Failed to create assignment');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error saving assignment: $e');
    }
  }

  Future<void> _deleteAssignment(VehicleAssignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Are you sure you want to delete the assignment for Vehicle ${assignment.vehicleId}?'),
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
        final response = await VehicleAssignmentApiService.deleteAssignment(assignment.assignmentId);
        if (response.success) {
          _showSuccessSnackBar('Assignment deleted successfully');
          _loadData();
        } else {
          _showErrorSnackBar(response.message ?? 'Failed to delete assignment');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting assignment: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    final filtered = _getFilteredSorted();
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
                        'Vehicle Assignment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E4795),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Edit mode toggle
                          IconButton(
                            onPressed: () => setState(() => _showActions = !_showActions),
                            icon: Icon(
                              _showActions ? Icons.edit_off : Icons.edit,
                              color: const Color(0xFF3E4795),
                            ),
                            tooltip: _showActions ? 'Exit edit mode' : 'Edit mode',
                          ),
                          const SizedBox(width: 8),
                          // Add assignment as + icon
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
                        'Vehicle Assignment',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E4795),
                        ),
                      ),
                      Row(
                        children: [
                          // Edit mode toggle
                          IconButton(
                            onPressed: () => setState(() => _showActions = !_showActions),
                            icon: Icon(
                              _showActions ? Icons.edit_off : Icons.edit,
                              color: const Color(0xFF3E4795),
                            ),
                            tooltip: _showActions ? 'Exit edit mode' : 'Edit mode',
                          ),
                          const SizedBox(width: 8),
                          // Add assignment as + icon
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
              // Search/sort block below title
              Container(
                width: double.infinity,
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
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search vehicle, driver, or conductor',
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
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search vehicle, driver, or conductor',
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
                                const Expanded(flex: 1, child: Text('Unit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                                const Expanded(flex: 1, child: Text('Driver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                                const Expanded(flex: 1, child: Text('Conductor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                                if (_showActions)
                                  const Expanded(flex: 1, child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                              ],
                            )
                          : Row(
                              children: [
                                const Expanded(flex: 1, child: Text('Unit Number', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                const Expanded(flex: 2, child: Text('Driver Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                const Expanded(flex: 2, child: Text('Conductor Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                if (_showActions)
                                  const Expanded(flex: 1, child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              ],
                            ),
                      ),
                      
                      // Table Content
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : filtered.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No assignments found',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final assignment = filtered[index];
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
                                                    Text(
                                                      'Unit ${assignment.vehicleId}',
                                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                                                    ),
                                                    if (_showActions)
                                                      Row(
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                            onPressed: () => _showEditFormDialog(assignment),
                                                            tooltip: 'Edit',
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                            onPressed: () => _deleteAssignment(assignment),
                                                            tooltip: 'Delete',
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text(
                                                            'Driver:',
                                                            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                                          ),
                                                          Text(
                                                            assignment.driverName ?? 'Not assigned',
                                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text(
                                                            'Conductor:',
                                                            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                                          ),
                                                          Text(
                                                            assignment.conductorName ?? 'Not assigned',
                                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Assigned: ${assignment.assignedAt.toString().split(' ')[0]}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    'Unit ${assignment.vehicleId}',
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    assignment.driverName ?? 'Not assigned',
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    assignment.conductorName ?? 'Not assigned',
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                                if (_showActions)
                                                  Expanded(
                                                    flex: 1,
                                                    child: Row(
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                                          onPressed: () => _showEditFormDialog(assignment),
                                                          tooltip: 'Edit Assignment',
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                          onPressed: () => _deleteAssignment(assignment),
                                                          tooltip: 'Delete Assignment',
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
        ),
        
        // Add Assignment Form Modal
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
                          _editingAssignment != null ? 'Edit Assignment' : 'Add New Assignment',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E4795),
                          ),
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<int>(
                          value: _selectedVehicleId,
                          decoration: const InputDecoration(
                            labelText: 'Select Vehicle',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            // Include currently assigned vehicle for editing
                            if (_editingAssignment != null)
                              DropdownMenuItem<int>(
                                value: _editingAssignment!.vehicleId,
                                child: Text('Vehicle ${_editingAssignment!.vehicleId} (Current)'),
                              ),
                            // Include available vehicles
                            ..._availableVehicles.map((vehicle) {
                              return DropdownMenuItem<int>(
                                value: vehicle.vehicleId,
                                child: Text('Vehicle ${vehicle.vehicleId}'),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedVehicleId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a vehicle';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedDriverId,
                          decoration: const InputDecoration(
                            labelText: 'Select Driver (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            // Include "None" option
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('None'),
                            ),
                            // Include currently assigned driver for editing
                            if (_editingAssignment != null && _editingAssignment!.driverId != null)
                              DropdownMenuItem<int>(
                                value: _editingAssignment!.driverId,
                                child: Text('${_editingAssignment!.driverName} (Current)'),
                              ),
                            // Include available drivers
                            ..._availableDrivers.map((driver) {
                              return DropdownMenuItem<int>(
                                value: driver.userId,
                                child: Text(driver.fullName),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedDriverId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedConductorId,
                          decoration: const InputDecoration(
                            labelText: 'Select Conductor (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            // Include "None" option
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('None'),
                            ),
                            // Include currently assigned conductor for editing
                            if (_editingAssignment != null && _editingAssignment!.conductorId != null)
                              DropdownMenuItem<int>(
                                value: _editingAssignment!.conductorId,
                                child: Text('${_editingAssignment!.conductorName} (Current)'),
                              ),
                            // Include available conductors
                            ..._availableConductors.map((conductor) {
                              return DropdownMenuItem<int>(
                                value: conductor.userId,
                                child: Text(conductor.fullName),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedConductorId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showAddForm = false;
                                  _editingAssignment = null;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _saveAssignment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3E4795),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(_editingAssignment != null ? 'Update Assignment' : 'Add Assignment'),
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
