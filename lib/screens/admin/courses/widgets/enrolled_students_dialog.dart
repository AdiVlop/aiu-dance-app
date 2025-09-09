import 'package:flutter/material.dart';
import '../../../../models/course_model.dart';

class EnrolledStudentsDialog extends StatelessWidget {
  final CourseModel course;

  const EnrolledStudentsDialog({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    // Mock enrolled students data
    final enrolledStudents = [
      {
        'id': '1',
        'name': 'Maria Popescu',
        'email': 'maria.popescu@email.com',
        'phone': '+40 721 123 456',
        'enrollmentDate': DateTime.now().subtract(const Duration(days: 5)),
        'paymentStatus': 'Paid',
        'paymentMethod': 'Wallet',
        'paidAmount': 150.0,
        'remainingAmount': 0.0,
      },
      {
        'id': '2',
        'name': 'Alexandru Ionescu',
        'email': 'alexandru.ionescu@email.com',
        'phone': '+40 722 234 567',
        'enrollmentDate': DateTime.now().subtract(const Duration(days: 3)),
        'paymentStatus': 'Paid',
        'paymentMethod': 'Card',
        'paidAmount': 150.0,
        'remainingAmount': 0.0,
      },
      {
        'id': '3',
        'name': 'Elena Dumitrescu',
        'email': 'elena.dumitrescu@email.com',
        'phone': '+40 723 345 678',
        'enrollmentDate': DateTime.now().subtract(const Duration(days: 1)),
        'paymentStatus': 'Pending',
        'paymentMethod': 'Wallet',
        'paidAmount': 150.0 * 0.5,
        'remainingAmount': 150.0 * 0.5,
      },
    ];

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Studenți înscriși - ${course.title}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Statistics
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total înscriși: ${enrolledStudents.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Plăți complete: ${enrolledStudents.where((s) => s['paymentStatus'] == 'Paid').length}',
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total încasat: ${enrolledStudents.fold(0.0, (sum, s) => sum + (s['paidAmount'] as double)).toStringAsFixed(2)} RON',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Restant: ${enrolledStudents.fold(0.0, (sum, s) => sum + (s['remainingAmount'] as double)).toStringAsFixed(2)} RON',
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Students list
            Expanded(
              child: ListView.builder(
                itemCount: enrolledStudents.length,
                itemBuilder: (context, index) {
                  final student = enrolledStudents[index];
                  final isPaid = student['paymentStatus'] == 'Paid';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                        child: Icon(
                          isPaid ? Icons.check : Icons.pending,
                          color: isPaid ? Colors.green.shade600 : Colors.orange.shade600,
                        ),
                      ),
                      title: Text(student['name'] as String),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student['email'] as String),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isPaid ? 'Plătit' : 'În așteptare',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(student['paidAmount'] as double).toStringAsFixed(2)} RON',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showStudentDetails(context, student),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalii ${student['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${student['email']}'),
            const SizedBox(height: 8),
            Text('Telefon: ${student['phone']}'),
            const SizedBox(height: 8),
            Text('Data înscrierii: ${(student['enrollmentDate'] as DateTime).toString().split(' ')[0]}'),
            const SizedBox(height: 8),
            Text('Status plată: ${student['paymentStatus']}'),
            const SizedBox(height: 8),
            Text('Metodă plată: ${student['paymentMethod']}'),
            const SizedBox(height: 8),
            Text('Suma plătită: ${(student['paidAmount'] as double).toStringAsFixed(2)} RON'),
            const SizedBox(height: 8),
            Text('Restant: ${(student['remainingAmount'] as double).toStringAsFixed(2)} RON'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Închide'),
          ),
        ],
      ),
    );
  }
}

