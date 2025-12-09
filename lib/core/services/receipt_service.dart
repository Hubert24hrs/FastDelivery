import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ReceiptService {
  // Generate PDF receipt for a ride
  Future<String> generateReceipt(RideModel ride) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'FAST DELIVERY',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Trip Receipt',
                  style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                ),
              ),
              pw.Divider(height: 40, thickness: 1, color: PdfColors.grey300),

              // Trip Details
              _buildSection('TRIP DETAILS', [
                _buildRow('Date', dateFormat.format(ride.createdAt)),
                _buildRow('Ride ID', ride.id.substring(0, 8).toUpperCase()),
                _buildRow('Status', ride.status.toUpperCase()),
              ]),

              pw.SizedBox(height: 20),

              // Route
              _buildSection('ROUTE', [
                _buildRow('Pickup', ride.pickupAddress),
                _buildRow('Dropoff', ride.dropoffAddress),
              ]),

              pw.SizedBox(height: 20),

              // Driver Info
              if (ride.driverId != null)
                _buildSection('DRIVER', [
                  _buildRow('Name', ride.driverName ?? 'Driver'),
                  _buildRow('Vehicle', ride.carModel ?? 'N/A'),
                  if (ride.plateNumber != null)
                    _buildRow('Plate', ride.plateNumber!),
                ]),

              pw.SizedBox(height: 20),

              // Payment
              _buildSection('PAYMENT', [
                _buildRow('Fare', '₦${ride.price.toStringAsFixed(2)}'),
                _buildRow('Payment Method', 'Cash'),
              ]),

              pw.Spacer(),

              // Footer
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Thank you for riding with Fast Delivery!',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'support@fastdelivery.ng',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt_${ride.id.substring(0, 8)}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }

  pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 8),
        ...children,
      ],
    );
  }

  pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Flexible(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
