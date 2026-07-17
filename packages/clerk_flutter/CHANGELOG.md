## 0.0.18-beta

* fix: sign in continue does nothing [[#437]](https://github.com/clerk-community/clerk-sdk-flutter/issues/437)

## 0.0.17-beta

* fix: minor fix to new_release tool
* chore: community org metadata and framing [[#433]](https://github.com/clerk-community/clerk-sdk-flutter/issues/433)
* test(patrol): sign in with google [[#410]](https://github.com/clerk-community/clerk-sdk-flutter/issues/410)
* tests: add patrol (#412)
* feat: client trust [[#419]](https://github.com/clerk-community/clerk-sdk-flutter/issues/419)

## 0.0.16-beta

* feat(clerk_auth): added immutable to user attribute data [[#406]](https://github.com/clerk-community/clerk-sdk-flutter/issues/406)
* docs(clerk_flutter): ClerkSignedIn and ClerkSignedOut example [[#416]](https://github.com/clerk-community/clerk-sdk-flutter/issues/416)

## 0.0.15-beta

* feat: add passkey support [[#300]](https://github.com/clerk-community/clerk-sdk-flutter/issues/300) 
* feat: improve testing [[#350]](https://github.com/clerk-community/clerk-sdk-flutter/issues/350)
* fix: improve sign up panel [[#356]](https://github.com/clerk-community/clerk-sdk-flutter/issues/356)
* fix: add explicit resend code function [[#365]](https://github.com/clerk-community/clerk-sdk-flutter/issues/365)
* fix: regression in oauth sign up [[#306]](https://github.com/clerk-community/clerk-sdk-flutter/issues/306)
* fix: make sign in with apple work [[#384]](https://github.com/clerk-community/clerk-sdk-flutter/issues/384) 
* fix(clerk_flutter): phone number input field not visible [[#389]](https://github.com/clerk-community/clerk-sdk-flutter/issues/389)
* feat: add signing in and up to clerk_auth_builder [[#382]](https://github.com/clerk-community/clerk-sdk-flutter/issues/382)

## 0.0.14-beta

* BREAKING CHANGE: The `ClerkDeepLink` class has been removed, since the information
  it carried is no longer being used. Deep links are now passed into the Clerk SDK 
  as `Stream<Uri?> deepLinkStream` in the `ClerkAuthConfig`. 

* feat: deprecate strategy in clerkdeeplink [[#345]](https://github.com/clerk-community/clerk-sdk-flutter/issues/345)
* fix: make sso sign up complete [[#343]](https://github.com/clerk-community/clerk-sdk-flutter/issues/343)
* feat: expose externalid on user object [[#339]](https://github.com/clerk-community/clerk-sdk-flutter/issues/339)
* feat: push error stream up to clerk_flutter [[#335]](https://github.com/clerk-community/clerk-sdk-flutter/issues/335)
* fix: dark-mode base inversion checking on strategy [[#333]](https://github.com/clerk-community/clerk-sdk-flutter/issues/333)
* fix: ensure api throws external errors rather than clerk errors [[#331]](https://github.com/clerk-community/clerk-sdk-flutter/issues/331)
* feat: improve sso provider logos display on dark themes [[#329]](https://github.com/clerk-community/clerk-sdk-flutter/issues/329)
* fix: add externalerrorcollection to autherror [[#316]](https://github.com/clerk-community/clerk-sdk-flutter/issues/316)
* feat: apple and google auth token support [[#308]](https://github.com/clerk-community/clerk-sdk-flutter/issues/308)
* feat: allow other launchmodes for sso [[#307]](https://github.com/clerk-community/clerk-sdk-flutter/issues/307)
* fix: sso sign up [[#306]](https://github.com/clerk-community/clerk-sdk-flutter/issues/306)
* fix: improve phone number handling [[#304]](https://github.com/clerk-community/clerk-sdk-flutter/issues/304)
* feat: add theme extension to drive colors and text styles [[#298]](https://github.com/clerk-community/clerk-sdk-flutter/issues/298)

## 0.0.13-beta

* feat: make test helpers globally available [[#292]](https://github.com/clerk-community/clerk-sdk-flutter/issues/292)
* feat: improve email link sign in up [[#267]](https://github.com/clerk-community/clerk-sdk-flutter/issues/267)
* fix: move session token polling from api to auth for better error reporting [[#244]](https://github.com/clerk-community/clerk-sdk-flutter/issues/244)
* feat: bring sign up ux in line with other sdks [[#246]](https://github.com/clerk-community/clerk-sdk-flutter/issues/246)
* fix: force org creation when needed [[#271]](https://github.com/clerk-community/clerk-sdk-flutter/issues/271)
* change: session token polling now defaults to ON (previous versions had it defaulting to OFF) [[#263]](https://github.com/clerk-community/clerk-sdk-flutter/issues/263)
* fix: bring session token polling with orgs inline with other SDKs [[#263]](https://github.com/clerk-community/clerk-sdk-flutter/issues/263)
* fix: enable re-initialisation of clerksdkgrammar [[#261]](https://github.com/clerk-community/clerk-sdk-flutter/issues/261)
* feat: enable sign up with enterprise sso [[#247]](https://github.com/clerk-community/clerk-sdk-flutter/issues/247)
* fix: enable sign in using enterprise sso [[#248]](https://github.com/clerk-community/clerk-sdk-flutter/issues/248)

## 0.0.12-beta

* chore: align release version with `clerk_auth` 0.0.12-beta package
* fix: ensure decoding of UserPublic.identifier is optional [[#256]](https://github.com/clerk-community/clerk-sdk-flutter/issues/256)

## 0.0.11-beta

* feat: **BREAKING** Upgrade to Flutter 3.27.4 and Dart 3.6.2 [[#242]](https://github.com/clerk-community/clerk-sdk-flutter/issues/242)
* fix: re-enable email link in signIn [[#241]](https://github.com/clerk-community/clerk-sdk-flutter/issues/241)
* fix: restrict sign up fields to known entities [[#227]](https://github.com/clerk-community/clerk-sdk-flutter/issues/227)
* fix: allow email address to be edited for verification [[#226]](https://github.com/clerk-community/clerk-sdk-flutter/issues/226)
* fix: allow landscape logos to look better in components [[#225]](https://github.com/clerk-community/clerk-sdk-flutter/issues/225)
* fix: remove branding if required in dashboard [[#224]](https://github.com/clerk-community/clerk-sdk-flutter/issues/224)
* fix: allow obscuration on sign in password to be togglable [[#223]](https://github.com/clerk-community/clerk-sdk-flutter/issues/223)
* fix: enable legal consent confirmation [[#222]](https://github.com/clerk-community/clerk-sdk-flutter/issues/222)
* fix: resolve issues with the sessionTokenStream [[#221]](https://github.com/clerk-community/clerk-sdk-flutter/issues/221)
* fix: make ui respond better when wifi is unavailable [[#212]](https://github.com/clerk-community/clerk-sdk-flutter/issues/212)
* fix: refactor sign-in panel to keep password and confirmation together [[#208]](https://github.com/clerk-community/clerk-sdk-flutter/issues/208)
* fix: make google authentication work directly with tokens [[#207]](https://github.com/clerk-community/clerk-sdk-flutter/issues/207)
* fix: minor refactoring to caching [[#204]](https://github.com/clerk-community/clerk-sdk-flutter/issues/204)

## 0.0.10-beta

* feat: allow app-defined redirects aka deep-links (with example) [[#170]](https://github.com/clerk-community/clerk-sdk-flutter/issues/170)
* feat: add password reset flow [[#161]](https://github.com/clerk-community/clerk-sdk-flutter/issues/161)
* feat: clear cookies on sign out [[#188]](https://github.com/clerk-community/clerk-sdk-flutter/issues/188)
* feat: refactor identifier input [[#197]](https://github.com/clerk-community/clerk-sdk-flutter/issues/197)
* feat: add offline support [[#200]](https://github.com/clerk-community/clerk-sdk-flutter/issues/200)
* feat: grammatical sentence formatting [[#192]](https://github.com/clerk-community/clerk-sdk-flutter/issues/192)

See changes made in `clerk_auth` package as part of this release.

## 0.0.9-beta

* feat: support fall-back localization default English [[#163]](https://github.com/clerk-community/clerk-sdk-flutter/issues/163)
* fix: update user agent to support desktop/mobile modes [[#166]](https://github.com/clerk-community/clerk-sdk-flutter/issues/166)

## 0.0.8-beta

* feat: add generated clerk_backend_api package [[#82]](https://github.com/clerk-community/clerk-sdk-flutter/issues/82)
* feat: implement organizations [[#150]](https://github.com/clerk-community/clerk-sdk-flutter/issues/150) 

## 0.0.7-dev

* fix: rationalise clerk auth exports [[#105]](https://github.com/clerk-community/clerk-sdk-flutter/issues/105)
* fix: session token broken [[#97]](https://github.com/clerk-community/clerk-sdk-flutter/issues/97)
* feat: enable session tokens to be created and updated per organization [[#97]](https://github.com/clerk-community/clerk-sdk-flutter/issues/97)
* fix: enable telemetry to be disabled and endpoint to be set from env [[#97]](https://github.com/clerk-community/clerk-sdk-flutter/issues/97)
* fix: allow telemetry period to be set from environment too [[#97]](https://github.com/clerk-community/clerk-sdk-flutter/issues/97)
* fix: add check for malformed jwt into session token [[#97]](https://github.com/clerk-community/clerk-sdk-flutter/issues/97)
* feat: add external accounts to user profile and start connect account journey [[#118]](https://github.com/clerk-community/clerk-sdk-flutter/issues/118)
* fix: bugs in sign up flow [[#127]](https://github.com/clerk-community/clerk-sdk-flutter/issues/127)
* fix: add failed status to enum [[#112]](https://github.com/clerk-community/clerk-sdk-flutter/issues/112)
* feat: enable `sessionToken()` to return templated JWT tokens for external vendors. [[#93]](https://github.com/clerk-community/clerk-sdk-flutter/issues/93)
* fix: improve multilingual support [[#128]](https://github.com/clerk-community/clerk-sdk-flutter/issues/128)
* fix: connecting a new account [[#121]](https://github.com/clerk-community/clerk-sdk-flutter/issues/121)
* fix: surface server errors in the ui [[#122]](https://github.com/clerk-community/clerk-sdk-flutter/issues/122) 
* feat: replace parameters with config object [[#120]](https://github.com/clerk-community/clerk-sdk-flutter/issues/120)
* fix: amalgamate Closeable and AnimatedCloseable [[#138]](https://github.com/clerk-community/clerk-sdk-flutter/issues/138)
* fix: add translations for sign in error [[#143]](https://github.com/clerk-community/clerk-sdk-flutter/issues/143)
* fix: mark all models as immutable [[#113]](https://github.com/clerk-community/clerk-sdk-flutter/issues/113) 
* fix: add toString to models [[#140]](https://github.com/clerk-community/clerk-sdk-flutter/issues/140)
* fix: refactor attemptSignIn [[#147]](https://github.com/clerk-community/clerk-sdk-flutter/issues/147)
* fix: refactor HttpService [[#149]](https://github.com/clerk-community/clerk-sdk-flutter/issues/149)
* feat: add timeouts to loading overlay [[#142]](https://github.com/clerk-community/clerk-sdk-flutter/issues/142)
* feat: custom sign in example [[#141]](https://github.com/clerk-community/clerk-sdk-flutter/issues/141)

## 0.0.6-dev

- Improve updateUser to utilise environment config [[#98]](https://github.com/clerk-community/clerk-sdk-flutter/issues/98)
- Fix ClerkAuthState missing after telemetry addition [[#102]](https://github.com/clerk-community/clerk-sdk-flutter/issues/102)

## 0.0.5-dev

- Lower flutter version to 3.10.0 [[#41]](https://github.com/clerk-community/clerk-sdk-flutter/issues/41)
- Remove usage of public_key [[#45]](https://github.com/clerk-community/clerk-sdk-flutter/issues/45)
- Add data/state persistor [[#46]](https://github.com/clerk-community/clerk-sdk-flutter/issues/46)
- Add user profile editing [[#55]](https://github.com/clerk-community/clerk-sdk-flutter/issues/55)
- Switch add account routing from overlays to routes [[#58]](https://github.com/clerk-community/clerk-sdk-flutter/issues/58)
- Resolve issues in UI when strategies are missing [[#65]](https://github.com/clerk-community/clerk-sdk-flutter/issues/65)
- Add telemetry support [[#81]](https://github.com/clerk-community/clerk-sdk-flutter/issues/81)
- Remove dependency on inset-box-shadow [[#87]](https://github.com/clerk-community/clerk-sdk-flutter/issues/87)
- Rename ClerkAuthProvider to ClerkAuthState to clarify its usage [[#99]](https://github.com/clerk-community/clerk-sdk-flutter/issues/99)

## 0.0.4-dev

- Improved SSO popup user experience [[#33]](https://github.com/clerk-community/clerk-sdk-flutter/issues/33)
- Updated async initialisation and token refresh [[#42]](https://github.com/clerk-community/clerk-sdk-flutter/issues/42)
- Added documentation [[#36]](https://github.com/clerk-community/clerk-sdk-flutter/issues/36)
- Improved formatting for pub score [[#34]](https://github.com/clerk-community/clerk-sdk-flutter/issues/34) [[#35]](https://github.com/clerk-community/clerk-sdk-flutter/issues/35)

## 0.0.3-dev

- Pre-release alpha.

## 0.0.2-dev

- Pre-alpha development.

## 0.0.1

- Pre-alpha version.
