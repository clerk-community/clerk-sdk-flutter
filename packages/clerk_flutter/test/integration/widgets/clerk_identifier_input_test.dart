import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_identifier_input.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/test_support.dart';

class _IdentifierInputUnderTest extends StatelessWidget {
  const _IdentifierInputUnderTest();

  @override
  Widget build(BuildContext context) {
    return ClerkIdentifierInput(
      onChanged: (_) {},
      strategies: const [clerk.Strategy.emailCode],
    );
  }
}

void main() {
  group('ClerkIdentifierInput email field', () {
    late ClerkAuthState authState;

    setUp(() async {
      authState = await createSignedOutAuthState();
    });

    tearDown(() {
      authState.terminate();
    });

    testWidgets(
      'is configured so the platform cannot rewrite the address',
      (tester) async {
        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authState,
            child: const Material(
              child: SingleChildScrollView(
                child: _IdentifierInputUnderTest(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final field = tester.widget<ClerkTextFormField>(
          find.byKey(const Key('identifier')),
        );

        // An email address is not prose. With autocorrect left on, iOS rewrites
        // a correctly typed address as it is entered -- capitalising a local
        // part that matches a proper noun in its dictionary -- and the
        // identifier then differs by case from the form the back end stores.
        expect(field.autocorrect, isFalse);
        expect(field.textCapitalization, TextCapitalization.none);

        // Without these the platform shows a prose keyboard with no `@`, and
        // cannot offer saved credentials.
        expect(field.keyboardType, TextInputType.emailAddress);
        expect(field.autofillHints, contains(AutofillHints.email));
      },
    );
  });
}
