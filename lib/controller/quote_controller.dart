import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/Model/quotes.dart';

class QuoteController extends ChangeNotifier {
  Quote _currentQuote = Quote(text: '', author: '');
  List<Quote> _favoriteQuotes = [];
  bool _isLoading = true;
  String? _errorMessage;
  final AudioPlayer audioPlayer = AudioPlayer();
  DateTime? _lastRequestTime;
  int _requestCount = 0;
  static const int _maxRequests = 5;
  static const Duration _rateLimitDuration = Duration(seconds: 30);
  static const String _apiKey = ''; // Replace with your API key if available

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fallback quotes
  static List<Quote> _fallbackQuotes = [
    Quote(text: 'The only way to do great work is to love what you do.', author: 'Steve Jobs'),
    Quote(text: 'Believe you can and you’re halfway there.', author: 'Theodore Roosevelt'),
    Quote(text: 'Success is not final, failure is not fatal.', author: 'Winston Churchill'),
    Quote(text: 'The future belongs to those who believe in the beauty of their dreams.', author: 'Eleanor Roosevelt'),
    Quote(text: 'Do what you can, with what you have, where you are.', author: 'Theodore Roosevelt'),
    Quote(text: 'It does not matter how slowly you go as long as you do not stop.', author: 'Confucius'),
    Quote(text: 'The best way to predict the future is to create it.', author: 'Peter Drucker'),
    Quote(text: 'You miss 100% of the shots you don’t take.', author: 'Wayne Gretzky'),
    Quote(text: 'Life is what happens when you’re busy making other plans.', author: 'John Lennon'),
    Quote(text: 'Strive not to be a success, but rather to be of value.', author: 'Albert Einstein'),
    Quote(text: 'The only limit to our realization of tomorrow is our doubts of today.', author: 'Franklin D. Roosevelt'),
    Quote(text: 'What you get by achieving your goals is not as important as what you become by achieving your goals.', author: 'Zig Ziglar'),
    Quote(text: 'Happiness is not something ready made. It comes from your own actions.', author: 'Dalai Lama'),
    Quote(text: 'The journey of a thousand miles begins with one step.', author: 'Lao Tzu'),
    Quote(text: 'You must be the change you wish to see in the world.', author: 'Mahatma Gandhi'),
    Quote(text: 'In the middle of difficulty lies opportunity.', author: 'Albert Einstein'),
    Quote(text: 'Keep your face always toward the sunshine, and shadows will fall behind you.', author: 'Walt Whitman'),
    Quote(text: 'The only way to discover the limits of the possible is to go beyond them into the impossible.', author: 'Arthur C. Clarke'),
    Quote(text: 'Don’t watch the clock; do what it does. Keep going.', author: 'Sam Levenson'),
    Quote(text: 'Success is walking from failure to failure with no loss of enthusiasm.', author: 'Winston Churchill'),
  ];

  QuoteController() {
    _init();
  }

  Future<void> _init() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await loadFavorites();
    }
    await fetchQuote();
  }

  Quote get currentQuote => _currentQuote;
  List<Quote> get favoriteQuotes => _favoriteQuotes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> _canMakeRequest() async {
    final now = DateTime.now();
    if (_lastRequestTime == null || now.difference(_lastRequestTime!) > _rateLimitDuration) {
      _requestCount = 0;
      _lastRequestTime = now;
    }
    if (_requestCount >= _maxRequests) {
      print('Rate limit exceeded. Waiting...');
      _errorMessage = 'Rate limit exceeded. Please wait a few seconds.';
      notifyListeners();
      return false;
    }
    print('Can make request. Count: $_requestCount');
    return true;
  }

  Future<void> fetchQuote() async {
    if (!(await _canMakeRequest())) return;

    _isLoading = true;
    notifyListeners();
    try {
      final url = _apiKey.isEmpty
          ? 'https://zenquotes.io/api/random'
          : 'https://zenquotes.io/api/random/$_apiKey';
      print('Attempting to fetch quote from: $url');
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      _requestCount++;
      _lastRequestTime = DateTime.now();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          _currentQuote = Quote(text: data[0]['q'], author: data[0]['a']);
          print('Quote fetched: ${_currentQuote.text} - ${_currentQuote.author}');
        } else {
          _currentQuote = _fallbackQuotes[DateTime.now().millisecondsSinceEpoch % _fallbackQuotes.length];
          _errorMessage = 'No quote received from API; using fallback';
          print('Error: No quote data in response');
        }
      } else {
        _currentQuote = _fallbackQuotes[DateTime.now().millisecondsSinceEpoch % _fallbackQuotes.length];
        _errorMessage = 'Server error: ${response.statusCode}; using fallback';
        print('Error: Server responded with status ${response.statusCode}');
      }
    } on SocketException catch (e) {
      _currentQuote = _fallbackQuotes[DateTime.now().millisecondsSinceEpoch % _fallbackQuotes.length];
      _errorMessage = 'No internet connection: $e; using fallback';
      print('SocketException: $e');
    } on http.ClientException catch (e, stackTrace) {
      _currentQuote = _fallbackQuotes[DateTime.now().millisecondsSinceEpoch % _fallbackQuotes.length];
      _errorMessage = 'Network error: $e; using fallback';
      print('ClientException: $e\nStackTrace: $stackTrace');
    } on HttpException catch (e, stackTrace) {
      _currentQuote = _fallbackQuotes[DateTime.now().millisecondsSinceEpoch % _fallbackQuotes.length];
      _errorMessage = 'HTTP error: $e; using fallback';
      print('HttpException: $e\nStackTrace: $stackTrace');
    } catch (e, stackTrace) {
      _currentQuote = _fallbackQuotes[DateTime.now().millisecondsSinceEpoch % _fallbackQuotes.length];
      _errorMessage = 'Unexpected error: $e; using fallback';
      print('Unexpected error: $e\nStackTrace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void showNewQuote() {
    fetchQuote();
  }

  Future<void> toggleFavorite(Quote quote) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = 'Please log in to save favorites';
      print('Error: User not logged in');
      notifyListeners();
      return;
    }

    try {
      final quoteRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorite_quotes')
          .doc('${quote.text}_${quote.author}');
      if (_favoriteQuotes.contains(quote)) {
        _favoriteQuotes.remove(quote);
        await quoteRef.delete();
        print('Removed quote from Firestore: ${quote.text} - ${quote.author} for user ${user.uid}');
      } else {
        _favoriteQuotes.add(quote);
        await quoteRef.set({
          'text': quote.text,
          'author': quote.author,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Added quote to Firestore: ${quote.text} - ${quote.author} for user ${user.uid}');
      }
      notifyListeners();
    } on FirebaseException catch (e) {
      _errorMessage = 'Firestore error: ${e.message} (code: ${e.code})';
      print('FirebaseException: ${e.message}\nCode: ${e.code}');
      notifyListeners();
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to update favorite in Firestore: $e';
      print('Firestore error: $e\nStackTrace: $stackTrace');
      notifyListeners();
    }
  }

  Future<void> loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = 'Please log in to view favorites';
      print('Error: User not logged in');
      notifyListeners();
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorite_quotes')
          .get();
      _favoriteQuotes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Quote(text: data['text'], author: data['author']);
      }).toList();
      print('Loaded ${_favoriteQuotes.length} favorite quotes from Firestore for user ${user.uid}');
      notifyListeners();
    } on FirebaseException catch (e) {
      _errorMessage = 'Firestore error: ${e.message} (code: ${e.code})';
      print('FirebaseException: ${e.message}\nCode: ${e.code}');
      notifyListeners();
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to load favorites from Firestore: $e';
      print('Firestore error: $e\nStackTrace: $stackTrace');
      notifyListeners();
    }
  }

  Future<void> playSound() async {
    try {
      await audioPlayer.play(AssetSource('audio/smooth.mp3'));
    } catch (e) {
      print('Error playing sound: $e');
      _errorMessage = 'Failed to play sound: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}