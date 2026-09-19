class const SkillCredentialOption({
  required final String credentialId,
  required final String displayName,
}) {
  Map<String, Object?> toJson() => {
    'credentialId': credentialId,
    'displayName': displayName,
  };
}
