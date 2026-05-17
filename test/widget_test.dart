import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:offline_mesh_app/app.dart';
import 'package:offline_mesh_app/services/mesh_store.dart';

void main() {
  testWidgets('App boots into the mesh dashboard', (WidgetTester tester) async {
    final MeshStore store = MeshStore();

    await tester.pumpWidget(MeshAppRoot(store: store));
    await tester.pumpAndSettle();

    expect(find.textContaining('Offline Mesh'), findsWidgets);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
