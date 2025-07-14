import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/controller/quote_controller.dart';
import 'package:share_plus/share_plus.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Quotes'),
      ),
      body: Consumer<QuoteController>(
        builder: (context, controller, child) {
          if (controller.favoriteQuotes.isEmpty) {
            return Center(child: Text('No favorite quotes yet.'));
          }
          return ListView.builder(
            itemCount: controller.favoriteQuotes.length,
            itemBuilder: (context, index) {
              final quote = controller.favoriteQuotes[index];
              return ListTile(
                title: Text(
                  quote.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(quote.author),
                trailing: Wrap(
                  spacing: 8.0,
                  children: [
                    IconButton(
                      icon: Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => controller.toggleFavorite(quote),
                    ),
                    IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () => Share.share('${quote.text} - ${quote.author}'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}