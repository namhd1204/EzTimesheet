import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Design System Demo - Showcase all design tokens and components
class DesignSystemDemo extends StatelessWidget {
  const DesignSystemDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: const DesignSystemShowcase(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DesignSystemShowcase extends StatelessWidget {
  const DesignSystemShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            title: const Text('Design System'),
            floating: true,
            elevation: AppTheme.elevationNone,
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: AppTheme.paddingMedium,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildColorPalette(context),
                  const SizedBox(height: AppTheme.space8),
                  _buildTypographyScale(context),
                  const SizedBox(height: AppTheme.space8),
                  _buildSpacingSystem(context),
                  const SizedBox(height: AppTheme.space8),
                  _buildBorderRadius(context),
                  const SizedBox(height: AppTheme.space8),
                  _buildButtons(context),
                  const SizedBox(height: AppTheme.space8),
                  _buildCards(context),
                  const SizedBox(height: AppTheme.space8),
                  _buildInputs(context),
                  const SizedBox(height: AppTheme.space8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Text(
        title,
        style: AppTheme.headlineSmall.copyWith(
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildColorPalette(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Color Palette'),
        Wrap(
          spacing: AppTheme.space2,
          runSpacing: AppTheme.space2,
          children: [
            _buildColorCard('Primary', AppTheme.primary),
            _buildColorCard('Primary Light', AppTheme.primaryLight),
            _buildColorCard('Primary Dark', AppTheme.primaryDark),
            _buildColorCard('Secondary', AppTheme.secondary),
            _buildColorCard('Secondary Light', AppTheme.secondaryLight),
            _buildColorCard('Secondary Dark', AppTheme.secondaryDark),
            _buildColorCard('Surface', AppTheme.surface),
            _buildColorCard('Surface Elevated', AppTheme.surfaceElevated),
            _buildColorCard('Surface Highlight', AppTheme.surfaceHighlight),
            _buildColorCard('Error', AppTheme.error),
            _buildColorCard('Error Light', AppTheme.errorLight),
            _buildColorCard('Error Dark', AppTheme.errorDark),
            _buildColorCard('Text Primary', AppTheme.textPrimary),
            _buildColorCard('Text Secondary', AppTheme.textSecondary),
            _buildColorCard('Text Tertiary', AppTheme.textTertiary),
            _buildColorCard('Border', AppTheme.border),
          ],
        ),
      ],
    );
  }

  Widget _buildColorCard(String name, Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Center(
        child: Text(
          name,
          style: AppTheme.labelSmall.copyWith(
            color: _getContrastColor(color),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildTypographyScale(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Typography Scale'),
        _buildTypographyItem('Display Large', AppTheme.displayLarge),
        _buildTypographyItem('Display Medium', AppTheme.displayMedium),
        _buildTypographyItem('Display Small', AppTheme.displaySmall),
        _buildTypographyItem('Headline Large', AppTheme.headlineLarge),
        _buildTypographyItem('Headline Medium', AppTheme.headlineMedium),
        _buildTypographyItem('Headline Small', AppTheme.headlineSmall),
        _buildTypographyItem('Body Large', AppTheme.bodyLarge),
        _buildTypographyItem('Body Medium', AppTheme.bodyMedium),
        _buildTypographyItem('Body Small', AppTheme.bodySmall),
        _buildTypographyItem('Label Large', AppTheme.labelLarge),
        _buildTypographyItem('Label Medium', AppTheme.labelMedium),
        _buildTypographyItem('Label Small', AppTheme.labelSmall),
      ],
    );
  }

  Widget _buildTypographyItem(String name, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              name,
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'The quick brown fox jumps over the lazy dog',
              style: style,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingSystem(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Spacing System'),
        Wrap(
          spacing: AppTheme.space4,
          children: [
            _buildSpacingItem('0', AppTheme.space0),
            _buildSpacingItem('1', AppTheme.space1),
            _buildSpacingItem('2', AppTheme.space2),
            _buildSpacingItem('3', AppTheme.space3),
            _buildSpacingItem('4', AppTheme.space4),
            _buildSpacingItem('5', AppTheme.space5),
            _buildSpacingItem('6', AppTheme.space6),
            _buildSpacingItem('8', AppTheme.space8),
            _buildSpacingItem('10', AppTheme.space10),
            _buildSpacingItem('12', AppTheme.space12),
            _buildSpacingItem('16', AppTheme.space16),
            _buildSpacingItem('20', AppTheme.space20),
            _buildSpacingItem('24', AppTheme.space24),
          ],
        ),
      ],
    );
  }

  Widget _buildSpacingItem(String name, double space) {
    return Column(
      children: [
        Container(
          width: space > 0 ? space : 4,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: AppTheme.borderRadiusSmall,
          ),
        ),
        const SizedBox(height: AppTheme.space1),
        Text(
          name,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildBorderRadius(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Border Radius'),
        Wrap(
          spacing: AppTheme.space4,
          runSpacing: AppTheme.space4,
          children: [
            _buildRadiusItem('None', AppTheme.radiusNone),
            _buildRadiusItem('Small', AppTheme.radiusSmall),
            _buildRadiusItem('Medium', AppTheme.radiusMedium),
            _buildRadiusItem('Large', AppTheme.radiusLarge),
            _buildRadiusItem('XLarge', AppTheme.radiusXLarge),
            _buildRadiusItem('Full', AppTheme.radiusFull),
          ],
        ),
      ],
    );
  }

  Widget _buildRadiusItem(String name, double radius) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppTheme.border),
          ),
        ),
        const SizedBox(height: AppTheme.space1),
        Text(
          name,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Buttons'),
        Wrap(
          spacing: AppTheme.space3,
          runSpacing: AppTheme.space3,
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('Elevated'),
            ),
            ElevatedButton(
              onPressed: null,
              child: const Text('Disabled'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Text Button'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Outlined'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Cards'),
        Card(
          child: Padding(
            padding: AppTheme.paddingMedium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Card Title',
                  style: AppTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.space2),
                Text(
                  'This is a sample card demonstrating the design system card styling with proper spacing and typography.',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.space3),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Action'),
                    ),
                    const SizedBox(width: AppTheme.space2),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Learn More'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputs(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Input Fields'),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Text Field',
            hintText: 'Enter your text',
          ),
        ),
        const SizedBox(height: AppTheme.space3),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'your@email.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: AppTheme.space3),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: '••••••••',
            prefixIcon: Icon(Icons.lock_outlined),
            suffixIcon: Icon(Icons.visibility_outlined),
          ),
          obscureText: true,
        ),
        const SizedBox(height: AppTheme.space3),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Error State',
            hintText: 'This field has an error',
            errorText: 'Please enter a valid value',
          ),
        ),
      ],
    );
  }
}