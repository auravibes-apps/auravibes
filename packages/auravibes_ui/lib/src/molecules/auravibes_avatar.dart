import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart'
    show AuraColorVariant, DesignShadows;
import 'package:flutter/material.dart';

/// A customizable avatar component following the Aura design system.
///
/// This avatar widget supports images, initials, and icons with consistent
/// sizing and styling across the application.
class AuraAvatar extends StatelessWidget {
  /// Creates a Aura avatar with an image.
  const AuraAvatar.image({
    required this.imageProvider,
    super.key,
    this.size = AuraAvatarSize.medium,
    this.fallbackText,
    this.fallbackIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
    this.onTap,
  }) : initials = null,
       icon = null;

  /// Creates a Aura avatar with initials.
  const AuraAvatar.initials({
    required this.initials,
    super.key,
    this.size = AuraAvatarSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
    this.onTap,
  }) : imageProvider = null,
       fallbackText = null,
       fallbackIcon = null,
       icon = null;

  /// Creates a Aura avatar with an icon.
  const AuraAvatar.icon({
    required this.icon,
    super.key,
    this.size = AuraAvatarSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
    this.onTap,
  }) : imageProvider = null,
       initials = null,
       fallbackText = null,
       fallbackIcon = null;

  /// The image provider for the avatar image.
  final ImageProvider? imageProvider;

  /// The initials to display in the avatar.
  final String? initials;

  /// The icon to display in the avatar.
  final IconData? icon;

  /// The size of the avatar.
  final AuraAvatarSize size;

  /// Fallback text to display if the image fails to load.
  final String? fallbackText;

  /// Fallback icon to display if the image fails to load.
  final IconData? fallbackIcon;

  /// The background color variant of the avatar.
  final AuraColorVariant? backgroundColor;

  /// The foreground color variant (text/icon color) of the avatar.
  final AuraColorVariant? foregroundColor;

  /// A semantic label for the avatar for accessibility.
  final String? semanticLabel;

  /// Called when the avatar is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final avatarSize = _getAvatarSize();
    final bgColor =
        auraColors.getColor(backgroundColor) ??
        _getDefaultBackgroundColor(auraColors);
    final fgColor =
        auraColors.getColor(foregroundColor) ??
        _getDefaultForegroundColor(auraColors);

    Widget avatar = Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: const [DesignShadows.sm],
      ),
      child: ClipOval(
        child: _buildAvatarContent(fgColor),
      ),
    );

    if (semanticLabel != null) {
      avatar = Semantics(
        label: semanticLabel,
        child: avatar,
      );
    }

    if (onTap != null) {
      avatar = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(avatarSize / 2),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildAvatarContent(Color foregroundColor) {
    if (imageProvider != null) {
      return Image(
        image: imageProvider!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackContent(foregroundColor);
        },
      );
    }

    if (initials != null) {
      return Center(
        child: AuraText(
          style: _getTextStyle(),
          child: Text(
            initials!.toUpperCase(),
            style: TextStyle(
              color: foregroundColor,
            ),
          ),
        ),
      );
    }

    if (icon != null) {
      return Center(
        child: Icon(
          icon,
          size: _getIconSize(),
          color: foregroundColor,
        ),
      );
    }

    return _buildFallbackContent(foregroundColor);
  }

  Widget _buildFallbackContent(Color foregroundColor) {
    if (fallbackText != null) {
      return Center(
        child: AuraText(
          style: _getTextStyle(),
          child: Text(
            fallbackText!.toUpperCase(),
            style: TextStyle(
              color: foregroundColor,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Icon(
        fallbackIcon ?? Icons.person,
        size: _getIconSize(),
        color: foregroundColor,
      ),
    );
  }

  double _getAvatarSize() {
    return switch (size) {
      AuraAvatarSize.extraSmall => 24.0,
      AuraAvatarSize.small => 32.0,
      AuraAvatarSize.medium => 40.0,
      AuraAvatarSize.large => 48.0,
      AuraAvatarSize.extraLarge => 64.0,
      AuraAvatarSize.huge => 96.0,
    };
  }

  double _getIconSize() {
    return switch (size) {
      AuraAvatarSize.extraSmall => 12.0,
      AuraAvatarSize.small => 16.0,
      AuraAvatarSize.medium => 20.0,
      AuraAvatarSize.large => 24.0,
      AuraAvatarSize.extraLarge => 32.0,
      AuraAvatarSize.huge => 48.0,
    };
  }

  AuraTextStyle _getTextStyle() {
    return switch (size) {
      AuraAvatarSize.extraSmall => AuraTextStyle.caption,
      AuraAvatarSize.small => AuraTextStyle.bodySmall,
      AuraAvatarSize.medium => AuraTextStyle.body,
      AuraAvatarSize.large => AuraTextStyle.bodyLarge,
      AuraAvatarSize.extraLarge => AuraTextStyle.heading6,
      AuraAvatarSize.huge => AuraTextStyle.heading4,
    };
  }

  Color _getDefaultBackgroundColor(AuraColorScheme colors) {
    return colors.primary;
  }

  Color _getDefaultForegroundColor(AuraColorScheme colors) {
    return colors.onPrimary;
  }
}

/// A specialized avatar group component for displaying multiple avatars.
///
/// This component stacks avatars with proper overlap and provides a way
/// to show additional count when there are more avatars than can be displayed.
class AuraAvatarGroup extends StatelessWidget {
  /// Creates a Aura avatar group.
  const AuraAvatarGroup({
    required this.avatars,
    super.key,
    this.size = AuraAvatarSize.medium,
    this.maxVisible = 3,
    this.spacing = 8.0,
    this.showCount = true,
    this.semanticLabel,
  });

  /// The list of avatars to display.
  final List<AuraAvatar> avatars;

  /// The size of all avatars in the group.
  final AuraAvatarSize size;

  /// The maximum number of avatars to show before displaying a count.
  final int maxVisible;

  /// The spacing between avatars (negative for overlap).
  final double spacing;

  /// Whether to show a count avatar when there are more avatars than
  /// maxVisible.
  final bool showCount;

  /// A semantic label for the avatar group for accessibility.
  final String? semanticLabel;

  double _getAvatarSize(AuraAvatarSize size) {
    return switch (size) {
      AuraAvatarSize.extraSmall => 24,
      AuraAvatarSize.small => 32,
      AuraAvatarSize.medium => 40,
      AuraAvatarSize.large => 48,
      AuraAvatarSize.extraLarge => 64,
      AuraAvatarSize.huge => 96,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) return const SizedBox.shrink();

    final visibleAvatars = avatars.take(maxVisible).toList();
    final remainingCount = avatars.length - maxVisible;
    final hasMore = remainingCount > 0 && showCount;

    Widget group;

    if (spacing < 0) {
      // For negative spacing (overlapping), use Stack
      final avatarSize = _getAvatarSize(size);
      final totalAvatars = visibleAvatars.length + (hasMore ? 1 : 0);
      final overlap = spacing.abs();
      final totalWidth =
          avatarSize + (totalAvatars - 1) * (avatarSize - overlap);

      group = SizedBox(
        width: totalWidth,
        child: Stack(
          children: [
            ...visibleAvatars.asMap().entries.map((entry) {
              final index = entry.key;
              final avatar = entry.value;

              return Positioned(
                left: index * (avatarSize - overlap),
                child: avatar,
              );
            }),
            if (hasMore)
              Positioned(
                left: visibleAvatars.length * (avatarSize - overlap),
                child: AuraAvatar.initials(
                  initials: '+$remainingCount',
                  backgroundColor: AuraColorVariant.surfaceVariant,
                  foregroundColor: AuraColorVariant.onSurfaceVariant,
                ),
              ),
          ],
        ),
      );
    } else {
      // For positive spacing, use Row with padding
      group = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...visibleAvatars.asMap().entries.map((entry) {
            final index = entry.key;
            final avatar = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                left: index > 0 ? spacing : 0,
              ),
              child: avatar,
            );
          }),
          if (hasMore)
            Padding(
              padding: EdgeInsets.only(left: spacing),
              child: AuraAvatar.initials(
                initials: '+$remainingCount',
                backgroundColor: AuraColorVariant.surfaceVariant,
                foregroundColor: AuraColorVariant.onSurfaceVariant,
              ),
            ),
        ],
      );
    }

    if (semanticLabel != null) {
      group = Semantics(
        label: semanticLabel,
        child: group,
      );
    }

    return group;
  }
}

/// The size of a [AuraAvatar].
enum AuraAvatarSize {
  /// Extra small avatar (24px).
  extraSmall,

  /// Small avatar (32px).
  small,

  /// Medium avatar (40px) - default.
  medium,

  /// Large avatar (48px).
  large,

  /// Extra large avatar (64px).
  extraLarge,

  /// Huge avatar (96px).
  huge,
}
