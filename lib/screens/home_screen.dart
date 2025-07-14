import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/controller/quote_controller.dart';
import '/controller/theme_controller.dart';
import '/screens/favorite_screen.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final quoteController = Provider.of<QuoteController>(context);
    final themeController = Provider.of<ThemeController>(context);

    if (quoteController.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(quoteController.errorMessage!),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: quoteController.clearError,
            ),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('InspireMe'),
        actions: [
          IconButton(
            icon: Icon(themeController.themeMode == ThemeMode.light ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: themeController.toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesScreen())),
          ),
        ],
      ),
      body: Consumer<QuoteController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          final quote = controller.currentQuote;
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
                            child: Text(
                              quote.text,
                              key: ValueKey(quote.text),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                                  ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
                          child: Text(
                            quote.author,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8.0,
                          children: [
                            IconButton(
                              icon: Icon(
                                controller.favoriteQuotes.contains(quote)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: controller.favoriteQuotes.contains(quote) ? Colors.red : null,
                              ),
                              onPressed: () => controller.toggleFavorite(quote),
                            ),
                            IconButton(
                              icon: Icon(Icons.share),
                              onPressed: () => Share.share('${quote.text} - ${quote.author}'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    controller.playSound();
                    controller.showNewQuote();
                  },
                  child: Text('Inspire Me'),
                ),
                SizedBox(height: 10),
                Text(
                  'Quotes provided by ZenQuotes.io',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}