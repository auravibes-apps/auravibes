bool isSkillLoadable({
  required bool isEnabled,
  required bool isLoaded,
  required bool isCredentialReady,
}) => isEnabled && !isLoaded && isCredentialReady;
