import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recommendation_model.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'recommendations';

  Future<List<RecommendationModel>> getRecommendations() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs
          .map((doc) => RecommendationModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recommendations: $e');
    }
  }

  Future<List<RecommendationModel>> getRecommendationsByCategory(String category) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .get();
      return snapshot.docs
          .map((doc) => RecommendationModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recommendations by category: $e');
    }
  }

  Future<void> addRecommendation(RecommendationModel recommendation) async {
    try {
      await _firestore.collection(_collection).add(recommendation.toJson());
    } catch (e) {
      throw Exception('Failed to add recommendation: $e');
    }
  }

  Future<void> updateRecommendation(String id, RecommendationModel recommendation) async {
    try {
      await _firestore.collection(_collection).doc(id).update(recommendation.toJson());
    } catch (e) {
      throw Exception('Failed to update recommendation: $e');
    }
  }

  Future<void> deleteRecommendation(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete recommendation: $e');
    }
  }
} 