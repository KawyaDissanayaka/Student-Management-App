import 'package:flutter/material.dart';
import '../../models/hall_model.dart';
import '../../services/hall_service.dart';

class AddEditHallScreen extends StatefulWidget {
  final HallModel? hall;

  const AddEditHallScreen({super.key, this.hall});

  @override
  State<AddEditHallScreen> createState() => _AddEditHallScreenState();
}

class _AddEditHallScreenState extends State<AddEditHallScreen> {
  final _formKey = GlobalKey<FormState>();
  final HallService _hallService = HallService();

  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _buildingController;
  late TextEditingController _floorController;
  late TextEditingController _capacityController;

  String _selectedType = 'Lecture Hall';
  String _selectedStatus = 'active';
  final List<String> _selectedFacilities = [];

  final List<String> _availableTypes = ['Lecture Hall', 'Laboratory', 'Computer Lab', 'Auditorium'];
  final List<String> _availableFacilities = ['Projector', 'Computers', 'Wi-Fi', 'Air Conditioning', 'Audio System', 'Smart Board'];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final h = widget.hall;
    _idController = TextEditingController(text: h?.hallId ?? 'HALL-0${DateTime.now().millisecond % 90 + 10}');
    _nameController = TextEditingController(text: h?.name ?? '');
    _buildingController = TextEditingController(text: h?.building ?? 'Building B (Tech Block)');
    _floorController = TextEditingController(text: h?.floor ?? '1st Floor');
    _capacityController = TextEditingController(text: h != null ? '${h.capacity}' : '60');
    _selectedType = h?.type ?? 'Lecture Hall';
    _selectedStatus = h?.status ?? 'active';
    if (h != null) {
      _selectedFacilities.addAll(h.facilities);
    } else {
      _selectedFacilities.addAll(['Projector', 'Wi-Fi', 'Air Conditioning']);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _saveHall() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final hall = HallModel(
        docId: widget.hall?.docId,
        hallId: _idController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        building: _buildingController.text.trim(),
        floor: _floorController.text.trim(),
        capacity: int.tryParse(_capacityController.text.trim()) ?? 50,
        type: _selectedType,
        facilities: _selectedFacilities,
        status: _selectedStatus,
      );

      if (widget.hall == null) {
        await _hallService.addHall(hall);
        messenger.showSnackBar(
          const SnackBar(content: Text('Lecture Hall registered successfully!'), backgroundColor: Colors.green),
        );
      } else {
        await _hallService.updateHall(widget.hall!.docId!, hall);
        messenger.showSnackBar(
          const SnackBar(content: Text('Lecture Hall updated successfully!'), backgroundColor: Colors.green),
        );
      }

      nav.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.hall != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Lecture Hall' : 'Add New Lecture Hall',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hall ID & Name
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _idController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Hall ID *',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Hall / Lab Name *',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Building & Floor
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _buildingController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Building Complex *',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _floorController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Floor Level *',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Capacity & Type
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Seat Capacity *',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.people_outline, color: Colors.tealAccent),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Valid > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Space Type',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _availableTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Facilities Multi-Select Chips
              const Text('Available Facilities & Equipment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableFacilities.map((fac) {
                  final isSelected = _selectedFacilities.contains(fac);
                  return FilterChip(
                    label: Text(fac),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFacilities.add(fac);
                        } else {
                          _selectedFacilities.remove(fac);
                        }
                      });
                    },
                    selectedColor: Colors.teal,
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(color: isSelected ? Colors.tealAccent : Colors.white10),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Operational Status
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Operational Status',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active (Ready for Lectures)', style: TextStyle(color: Colors.greenAccent))),
                  DropdownMenuItem(value: 'maintenance', child: Text('Under Maintenance', style: TextStyle(color: Colors.orangeAccent))),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive (Decommissioned)', style: TextStyle(color: Colors.redAccent))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _saveHall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    isEditing ? 'Update Lecture Hall' : 'Save & Register Hall',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
