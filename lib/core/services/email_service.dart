import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/services/receipt_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  // SMTP Configuration loaded from environment variables
  String get _smtpHost => dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
  int get _smtpPort => int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;
  String get _smtpUsername => dotenv.env['SMTP_USERNAME'] ?? '';
  String get _smtpPassword => dotenv.env['SMTP_PASSWORD'] ?? '';
  String get _senderName => dotenv.env['SENDER_NAME'] ?? 'Fast Delivery';
  String get _senderEmail => dotenv.env['SENDER_EMAIL'] ?? 'noreply@fastdelivery.ng';

  final ReceiptService _receiptService = ReceiptService();

  // Send receipt email
  Future<bool> sendReceiptEmail({
    required String recipientEmail,
    required RideModel ride,
    String? recipientName,
  }) async {
    try {
      // Generate PDF receipt
      final pdfPath = await _receiptService.generateReceipt(ride);
      final pdfFile = File(pdfPath);

      if (!await pdfFile.exists()) {
        throw Exception('Failed to generate receipt PDF');
      }

      // Configure SMTP server
      // Note: For Gmail, you need to use App Passwords with 2FA enabled
      final smtpServer = gmail(_smtpUsername, _smtpPassword);

      // Create the email message
      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(recipientEmail)
        ..subject = 'Your Fast Delivery Trip Receipt - ${ride.id.substring(0, 8).toUpperCase()}'
        ..html = _buildEmailHtml(ride, recipientName)
        ..attachments = [FileAttachment(pdfFile, fileName: 'receipt_${ride.id.substring(0, 8)}.pdf')];

      // Send the email
      final sendReport = await send(message, smtpServer);
      
      if (kDebugMode) {
        debugPrint('Email sent: ${sendReport.toString()}');
      }

      return true;
    } on MailerException catch (e) {
      if (kDebugMode) {
        debugPrint('Email sending failed: ${e.message}');
        for (var p in e.problems) {
          debugPrint('Problem: ${p.code}: ${p.msg}');
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Email error: $e');
      }
      return false;
    }
  }

  // Mock email sending for testing (doesn't require SMTP)
  Future<bool> sendReceiptEmailMock({
    required String recipientEmail,
    required RideModel ride,
    String? recipientName,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (kDebugMode) {
      debugPrint('=== MOCK EMAIL SENT ===');
      debugPrint('To: $recipientEmail');
      debugPrint('Subject: Your Fast Delivery Trip Receipt - ${ride.id.substring(0, 8).toUpperCase()}');
      debugPrint('Attachment: receipt_${ride.id.substring(0, 8)}.pdf');
      debugPrint('========================');
    }

    // Generate the PDF anyway so we can show the path
    final pdfPath = await _receiptService.generateReceipt(ride);
    if (kDebugMode) {
      debugPrint('Receipt PDF generated at: $pdfPath');
    }

    return true;
  }

  String _buildEmailHtml(RideModel ride, String? recipientName) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #00D26A 0%, #00A854 100%); padding: 30px; text-align: center; border-radius: 12px 12px 0 0; }
        .header h1 { color: white; margin: 0; font-size: 24px; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 12px 12px; }
        .trip-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .trip-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #eee; }
        .trip-row:last-child { border-bottom: none; }
        .price { font-size: 32px; font-weight: bold; color: #00D26A; text-align: center; margin: 20px 0; }
        .footer { text-align: center; color: #888; font-size: 12px; margin-top: 20px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🚗 Fast Delivery</h1>
          <p style="color: white; margin: 10px 0 0 0;">Trip Receipt</p>
        </div>
        <div class="content">
          <p>Hi ${recipientName ?? 'there'},</p>
          <p>Thank you for riding with Fast Delivery! Here's your trip summary:</p>
          
          <div class="price">₦${ride.price.toStringAsFixed(0)}</div>
          
          <div class="trip-details">
            <div class="trip-row">
              <span><strong>Trip ID</strong></span>
              <span>${ride.id.substring(0, 8).toUpperCase()}</span>
            </div>
            <div class="trip-row">
              <span><strong>Pickup</strong></span>
              <span>${ride.pickupAddress}</span>
            </div>
            <div class="trip-row">
              <span><strong>Dropoff</strong></span>
              <span>${ride.dropoffAddress}</span>
            </div>
            ${ride.driverName != null ? '''
            <div class="trip-row">
              <span><strong>Driver</strong></span>
              <span>${ride.driverName}</span>
            </div>
            ''' : ''}
          </div>
          
          <p>Your PDF receipt is attached to this email.</p>
          
          <div class="footer">
            <p>© ${DateTime.now().year} Fast Delivery. All rights reserved.</p>
            <p>Need help? Contact us at support@fastdelivery.ng</p>
          </div>
        </div>
      </div>
    </body>
    </html>
    ''';
  }
}
