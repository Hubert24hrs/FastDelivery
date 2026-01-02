// import 'dart:io';
// import 'package:mailer/mailer.dart';
// import 'package:mailer/smtp_server.dart';
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
    // WEB COMPATIBILITY: functionality disabled
    debugPrint('EmailService: sendReceiptEmail called for $recipientEmail. (Disabled for Web Build)');
    return true; /*
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
    } */
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
    // final pdfPath = await _receiptService.generateReceipt(ride);
    // if (kDebugMode) {
    //   debugPrint('Receipt PDF generated at: $pdfPath');
    // }

    return true;
  }

  String _buildEmailHtml(RideModel ride, String? recipientName) {
    return 'HTML Content Placeholder';
  }
}
