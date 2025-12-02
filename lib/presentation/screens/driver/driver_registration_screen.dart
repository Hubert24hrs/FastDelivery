import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DriverRegistrationScreen extends StatefulWidget {
  final String type; // 'driver' or 'courier'

  const DriverRegistrationScreen({super.key, required this.type});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDriver = widget.type == 'driver';
    final title = isDriver ? 'Become a Driver' : 'Become a Courier';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submit Documentation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please fill in the details and upload necessary documents to get verified.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),

              _buildTextField('Full Name'),
              const SizedBox(height: 16),
              _buildTextField('Phone Number'),
              const SizedBox(height: 16),
              _buildTextField('Vehicle Make & Model'),
              const SizedBox(height: 16),
              _buildTextField('Vehicle Year'),
              const SizedBox(height: 16),
              _buildTextField('License Plate Number'),
              
              const SizedBox(height: 32),
              
              const Text(
                'Documents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              
              _buildUploadButton('Driver\'s License'),
              const SizedBox(height: 12),
              _buildUploadButton('Vehicle Registration'),
              const SizedBox(height: 12),
              _buildUploadButton('Insurance Certificate'),
              if (!isDriver) ...[
                const SizedBox(height: 12),
                _buildUploadButton('Courier Permit'),
              ],

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Submit Application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
    );
  }

  Widget _buildUploadButton(String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          const Icon(Icons.upload_file, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const Text(
            'Upload',
            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application Submitted! We will review it shortly.')),
        );
        context.pop(); // Go back to selection
      }
    }
  }
}
