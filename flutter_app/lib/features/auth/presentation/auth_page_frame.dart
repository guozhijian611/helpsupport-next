import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';

class AuthPageFrame extends ConsumerWidget {
  const AuthPageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.trailing,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 720;
    final appConfigState = ref.watch(appConfigProvider);
    final appConfig = appConfigState.hasValue
        ? appConfigState.value ?? AppConfig.fallback
        : AppConfig.fallback;

    return Scaffold(
      backgroundColor: _gradientStart,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_gradientStart, _gradientEnd],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 520 : 480),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final scale = (constraints.maxWidth / 375)
                      .clamp(0.92, 1.08)
                      .toDouble();
                  final panelTop = (isWide ? 276.0 : 200.0 * scale)
                      .clamp(198.0, height * 0.36)
                      .toDouble();
                  final logoTop = isWide ? 52.0 : 46.0 * scale;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (leading != null || trailing != null)
                        Positioned(
                          top: 18,
                          left: isWide ? 44 : 24,
                          right: isWide ? 44 : 24,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 52,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: leading,
                                ),
                              ),
                              const Spacer(),
                              ?trailing,
                            ],
                          ),
                        ),
                      Positioned(
                        top: logoTop,
                        left: 0,
                        right: 0,
                        child: _AppLogo(logoUrl: appConfig.logo),
                      ),
                      Positioned(
                        top: logoTop + 100,
                        left: 24,
                        right: 24,
                        child: Text(
                          appConfig.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                        ),
                      ),
                      Positioned(
                        top: panelTop,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(30),
                            ),
                          ),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              isWide ? 44 : 40,
                              30,
                              isWide ? 44 : 40,
                              28 + MediaQuery.paddingOf(context).bottom,
                            ),
                            children: [
                              Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: isWide ? 430 : double.infinity,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: _gradientStart,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      if (subtitle.trim().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          subtitle,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: _mutedTextColor,
                                                height: 1.35,
                                              ),
                                        ),
                                      ],
                                      const SizedBox(height: 24),
                                      child,
                                      if (footer != null) ...[
                                        const SizedBox(height: 18),
                                        footer!,
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.height = 52,
    this.borderRadius = 15,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? disabledBackgroundColor;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolvedBackground = backgroundColor ?? _gradientStart;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: resolvedBackground,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              disabledBackgroundColor ??
              resolvedBackground.withValues(alpha: 0.42),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: _PrimaryButtonContent(
          icon: icon,
          isLoading: isLoading,
          label: label,
        ),
      ),
    );
  }
}

class _PrimaryButtonContent extends StatelessWidget {
  const _PrimaryButtonContent({
    required this.label,
    required this.isLoading,
    this.icon,
  });

  final String label;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final spinner = const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );
    final iconWidget = isLoading
        ? spinner
        : icon == null
        ? null
        : Icon(icon);

    if (iconWidget == null) {
      return Text(label);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [iconWidget, const SizedBox(width: 8), Text(label)],
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.backgroundColor = Colors.white,
    this.foregroundColor,
    this.borderColor = _softBorderColor,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color? foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor:
              foregroundColor ?? Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }
}

class AuthLinkButton extends StatelessWidget {
  const AuthLinkButton({
    super.key,
    required this.text,
    required this.actionText,
    required this.onPressed,
    this.onDark = true,
  });

  final String text;
  final String actionText;
  final VoidCallback onPressed;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final baseColor = onDark
        ? Colors.white.withValues(alpha: 0.82)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final actionColor = onDark
        ? Colors.white
        : Theme.of(context).colorScheme.primary;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: baseColor),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: actionColor,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
          child: Text(actionText),
        ),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        hintText: label,
        errorMaxLines: 2,
        filled: true,
        fillColor: _fieldFillColor,
        prefixIcon: Icon(icon, color: _inputIconColor),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _gradientStart),
        ),
      ),
      validator: validator,
    );
  }
}

class AuthAgreementNotice extends StatelessWidget {
  const AuthAgreementNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        height: 1.45,
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo({required this.logoUrl});

  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 72,
        child: logoUrl.isEmpty
            ? const _LogoFallback()
            : Image.network(
                logoUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return const Center(
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const _LogoFallback();
                },
              ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LogoMarkPainter());
  }
}

class _LogoMarkPainter extends CustomPainter {
  const _LogoMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final unit = size.shortestSide / 90;
    final radius = Radius.circular(17 * unit);

    void pill(Rect rect) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
    }

    pill(Rect.fromLTWH(39 * unit, 0, 32 * unit, 58 * unit));
    pill(Rect.fromLTWH(0, 44 * unit, 63 * unit, 32 * unit));
    pill(Rect.fromLTWH(75 * unit, 44 * unit, 42 * unit, 32 * unit));
    pill(Rect.fromLTWH(39 * unit, 70 * unit, 32 * unit, 30 * unit));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const _gradientStart = Color(0xFFFF9585);
const _gradientEnd = Color(0xFFFCB08E);
const _fieldFillColor = Color(0xFFF4F5F9);
const _inputIconColor = Color(0xFF343437);
const _mutedTextColor = Color(0xFFA28D86);
const _softBorderColor = Color(0xFFECE7E4);
