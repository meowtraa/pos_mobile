import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_view_model.dart';

/// Home Page
/// Main home screen of the application
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POS Mobile'), centerTitle: true),
      body: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('You have pushed the button this many times:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                Text(
                  '${viewModel.counter}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                if (viewModel.isLoading)
                  const CircularProgressIndicator()
                else if (viewModel.isError)
                  Text(viewModel.errorMessage ?? 'An error occurred', style: const TextStyle(color: Colors.red)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<HomeViewModel>().incrementCounter();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
