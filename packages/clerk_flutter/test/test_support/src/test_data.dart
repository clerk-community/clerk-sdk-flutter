import 'package:clerk_auth/clerk_auth.dart';

/// Creates a test Verification with sensible defaults
Verification createTestVerification({
  Status status = Status.verified,
  Strategy strategy = Strategy.emailCode,
  int? attempts = 0,
  DateTime? expireAt,
}) {
  return Verification(
    status: status,
    strategy: strategy,
    attempts: attempts,
    expireAt: expireAt ?? DateTime.now().add(const Duration(days: 1)),
  );
}

/// Creates a test Email with sensible defaults
Email createTestEmail({
  String id = 'email_123',
  String emailAddress = 'john.doe@example.com',
  Verification? verification,
  bool reserved = false,
  DateTime? updatedAt,
  DateTime? createdAt,
}) {
  return Email(
    id: id,
    emailAddress: emailAddress,
    verification: verification ?? createTestVerification(),
    reserved: reserved,
    updatedAt: updatedAt ?? DateTime.now(),
    createdAt: createdAt ?? DateTime.now(),
  );
}

/// Creates a test PhoneNumber with sensible defaults
PhoneNumber createTestPhoneNumber({
  String id = 'phone_123',
  String phoneNumber = '+1234567890',
  Verification? verification,
  bool reserved = false,
  bool reservedForSecondFactor = false,
  bool defaultSecondFactor = false,
  DateTime? updatedAt,
  DateTime? createdAt,
}) {
  return PhoneNumber(
    id: id,
    phoneNumber: phoneNumber,
    verification: verification ?? createTestVerification(),
    reserved: reserved,
    reservedForSecondFactor: reservedForSecondFactor,
    defaultSecondFactor: defaultSecondFactor,
    updatedAt: updatedAt ?? DateTime.now(),
    createdAt: createdAt ?? DateTime.now(),
  );
}

/// Creates a test User with sensible defaults
User createTestUser({
  String id = 'user_test_123',
  String? firstName = 'John',
  String? lastName = 'Doe',
  String? username = 'johndoe',
  String? imageUrl,
  bool? hasImage = false,
  String? primaryEmailAddressId = 'email_123',
  List<Email>? emailAddresses,
  List<PhoneNumber>? phoneNumbers,
  List<ExternalAccount>? externalAccounts,
  List<OrganizationMembership>? organizationMemberships,
  bool createOrganizationEnabled = false,
}) {
  return User(
    id: id,
    externalId: null,
    username: username,
    firstName: firstName,
    lastName: lastName,
    profileImageUrl: null,
    imageUrl: imageUrl,
    hasImage: hasImage,
    primaryEmailAddressId: primaryEmailAddressId,
    primaryPhoneNumberId: null,
    primaryWeb3WalletId: null,
    publicMetadata: const {},
    privateMetadata: const {},
    unsafeMetadata: const {},
    emailAddresses: emailAddresses ?? [createTestEmail()],
    phoneNumbers: phoneNumbers ?? const [],
    web3Wallets: const [],
    passkeys: const [],
    organizationMemberships: organizationMemberships ?? const [],
    createOrganizationEnabled: createOrganizationEnabled,
    externalAccounts: externalAccounts ?? const [],
    passwordEnabled: true,
    twoFactorEnabled: false,
    totpEnabled: false,
    backupCodeEnabled: false,
    lastSignInAt: DateTime.now(),
    banned: false,
    locked: false,
    lockoutExpiresInSeconds: null,
    verificationAttemptsRemaining: null,
    updatedAt: DateTime.now(),
    createdAt: DateTime.now(),
    lastActiveAt: DateTime.now(),
    deleteSelfEnabled: true,
  );
}

/// Creates a test Session with sensible defaults
Session createTestSession({
  String id = 'sess_test_123',
  Status status = Status.active,
  User? user,
  String? lastActiveOrganizationId,
}) {
  final testUser = user ?? createTestUser();
  return Session(
    id: id,
    status: status,
    lastActiveAt: DateTime.now(),
    expireAt: DateTime.now().add(const Duration(days: 1)),
    abandonAt: DateTime.now().add(const Duration(days: 7)),
    publicUserData: UserPublic(
      firstName: testUser.firstName,
      lastName: testUser.lastName,
      profileImageUrl: testUser.profileImageUrl,
      imageUrl: testUser.imageUrl,
      hasImage: testUser.hasImage ?? false,
      identifier: testUser.email ?? '',
    ),
    lastActiveOrganizationId: lastActiveOrganizationId,
    user: testUser,
  );
}

/// Creates a test Client with sensible defaults
///
/// Note: the live API does not advance `updated_at` when a sign-in is
/// created or progresses. Pass an explicit [updatedAt] shared between
/// consecutive clients to model flows faithfully.
Client createTestClient({
  String? id = 'client_test_123',
  List<Session>? sessions,
  String? lastActiveSessionId,
  SignIn? signIn,
  SignUp? signUp,
  DateTime? updatedAt,
  DateTime? createdAt,
}) {
  final testSessions = sessions ?? [];
  return Client(
    id: id,
    sessions: testSessions,
    lastActiveSessionId: lastActiveSessionId ??
        (testSessions.isNotEmpty ? testSessions.first.id : null),
    signIn: signIn,
    signUp: signUp,
    updatedAt: updatedAt ?? DateTime.now(),
    createdAt: createdAt ?? DateTime.now(),
  );
}

/// Creates a test Client with a signed-in user
Client createSignedInClient({
  User? user,
  String sessionId = 'sess_test_123',
}) {
  final testUser = user ?? createTestUser();
  final session = createTestSession(id: sessionId, user: testUser);
  return createTestClient(
    sessions: [session],
    lastActiveSessionId: sessionId,
  );
}

/// Creates an empty test Client (signed out state)
Client createSignedOutClient() {
  return createTestClient(sessions: []);
}

/// Creates a test SignUp with sensible defaults
SignUp createTestSignUp({
  String id = 'signup_test_123',
  Status status = Status.missingRequirements,
  List<Field> requiredFields = const [],
  List<Field> optionalFields = const [],
  List<Field> missingFields = const [],
  List<Field> unverifiedFields = const [],
  String? username,
  String? emailAddress,
  String? phoneNumber,
  bool passwordEnabled = false,
  String? firstName,
  String? lastName,
  Map<Field, Verification> verifications = const {},
}) {
  return SignUp(
    id: id,
    status: status,
    requiredFields: requiredFields,
    optionalFields: optionalFields,
    missingFields: missingFields,
    unverifiedFields: unverifiedFields,
    username: username,
    emailAddress: emailAddress,
    phoneNumber: phoneNumber,
    web3Wallet: null,
    passwordEnabled: passwordEnabled,
    firstName: firstName,
    lastName: lastName,
    unsafeMetadata: const {},
    publicMetadata: const {},
    verifications: verifications,
    customAction: false,
    externalId: null,
    createdSessionId: null,
    createdUserId: null,
    abandonAt: DateTime.now().add(const Duration(days: 7)),
  );
}

/// Creates a test SignIn with sensible defaults
SignIn createTestSignIn({
  String id = 'signin_test_123',
  Status status = Status.needsIdentifier,
  List<String> supportedIdentifiers = const [],
  List<Factor> supportedFirstFactors = const [],
  List<Factor> supportedSecondFactors = const [],
  String? identifier,
  Verification? firstFactorVerification,
  Verification? secondFactorVerification,
}) {
  return SignIn(
    id: id,
    status: status,
    supportedIdentifiers: supportedIdentifiers,
    supportedFirstFactors: supportedFirstFactors,
    supportedSecondFactors: supportedSecondFactors,
    identifier: identifier,
    firstFactorVerification: firstFactorVerification,
    secondFactorVerification: secondFactorVerification,
    userData: null,
    createdSessionId: null,
    abandonAt: DateTime.now().add(const Duration(days: 7)),
  );
}

/// Creates a test Factor with sensible defaults
Factor createTestFactor({
  Strategy strategy = Strategy.password,
  String? safeIdentifier,
  String? emailAddressId,
  String? phoneNumberId,
  String? web3WalletId,
  String? passkeyId,
  bool isPrimary = false,
  bool isDefault = false,
}) {
  return Factor(
    strategy: strategy,
    safeIdentifier: safeIdentifier,
    emailAddressId: emailAddressId,
    phoneNumberId: phoneNumberId,
    web3WalletId: web3WalletId,
    passkeyId: passkeyId,
    isPrimary: isPrimary,
    isDefault: isDefault,
  );
}

/// Creates a test Organization with sensible defaults
Organization createTestOrganization({
  String id = 'org_test_123',
  String name = 'Test Organization',
  String slug = 'test-org',
  String imageUrl = '',
  bool hasImage = false,
  int maxAllowedMemberships = 100,
}) {
  return Organization(
    id: id,
    name: name,
    slug: slug,
    imageUrl: imageUrl,
    hasImage: hasImage,
    membersCount: 1,
    pendingInvitationsCount: 0,
    maxAllowedMemberships: maxAllowedMemberships,
    adminDeleteEnabled: true,
    publicMetadata: const {},
    updatedAt: DateTime.now(),
    createdAt: DateTime.now(),
  );
}

/// Creates a test OrganizationMembership with sensible defaults
OrganizationMembership createTestOrganizationMembership({
  String id = 'orgmem_test_123',
  String role = 'org:member',
  String roleName = 'Member',
  Organization? organization,
  UserPublic? publicUserData,
  List<Permission>? permissions,
}) {
  return OrganizationMembership(
    id: id,
    role: role,
    roleName: roleName,
    organization: organization ?? createTestOrganization(),
    publicUserData: publicUserData,
    permissions: permissions ?? const [],
    updatedAt: DateTime.now(),
    createdAt: DateTime.now(),
  );
}

/// Creates a test ExternalAccount with sensible defaults
ExternalAccount createTestExternalAccount({
  String id = 'extacc_test_123',
  String provider = 'google',
  String providerUserId = 'google_123',
  String approvedScopes = 'email profile',
  String emailAddress = 'john.doe@gmail.com',
  String? username,
  String? firstName = 'John',
  String? lastName = 'Doe',
  Verification? verification,
}) {
  return ExternalAccount(
    id: id,
    provider: provider,
    providerUserId: providerUserId,
    approvedScopes: approvedScopes,
    emailAddress: emailAddress,
    username: username,
    firstName: firstName,
    lastName: lastName,
    avatarUrl: null,
    imageUrl: null,
    label: null,
    publicMetadata: const {},
    verification: verification ?? createTestVerification(),
    updatedAt: DateTime.now(),
    createdAt: DateTime.now(),
  );
}
