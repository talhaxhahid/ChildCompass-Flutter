import 'package:childcompass/provider/parent_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/parent/parent_api_service.dart';

class SpeedLimitScreen extends ConsumerStatefulWidget {

  const SpeedLimitScreen({super.key});

  @override
  ConsumerState<SpeedLimitScreen> createState() => _SpeedLimitScreenState();
}

class _SpeedLimitScreenState extends ConsumerState<SpeedLimitScreen> {


  final _formKey = GlobalKey<FormState>();
  late int _speedLimit ;
  bool _isSubmitting = false;
  void initState() {
    // TODO: implement initState
    super.initState();
    _speedLimit = ref.read(speedlimitProvider);
  }
  Future<void> _submitSpeedLimit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final parentApiService _apiService = parentApiService();

      try {
        final response = await _apiService.setSpeedLimit(
          ref.read(currentChildProvider)!
            ,_speedLimit
        );

        if (response['success'] == true) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Speed limit set to $_speedLimit km/h'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          ref.read(speedlimitProvider.notifier).state=_speedLimit;

        } else {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to set Speed Limit')),
          );
        }
      } catch (e) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred')),
        );
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF373E4E),
        title: const Text(
          'Set Speed Limit',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
            fontFamily: "Quantico",
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const SizedBox(height: 10),

              Text(
                'You will be notified if child exceed this speed limit.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Visual Speed Indicator
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF373E4E),Color(0xFF373E4E),Color(0xFF373E4E),Color(0xFF373E4E)
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade900.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_speedLimit',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'km/h',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Speed Input Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Slider alternative
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adjust speed limit:',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _speedLimit.toDouble(),
                          min: 10,
                          max: 200,
                          divisions: 38,
                          label: '$_speedLimit km/h',
                          onChanged: (value) {
                            setState(() => _speedLimit = value.round());
                          },
                          activeColor: _getSpeedColor(_speedLimit),
                          inactiveColor: Colors.grey.shade800,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '10 km/h',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                            Text(
                              '200 km/h',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitSpeedLimit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF373E4E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Color(0xFF373E4E)
                              .withOpacity(0.5),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          'SET SPEED LIMIT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSpeedColor(int speed) {
    if (speed < 40) return Colors.green;
    if (speed < 80) return Colors.blue;
    if (speed < 120) return Colors.orange;
    return Colors.red;
  }
}