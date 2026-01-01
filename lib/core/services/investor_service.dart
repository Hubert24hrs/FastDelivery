import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/investor_model.dart';
import '../models/bike_model.dart';
import '../models/hp_agreement_model.dart';
import '../models/investor_earnings_model.dart';

/// Service for investor operations
class InvestorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== INVESTOR PROFILE ====================
  
  /// Create investor profile
  Future<void> createInvestorProfile({
    required String userId,
    required String email,
    String? displayName,
    String? phone,
  }) async {
    final investor = InvestorModel(
      id: userId,
      userId: userId,
      email: email,
      displayName: displayName,
      phone: phone,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('investors')
        .doc(userId)
        .set(investor.toMap());
  }

  /// Get investor profile
  Future<InvestorModel?> getInvestorProfile(String userId) async {
    final doc = await _firestore.collection('investors').doc(userId).get();
    if (!doc.exists) return null;
    return InvestorModel.fromFirestore(doc);
  }

  /// Stream investor profile
  Stream<InvestorModel?> streamInvestorProfile(String userId) {
    return _firestore
        .collection('investors')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? InvestorModel.fromFirestore(doc) : null);
  }

  /// Update investor profile
  Future<void> updateInvestorProfile(String userId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = DateTime.now().toIso8601String();
    await _firestore.collection('investors').doc(userId).update(updates);
  }

  /// Check if user is already an investor
  Future<bool> isInvestor(String userId) async {
    final doc = await _firestore.collection('investors').doc(userId).get();
    return doc.exists;
  }

  // ==================== KYC VERIFICATION ====================

  /// Update KYC status (mock - integrate Paystack Verify in production)
  Future<void> updateKycStatus({
    required String userId,
    required bool bvnVerified,
    required bool ninVerified,
  }) async {
    final kycStatus = (bvnVerified && ninVerified) ? 'verified' : 'pending';
    
    await _firestore.collection('investors').doc(userId).update({
      'bvnVerified': bvnVerified,
      'ninVerified': ninVerified,
      'kycStatus': kycStatus,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    debugPrint('InvestorService: KYC updated for $userId - BVN: $bvnVerified, NIN: $ninVerified');
  }

  /// Update bank details
  Future<void> updateBankDetails({
    required String userId,
    required String bankName,
    required String accountNumber,
    required String accountName,
    String? bankCode,
  }) async {
    await _firestore.collection('investors').doc(userId).update({
      'bankDetails': {
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountName': accountName,
        'bankCode': bankCode,
      },
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ==================== BIKE CAMPAIGNS ====================

  /// Get available bikes needing funding
  Stream<List<BikeModel>> getAvailableBikeCampaigns() {
    return _firestore
        .collection('bikes')
        .where('status', isEqualTo: 'pending_funding')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => BikeModel.fromFirestore(doc)).toList());
  }

  /// Get bikes funded by investor
  Stream<List<BikeModel>> getInvestorBikes(String investorId) {
    return _firestore
        .collection('bikes')
        .where('investorId', isEqualTo: investorId)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => BikeModel.fromFirestore(doc)).toList());
  }

  /// Get single bike details
  Future<BikeModel?> getBike(String bikeId) async {
    final doc = await _firestore.collection('bikes').doc(bikeId).get();
    if (!doc.exists) return null;
    return BikeModel.fromFirestore(doc);
  }

  /// Stream bike location updates
  Stream<BikeModel?> streamBike(String bikeId) {
    return _firestore
        .collection('bikes')
        .doc(bikeId)
        .snapshots()
        .map((doc) => doc.exists ? BikeModel.fromFirestore(doc) : null);
  }

  // ==================== HP AGREEMENTS ====================

  /// Fund a bike (create HP agreement)
  Future<HPAgreementModel> fundBike({
    required String investorId,
    required String bikeId,
    required double principalAmount,
    required double interestRate,
    required int termMonths,
  }) async {
    // Generate agreement ID
    final agreementId = '${bikeId}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Calculate HP terms
    final agreement = HPAgreementModel.calculate(
      id: agreementId,
      bikeId: bikeId,
      investorId: investorId,
      principalAmount: principalAmount,
      interestRate: interestRate,
      termMonths: termMonths,
    );

    // Create agreement
    await _firestore
        .collection('hp_agreements')
        .doc(agreementId)
        .set(agreement.toMap());

    // Update bike status
    await _firestore.collection('bikes').doc(bikeId).update({
      'investorId': investorId,
      'status': 'funded',
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Update investor stats
    await _firestore.collection('investors').doc(investorId).update({
      'totalInvested': FieldValue.increment(principalAmount),
      'activeBikes': FieldValue.increment(1),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    debugPrint('InvestorService: Bike $bikeId funded by $investorId for ₦$principalAmount');
    
    return agreement;
  }

  /// Get HP agreement for a bike
  Future<HPAgreementModel?> getHPAgreement(String bikeId) async {
    final snapshot = await _firestore
        .collection('hp_agreements')
        .where('bikeId', isEqualTo: bikeId)
        .where('status', whereIn: ['pending_rider', 'active'])
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return HPAgreementModel.fromFirestore(snapshot.docs.first);
  }

  /// Get all HP agreements for investor
  Stream<List<HPAgreementModel>> getInvestorAgreements(String investorId) {
    return _firestore
        .collection('hp_agreements')
        .where('investorId', isEqualTo: investorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => HPAgreementModel.fromFirestore(doc)).toList());
  }

  /// Sign HP agreement (investor)
  Future<void> signAgreementAsInvestor({
    required String agreementId,
    required String signatureUrl,
  }) async {
    await _firestore.collection('hp_agreements').doc(agreementId).update({
      'investorSignatureUrl': signatureUrl,
      'investorSignedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ==================== EARNINGS ====================

  /// Get investor earnings stream
  Stream<List<InvestorEarningsModel>> getInvestorEarnings(String investorId) {
    return _firestore
        .collection('investor_earnings')
        .where('investorId', isEqualTo: investorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => InvestorEarningsModel.fromFirestore(doc)).toList());
  }

  /// Get earnings summary for investor
  Future<Map<String, double>> getEarningsSummary(String investorId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await _firestore
        .collection('investor_earnings')
        .where('investorId', isEqualTo: investorId)
        .get();

    double today = 0, week = 0, month = 0, total = 0;
    int ridesCount = 0;

    for (var doc in snapshot.docs) {
      final earning = InvestorEarningsModel.fromFirestore(doc);
      total += earning.hpDeduction;
      ridesCount++;

      if (earning.createdAt.isAfter(startOfDay)) {
        today += earning.hpDeduction;
      }
      if (earning.createdAt.isAfter(startOfWeek)) {
        week += earning.hpDeduction;
      }
      if (earning.createdAt.isAfter(startOfMonth)) {
        month += earning.hpDeduction;
      }
    }

    return {
      'today': today,
      'week': week,
      'month': month,
      'total': total,
      'ridesCount': ridesCount.toDouble(),
    };
  }

  // ==================== WITHDRAWALS ====================

  /// Request withdrawal (min ₦5,000, max ₦500,000 daily)
  Future<InvestorWithdrawalModel> requestWithdrawal({
    required String investorId,
    required double amount,
  }) async {
    // Validate amount
    if (amount < 5000) {
      throw Exception('Minimum withdrawal amount is ₦5,000');
    }
    if (amount > 500000) {
      throw Exception('Maximum daily withdrawal is ₦500,000');
    }

    // Get investor profile
    final investor = await getInvestorProfile(investorId);
    if (investor == null) {
      throw Exception('Investor profile not found');
    }

    if (amount > investor.walletBalance) {
      throw Exception('Insufficient balance. Available: ₦${investor.walletBalance.toStringAsFixed(2)}');
    }

    if (investor.bankDetails == null) {
      throw Exception('Please add bank details before withdrawing');
    }

    // Check daily withdrawal limit
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final todayWithdrawals = await _firestore
        .collection('investor_withdrawals')
        .where('investorId', isEqualTo: investorId)
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .get();

    double todayTotal = 0;
    for (var doc in todayWithdrawals.docs) {
      todayTotal += (doc.data()['amount'] ?? 0.0).toDouble();
    }

    if (todayTotal + amount > 500000) {
      throw Exception('Daily withdrawal limit exceeded. Remaining today: ₦${(500000 - todayTotal).toStringAsFixed(2)}');
    }

    // Create withdrawal request
    final withdrawalId = DateTime.now().millisecondsSinceEpoch.toString();
    final withdrawal = InvestorWithdrawalModel(
      id: withdrawalId,
      investorId: investorId,
      amount: amount,
      bankName: investor.bankDetails!.bankName,
      accountNumber: investor.bankDetails!.accountNumber,
      accountName: investor.bankDetails!.accountName,
      status: 'processing',
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('investor_withdrawals')
        .doc(withdrawalId)
        .set(withdrawal.toMap());

    // Deduct from wallet balance
    await _firestore.collection('investors').doc(investorId).update({
      'walletBalance': FieldValue.increment(-amount),
      'totalWithdrawn': FieldValue.increment(amount),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // TODO: Call Paystack Transfer API here
    // For now, simulate completion after 2 seconds
    Future.delayed(const Duration(seconds: 2), () async {
      await _firestore.collection('investor_withdrawals').doc(withdrawalId).update({
        'status': 'completed',
        'paystackReference': 'MOCK_${withdrawalId}',
        'completedAt': DateTime.now().toIso8601String(),
      });
    });

    debugPrint('InvestorService: Withdrawal of ₦$amount requested for $investorId');

    return withdrawal;
  }

  /// Get withdrawal history
  Stream<List<InvestorWithdrawalModel>> getWithdrawalHistory(String investorId) {
    return _firestore
        .collection('investor_withdrawals')
        .where('investorId', isEqualTo: investorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => InvestorWithdrawalModel.fromFirestore(doc)).toList());
  }

  // ==================== AI INSIGHTS ====================

  /// Get AI insights for investor portfolio
  Future<List<Map<String, dynamic>>> getAIInsights(String investorId) async {
    final bikes = await _firestore
        .collection('bikes')
        .where('investorId', isEqualTo: investorId)
        .get();

    final insights = <Map<String, dynamic>>[];

    for (var bikeDoc in bikes.docs) {
      final bike = BikeModel.fromFirestore(bikeDoc);
      
      // Get recent earnings for this bike
      final earnings = await _firestore
          .collection('investor_earnings')
          .where('bikeId', isEqualTo: bike.id)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      if (earnings.docs.isEmpty) {
        insights.add({
          'bikeId': bike.id,
          'bikeName': bike.displayName,
          'type': 'warning',
          'title': 'Low Activity',
          'message': 'No rides recorded in the last 30 days. Consider contacting the rider.',
          'icon': 'warning',
        });
        continue;
      }

      // Calculate average daily earnings
      double totalEarnings = 0;
      for (var doc in earnings.docs) {
        totalEarnings += (doc.data()['hpDeduction'] ?? 0.0).toDouble();
      }
      final avgDaily = totalEarnings / 30;

      if (avgDaily < 3000) {
        insights.add({
          'bikeId': bike.id,
          'bikeName': bike.displayName,
          'type': 'tip',
          'title': 'Optimization Needed',
          'message': 'Daily average ₦${avgDaily.toStringAsFixed(0)} is below target. Suggest rider focus on peak hours.',
          'icon': 'lightbulb',
        });
      } else {
        insights.add({
          'bikeId': bike.id,
          'bikeName': bike.displayName,
          'type': 'success',
          'title': 'Strong Performance',
          'message': 'Daily average ₦${avgDaily.toStringAsFixed(0)} is on track for HP completion.',
          'icon': 'trending_up',
        });
      }

      // Check maintenance alerts
      if (bike.hasActiveAlerts) {
        insights.add({
          'bikeId': bike.id,
          'bikeName': bike.displayName,
          'type': 'alert',
          'title': 'Maintenance Required',
          'message': '${bike.maintenanceAlerts.where((a) => !a.isResolved).length} pending maintenance items.',
          'icon': 'build',
        });
      }
    }

    return insights;
  }
}

/// Provider for InvestorService
final investorServiceProvider = Provider<InvestorService>((ref) {
  return InvestorService();
});
