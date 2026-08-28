import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/cloudinary_config.dart';
import '../models/product.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'admin_shell.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(currentAdminProvider).valueOrNull;
    final user = ref.watch(authStateProvider).valueOrNull;
    final products = ref.watch(productsProvider).valueOrNull ?? const <AdminProduct>[];
    final orders = ref.watch(ordersProvider).valueOrNull ?? const [];
    final customers = ref.watch(customersProvider).valueOrNull ?? const [];

    return AdminPage(
      children: [
        const PageHeader(
          title: 'Settings',
          subtitle: 'Your account and how this console connects to the store',
        ),
        PanelCard(
          title: 'Signed in as',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AdminColors.primary,
                    child: Text(
                      admin?.initials ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          admin?.name ?? 'Admin',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AdminColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Pill(
                    label: admin?.role ?? 'admin',
                    color: AdminColors.primary,
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(adminAuthServiceProvider).signOut(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Store at a glance',
          child: Wrap(
            spacing: 28,
            runSpacing: 16,
            children: [
              _Figure('Products', '${products.length}'),
              _Figure(
                'Live in app',
                '${products.where((p) => p.active).length}',
              ),
              _Figure('Orders', '${orders.length}'),
              _Figure('Customers', '${customers.length}'),
              _Figure(
                'Stock value',
                Money.compact(
                  products.fold<double>(0, (total, p) => total + p.price * p.stock),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AdminAccessCard(uid: user?.uid ?? ''),
        const SizedBox(height: 16),
        const _ConnectionCard(),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: AdminColors.textGrey),
        ),
      ],
    );
  }
}

/// How to add another admin — the one operation that cannot be done from
/// inside the console, because granting admin rights from an admin UI is how
/// a compromised session escalates.
class _AdminAccessCard extends StatelessWidget {
  const _AdminAccessCard({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    const snippet = 'admins/{their-uid}\n'
        '  name: "Staff name"\n'
        '  email: "staff@example.com"\n'
        '  role: "manager"\n'
        '  active: true';

    return PanelCard(
      title: 'Adding another admin',
      subtitle: 'Done in the Firebase console, on purpose',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Anyone who should use this console needs two things: a Firebase '
            'Authentication account, and a document under the admins collection '
            'keyed by their user ID. Flip active to false to revoke access — '
            'their open session is cut off immediately.',
            style: TextStyle(fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 14),
          _CodeBlock(text: snippet),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Your user ID:',
                style: TextStyle(fontSize: 12.5, color: AdminColors.textGrey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  uid,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy, size: 17),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: uid));
                  showToast(context, 'User ID copied.');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard();

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      title: 'Connection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _KeyValue('Firebase project', 'c2b-shopping-app'),
          _KeyValue('Products', 'products/{id}'),
          _KeyValue('Sections', 'sections/{id}'),
          _KeyValue('Orders', 'orders/{id}'),
          _KeyValue('Customers', 'users/{uid}'),
          _KeyValue('Admins', 'admins/{uid}'),
          _PhotoStorageRow(),
        ],
      ),
    );
  }
}

/// Where photos go, and whether that is actually set up.
///
/// Worth a line of its own because it is the one piece of this console that is
/// configured outside Firebase, and a missing cloud name shows up otherwise
/// only as a failed upload halfway through adding a product.
class _PhotoStorageRow extends StatelessWidget {
  const _PhotoStorageRow();

  @override
  Widget build(BuildContext context) {
    final ready = CloudinaryConfig.isConfigured;
    return _KeyValue(
      'Photos',
      ready
          ? 'Cloudinary: ${CloudinaryConfig.cloudName}/${CloudinaryConfig.folder}'
          : 'Cloudinary — not configured (see cloudinary_config.dart)',
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AdminColors.textGrey),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.65),
      ),
    );
  }
}
