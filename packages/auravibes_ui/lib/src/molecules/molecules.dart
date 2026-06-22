// Molecular components - groups of atoms bonded together.
//
// Molecules are groups of atoms bonded together and are the smallest.
// Fundamental units of a compound. These molecules take on their own.
// Properties and serve as the backbone of our design systems.
//
// Examples:.
// - Search form (input + button.)
// - Card with header and content.
// - Navigation item with icon and text.
// - Form field with label and validation.

// Export all molecular components here.
// Export 'search_form.dart';.
// Export 'card.dart';.
// Export 'navigation_item.dart';.
// Export 'form_field.dart';.
export 'aura_badge.dart' show AuraBadge, AuraBadgeSize, AuraBadgeVariant;
export 'aura_button.dart';
export 'aura_card.dart';
export 'aura_checkbox.dart';
export 'aura_container.dart';
export 'aura_divider.dart' show AuraDivider;
export 'aura_dropdown_option.dart';
export 'aura_floating_action_button.dart';
export 'aura_message_bubble.dart';
export 'aura_radio_option.dart' show AuraRadio, AuraRadioOption;
export 'aura_screen.dart';
export 'aura_snack_bar_variant.dart'
    show AuraSnackBarHost, AuraSnackBarVariant, showAuraSnackBar;

// WorkspaceDropdown moved to app layer per UI Package Purity Contract.
