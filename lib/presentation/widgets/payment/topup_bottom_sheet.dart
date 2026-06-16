import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';

class TopupBottomSheet extends StatefulWidget {
  const TopupBottomSheet({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TopupBottomSheet(),
    );
  }

  @override
  State<TopupBottomSheet> createState() => _TopupBottomSheetState();
}

class _TopupBottomSheetState extends State<TopupBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadPackages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final payment = context.watch<PaymentProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.topupCredit,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  payment.clearTransaction();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (payment.isLoading && payment.packages.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (payment.error != null)
            Center(
              child: Text(
                payment.error!,
                style: const TextStyle(color: AppColors.error),
              ),
            )
          else if (payment.currentTransaction != null)
            _buildPaymentTransaction(context, payment, l10n)
          else
            _buildPackageList(context, payment, l10n),
        ],
      ),
    );
  }

  Widget _buildPackageList(BuildContext context, PaymentProvider payment, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...payment.packages.map((pkg) => _PackageItem(
          package: pkg,
          isProcessing: payment.isLoading,
          onTap: () async {
            final success = await payment.createTransaction(pkg.id);
            if (success && mounted) {
              // Wait for QR or check status
            }
          },
        )),
      ],
    );
  }

  Widget _buildPaymentTransaction(BuildContext context, PaymentProvider payment, AppLocalizations l10n) {
    final tx = payment.currentTransaction!;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Quét mã QR để thanh toán',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          width: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: tx.qrCodeUrl.isNotEmpty
                ? Image.network(
                    tx.qrCodeUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  )
                : const Center(child: Text('Không tải được mã QR')),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                'Ngân hàng: ${tx.bankInfo['bankName'] ?? ''}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Số tài khoản: ${tx.bankInfo['accountNumber'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Nội dung chuyển khoản:',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                tx.transferContent,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            await payment.confirmTransaction();
            if (mounted) {
              Navigator.pop(context);
              // Nạp profile lại
              context.read<AuthProvider>().refreshProfile();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Tôi đã chuyển khoản'),
        ),
      ],
    );
  }
}

class _PackageItem extends StatelessWidget {
  final dynamic package;
  final bool isProcessing;
  final VoidCallback onTap;

  const _PackageItem({
    required this.package,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: package.popular ? AppColors.primary : Colors.grey.withOpacity(0.3),
          width: package.popular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: package.popular ? AppColors.primary.withOpacity(0.05) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Text(
              package.label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (package.popular) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'PHỔ BIẾN',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        subtitle: package.bonus != null
            ? Text(
                'Tặng thêm ${package.bonus}',
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
              )
            : null,
        trailing: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                '${(package.price / 1000).toStringAsFixed(0)}k',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
        onTap: isProcessing ? null : onTap,
      ),
    );
  }
}
