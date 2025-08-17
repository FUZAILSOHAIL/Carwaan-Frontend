import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('Basic Button Widget Test', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: Text('Test Button'),
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
    });

    testWidgets('Text Field Widget Test', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
      
      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();
      
      expect(find.text('test@example.com'), findsOneWidget);
      expect(controller.text, 'test@example.com');
    });

    testWidgets('Form Validation Widget Test', (tester) async {
      final formKey = GlobalKey<FormState>();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState?.validate();
                    },
                    child: Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test empty validation
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('Please enter your email'), findsOneWidget);

      // Test invalid email
      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('Please enter a valid email'), findsOneWidget);

      // Test valid email
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter a valid email'), findsNothing);
    });

    testWidgets('List View Widget Test', (tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3', 'Item 4', 'Item 5'];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(items[index]),
                  leading: Icon(Icons.star),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 5'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNWidgets(5));
    });

    testWidgets('Theme and Colors Widget Test', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.black,
          ),
          home: Scaffold(
            appBar: AppBar(
              title: Text('Test App'),
              backgroundColor: Colors.blue,
            ),
            body: Container(
              color: Colors.black,
              child: Text(
                'Dark Theme Test',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('Dark Theme Test'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.brightness, Brightness.dark);
    });
  });
}
