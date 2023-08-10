// ignore: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

class UserReviewsPage extends StatefulWidget {
  const UserReviewsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UserReviewsPageState createState() => _UserReviewsPageState();
}

class _UserReviewsPageState extends State<UserReviewsPage> {
  final Map<String, String?> sentimentCache = {};

  Future<String?> analyzeSentiment(String text) async {
    if (sentimentCache.containsKey(text)) {
      return sentimentCache[text];
    }

    const apiKey = '63f21928c212015777987befc37ee6f1';
    const url = 'https://api.meaningcloud.com/sentiment-2.1';

    final response = await http.post(
      Uri.parse('$url?key=$apiKey&of=json&txt=$text'),
    );

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      // ignore: avoid_print
      print('Response Body: $decodedResponse');

      final agreement = decodedResponse['agreement'];
      final subjectivity = decodedResponse['subjectivity'];
      final irony = decodedResponse['irony'];
      final scoreTag = decodedResponse['score_tag'];

      final sentimentAnalysis = 'Agreement: $agreement\n'
          'Subjectivity: $subjectivity\n'
          'Irony: $irony\n'
          'Score Tag: $scoreTag';

      sentimentCache[text] = sentimentAnalysis;

      return sentimentAnalysis;
    } else {
      // ignore: avoid_print
      print('Request Error: ${response.body}');
      throw Exception(
          'Failed to analyze sentiment. Error code: ${response.statusCode}');
    }
  }

  Future<void> _refreshPage() async {
    // Implement the logic to refresh the page
    // For example, you can fetch new data or reset the cache
    setState(() {
      sentimentCache.clear();
    });
  }

  Future<void> _confirmDeleteReviews() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('reviews').get();

    if (snapshot.docs.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No reviews to delete',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } else {
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete All Reviews'),
            content: const Text('Are you sure you want to delete all reviews?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _deleteAllReviews();
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _deleteAllReviews() {
    FirebaseFirestore.instance.collection('reviews').get().then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        for (DocumentSnapshot doc in snapshot.docs) {
          doc.reference.delete();
        }
        Fluttertoast.showToast(
          msg: 'All reviews deleted',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final reviews = snapshot.data!.docs;

              if (reviews.isNotEmpty) {
                return ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review =
                        reviews[index].data() as Map<String, dynamic>;

                    // Extract the review data
                    double? rating = review['rating'] as double?;
                    String? reviewText = review['review'] as String?;
                    String? fullName = review['fullName'] as String?;
                    String? userEmail = review['userEmail'] as String?;
                    String? eateryName = review['eateryName'] as String?;

                    if (reviewText != null && reviewText.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: Dismissible(
                          key: Key(reviews[index].id),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16.0),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            FirebaseFirestore.instance
                                .collection('reviews')
                                .doc(reviews[index].id)
                                .delete();
                          },
                          child: SizedBox(
                            width: double.infinity,
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Eatery Name: ${eateryName ?? 'No eatery name available'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'User Email: ${userEmail ?? 'No email available'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Full Name: ${fullName ?? 'No name available'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Rating: ${rating?.toString() ?? 'No rating available'}',
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Review: $reviewText',
                                    ),
                                    const SizedBox(height: 8),
                                    FutureBuilder<String?>(
                                      future: analyzeSentiment(reviewText),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        } else if (snapshot.hasError) {
                                          return Text(
                                              'Failed to analyze sentiment: ${snapshot.error}');
                                        } else {
                                          final sentimentAnalysis =
                                              snapshot.data;
                                          if (sentimentAnalysis != null) {
                                            return Text(
                                                'Sentiment Analysis:\n$sentimentAnalysis');
                                          } else {
                                            return const Text(
                                                'No sentiment analysis available');
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Container();
                    }
                  },
                );
              } else {
                return const Center(
                  child: Text('No reviews found.'),
                );
              }
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _confirmDeleteReviews,
        child: const Icon(Icons.delete),
      ),
    );
  }
}
