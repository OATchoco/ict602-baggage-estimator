import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const appTitle = 'Excess Baggage Estimator';
const authorName = 'Muhammad Afiq bin Azman';
const course = 'ICT602 • Mobile Technology';
const programme = 'CDCS251 • Netcentric Computing';

const matricNumber = '2025229238';
const profileUrl = 'https://github.com/OATchoco';
const repositoryUrl = 'https://github.com/OATchoco/ict602-baggage-estimator';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF12374A);
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007A73)),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const HomePage(),
    );
  }
}

enum TicketClass {
  economy('Economy', 20),
  business('Business', 40);

  const TicketClass(this.label, this.allowanceKg);
  final String label;
  final int allowanceKg;
}

class FeeEstimate {
  const FeeEstimate(this.excessKg, this.charge);

  final double excessKg;
  final double charge;
  double get tax => charge * 0.08;
  double get total => charge + tax;

  factory FeeEstimate.calculate(
    double weight,
    TicketClass ticket,
    double rate,
  ) {
    final excess = math.max(0.0, weight - ticket.allowanceKg);
    return FeeEstimate(excess, excess * rate);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final formKey = GlobalKey<FormState>();
  final weight = TextEditingController();
  final rate = TextEditingController();
  TicketClass ticket = TicketClass.economy;
  FeeEstimate? estimate;

  @override
  void dispose() {
    weight.dispose();
    rate.dispose();
    super.dispose();
  }

  String? validateNumber(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter the $label.';
    final number = double.tryParse(text);
    if (number == null || !number.isFinite || number < 0) {
      return 'Enter a number of zero or more.';
    }
    return null;
  }

  void clearEstimate(String _) {
    if (estimate != null) setState(() => estimate = null);
  }

  void calculate() {
    if (!formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final result = FeeEstimate.calculate(
      double.parse(weight.text.trim()),
      ticket,
      double.parse(rate.text.trim()),
    );
    if (!result.total.isFinite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('These values are too large to calculate.'),
        ),
      );
      return;
    }
    setState(() => estimate = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appTitle)),
      drawer: const AppMenu(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Checked baggage',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose your ticket class and enter your baggage weight and excess rate.',
            ),
            const SizedBox(height: 20),
            Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ticket class',
                      prefixIcon: Icon(Icons.airplane_ticket_outlined),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TicketClass>(
                        value: ticket,
                        isDense: true,
                        isExpanded: true,
                        items: [
                          for (final item in TicketClass.values)
                            DropdownMenuItem(
                              value: item,
                              child: Text(
                                '${item.label} (${item.allowanceKg} kg)',
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            ticket = value;
                            estimate = null;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: weight,
                    decoration: const InputDecoration(
                      labelText: 'Checked baggage weight',
                      hintText: 'e.g. 42.5',
                      suffixText: 'kg',
                      prefixIcon: Icon(Icons.luggage_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        validateNumber(value, 'baggage weight'),
                    onChanged: clearEstimate,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: rate,
                    decoration: const InputDecoration(
                      labelText: 'Excess rate per kg',
                      hintText: 'e.g. 12.00',
                      prefixText: 'RM ',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (value) => validateNumber(value, 'rate per kg'),
                    onChanged: clearEstimate,
                    onFieldSubmitted: (_) => calculate(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The first ${ticket.allowanceKg} kg is included. '
                    'An 8% service tax applies to the excess charge.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: calculate,
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Calculate fee'),
                  ),
                ],
              ),
            ),
            if (estimate != null) EstimateCard(result: estimate!),
          ],
        ),
      ),
    );
  }
}

class EstimateCard extends StatelessWidget {
  const EstimateCard({super.key, required this.result});
  final FeeEstimate result;

  @override
  Widget build(BuildContext context) {
    String money(double value) => 'RM ${value.toStringAsFixed(2)}';
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 20),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fee estimate', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (result.excessKg == 0)
              const Text('Your baggage is within the allowance.'),
            Text(
              'Excess baggage weight: ${result.excessKg.toStringAsFixed(2)} kg',
            ),
            Text('Excess baggage charge: ${money(result.charge)}'),
            Text('Service tax (8%): ${money(result.tax)}'),
            const Divider(),
            Text(
              'Total amount payable: ${money(result.total)}',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class AppMenu extends StatelessWidget {
  const AppMenu({super.key, this.onAboutPage = false});
  final bool onAboutPage;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(leading: Icon(Icons.luggage), title: Text(appTitle)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              selected: !onAboutPage,
              onTap: () {
                navigator.pop(); // Close the menu.
                if (onAboutPage)
                  navigator.pop(); // Return to the existing estimate.
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              selected: onAboutPage,
              onTap: () {
                navigator.pop();
                if (!onAboutPage) {
                  navigator.push(
                    MaterialPageRoute<void>(builder: (_) => const AboutPage()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> openGitHub(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication))
        return;
    } on Exception {
      // Use the same message if the platform cannot open the browser.
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open the GitHub link.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final githubUrl = repositoryUrl.isEmpty ? profileUrl : repositoryUrl;
    return Scaffold(
      appBar: AppBar(title: const Text(appTitle)),
      drawer: const AppMenu(onAboutPage: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: const Icon(Icons.luggage, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            Text('About this app', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Author'),
              subtitle: Text(authorName),
            ),
            const ListTile(
              leading: Icon(Icons.badge_outlined),
              title: Text('Matric number'),
              subtitle: Text(matricNumber),
            ),
            const ListTile(
              leading: Icon(Icons.school_outlined),
              title: Text('Course'),
              subtitle: Text('$course\n$programme'),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: Text(
                repositoryUrl.isEmpty ? 'GitHub profile' : 'GitHub repository',
              ),
              subtitle: Text(githubUrl),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => openGitHub(context, githubUrl),
            ),
            const Divider(),
            const Text('© 2026 $authorName. All rights reserved.'),
          ],
        ),
      ),
    );
  }
}
