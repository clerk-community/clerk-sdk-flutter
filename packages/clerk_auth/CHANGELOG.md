## 0.0.18-beta

* chore: bump `clerk_auth` to `0.0.18-beta`

## 0.0.17-beta

* fix: minor fix to new_release tool
* chore: community org metadata and framing [[#433]](https://github.com/clerk-community/clerk-sdk-flutter/issues/433)
* test(patrol): sign in with google [[#410]](https://github.com/clerk-community/clerk-sdk-flutter/issues/410)
* feat: client trust [[#419]](https://github.com/clerk-community/clerk-sdk-flutter/issues/419)

## 0.0.16-beta

* fix(clerk_auth): offline sign out [[#403]](https://github.com/clerk-community/clerk-sdk-flutter/issues/403)
* feat(clerk_auth): added immutable to user attribute data [[#406]](https://github.com/clerk-community/clerk-sdk-flutter/issues/406)

## 0.0.15-beta

* feat: add passkey support [[#300]](https://github.com/clerk-community/clerk-sdk-flutter/issues/300) 
* feat: add default session token template [[#354]](https://github.com/clerk-community/clerk-sdk-flutter/issues/354)
* feat: add metadata to sign up [[#355]](https://github.com/clerk-community/clerk-sdk-flutter/issues/355)
* fix: make client persist [[#348]](https://github.com/clerk-community/clerk-sdk-flutter/issues/348)
* feat: improve testing [[#350]](https://github.com/clerk-community/clerk-sdk-flutter/issues/350)
* fix: improve sign up panel [[#356]](https://github.com/clerk-community/clerk-sdk-flutter/issues/356)
* fix: regression introduced to pollforsessiontoken [[#363]](https://github.com/clerk-community/clerk-sdk-flutter/issues/363)
* fix: add explicit resend code function [[#365]](https://github.com/clerk-community/clerk-sdk-flutter/issues/365)
* chore(clerk_auth): upgrade to api version 2025-11-10 [[#371]](https://github.com/clerk-community/clerk-sdk-flutter/issues/371)
* fix: consolidate oauth token sign in methods [[#380]](https://github.com/clerk-community/clerk-sdk-flutter/issues/380)
* fix: make sign in with apple work [[#384]](https://github.com/clerk-community/clerk-sdk-flutter/issues/384)
* fix: change healthcheck endpoint [[#376]](https://github.com/clerk-community/clerk-sdk-flutter/issues/376)
* fix(clerk_auth): unblock CORS preflight on Flutter Web [[#395]](https://github.com/clerk-community/clerk-sdk-flutter/issues/395)
* fix(clerk_flutter): example app working on android [[#397]](https://github.com/clerk-community/clerk-sdk-flutter/issues/397)

## 0.0.14-beta

* BREAKING CHANGE: The `ClerkDeepLink` class has been removed, since the information
  it carried is no longer being used. Deep links are now passed into the Clerk SDK 
  as `Stream<Uri?> deepLinkStream` in the `ClerkAuthConfig`. 

* feat: deprecate strategy in clerkdeeplink [[#345]](https://github.com/clerk-community/clerk-sdk-flutter/issues/345)
* fix: make sso sign up complete [[#343]](https://github.com/clerk-community/clerk-sdk-flutter/issues/343)
* feat: expose externalid on user object [[#339]](https://github.com/clerk-community/clerk-sdk-flutter/issues/339)
* feat: push error stream up to clerk_flutter [[#335]](https://github.com/clerk-community/clerk-sdk-flutter/issues/335)
* fix: ensure api throws external errors rather than clerk errors [[#331]](https://github.com/clerk-community/clerk-sdk-flutter/issues/331)
* feat: improve second factor flow, now supports TOTP [[#325]](https://github.com/clerk-community/clerk-sdk-flutter/issues/325) [[#328]](https://github.com/clerk-community/clerk-sdk-flutter/issues/328)
* fix: add externalerrorcollection to autherror [[#316]](https://github.com/clerk-community/clerk-sdk-flutter/issues/316)
* feat: enable setting of primary email address and phone number [[#310]](https://github.com/clerk-community/clerk-sdk-flutter/issues/310)
* feat: apple and google auth token support [[#308]](https://github.com/clerk-community/clerk-sdk-flutter/issues/308)
* feat: delete identifying data [[#309]](https://github.com/clerk-community/clerk-sdk-flutter/issues/309)
* fix: sso sign up [[#306]](https://github.com/clerk-community/clerk-sdk-flutter/issues/306)
* fix: improve phone number handling [[#304]](https://github.com/clerk-community/clerk-sdk-flutter/issues/304)
* feat: add low-level access to api [[#301]](https://github.com/clerk-community/clerk-sdk-flutter/issues/301)

## 0.0.13-beta

* feat: make test helpers globally available [[#292]](https://github.com/clerk-community/clerk-sdk-flutter/issues/292)
* fix: make updates only happen when details change [[#286]](https://github.com/clerk-community/clerk-sdk-flutter/issues/286)
* fix: accept 'required' fields [[#285]](https://github.com/clerk-community/clerk-sdk-flutter/issues/285)
* fix: test framework [[#281]](https://github.com/clerk-community/clerk-sdk-flutter/issues/281)
* fix: set polling periods to zero for testing [[#283]](https://github.com/clerk-community/clerk-sdk-flutter/issues/283)
* feat: improve email link sign in up [[#267]](https://github.com/clerk-community/clerk-sdk-flutter/issues/267)
* fix: only poll when signed in [[#275]](https://github.com/clerk-community/clerk-sdk-flutter/issues/275)
* fix: add housekeeping where missing [[#279]](https://github.com/clerk-community/clerk-sdk-flutter/issues/279)
* fix: move session token polling from api to auth for better error reporting [[#244]](https://github.com/clerk-community/clerk-sdk-flutter/issues/244)
* feat: bring sign up ux in line with other sdks [[#246]](https://github.com/clerk-community/clerk-sdk-flutter/issues/246)
* fix: force org creation when needed [[#271]](https://github.com/clerk-community/clerk-sdk-flutter/issues/271)
* change: session token polling now defaults to ON (previous versions had it defaulting to OFF) [[#263]](https://github.com/clerk-community/clerk-sdk-flutter/issues/263)
* fix: bring session token polling with orgs inline with other SDKs [[#263]](https://github.com/clerk-community/clerk-sdk-flutter/issues/263)
* fix: remove unnecessary email etc update [[#265]](https://github.com/clerk-community/clerk-sdk-flutter/issues/265)
* feat: enable sign up with enterprise sso [[#247]](https://github.com/clerk-community/clerk-sdk-flutter/issues/247)
* fix: enable sign in using enterprise sso [[#248]](https://github.com/clerk-community/clerk-sdk-flutter/issues/248)

## 0.0.12-beta

* fix: ensure decoding of UserPublic.identifier is optional [[#256]](https://github.com/clerk-community/clerk-sdk-flutter/issues/256)

## 0.0.11-beta

* fix: ensure all params are trimmed [[#236]](https://github.com/clerk-community/clerk-sdk-flutter/issues/236)
* fix: amend persistor docs [[#235]](https://github.com/clerk-community/clerk-sdk-flutter/issues/235)
* fix: allow email address to be edited for verification [[#226]](https://github.com/clerk-community/clerk-sdk-flutter/issues/226)
* fix: enable legal consent confirmation [[#222]](https://github.com/clerk-community/clerk-sdk-flutter/issues/222)
* fix: resolve issues with the sessionTokenStream [[#221]](https://github.com/clerk-community/clerk-sdk-flutter/issues/221)
* fix: support offline better [[#212]](https://github.com/clerk-community/clerk-sdk-flutter/issues/212)
* fix: make google authentication work directly with tokens [[#207]](https://github.com/clerk-community/clerk-sdk-flutter/issues/207)

## 0.0.10-beta

* fix: added Facebook as strategy [[#172]](https://github.com/clerk-community/clerk-sdk-flutter/issues/172)
* feat: add oauth token sign in [[#186]](https://github.com/clerk-community/clerk-sdk-flutter/issues/186)
* feat: add a stream of updating session tokens as they renew [[#165]](https://github.com/clerk-community/clerk-sdk-flutter/issues/165)
* feat: add password reset flow [[#161]](https://github.com/clerk-community/clerk-sdk-flutter/issues/161)
* feat: allow user deletion via api [[#174]](https://github.com/clerk-community/clerk-sdk-flutter/issues/174)
* feat: **BREAKING** add Persistor and HttpService to ClarkAuthConfig [[#183]](https://github.com/clerk-community/clerk-sdk-flutter/issues/183)
* feat: add flags to ClarkAuthConfig [[#195]](https://github.com/clerk-community/clerk-sdk-flutter/issues/195)
* feat: add offline support [[#200]](https://github.com/clerk-community/clerk-sdk-flutter/issues/200)

## 0.0.9-beta

* chore: align release version with `clerk_flutter` package

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
- Disable bot protection [[#66]](https://github.com/clerk-community/clerk-sdk-flutter/issues/66)
- Remove favicon_image from display_config [[#88]](https://github.com/clerk-community/clerk-sdk-flutter/issues/88)
- Upload images using byte arrays [[#79]](https://github.com/clerk-community/clerk-sdk-flutter/issues/79)
- Add telemetry support [[#81]](https://github.com/clerk-community/clerk-sdk-flutter/issues/81)

## 0.0.4-dev

- Updated token expiration to use UTC [[#47]](https://github.com/clerk-community/clerk-sdk-flutter/issues/47)
- Added regular poll for session token (optional) [[#42]](https://github.com/clerk-community/clerk-sdk-flutter/issues/42)
- Added documentation [[#36]](https://github.com/clerk-community/clerk-sdk-flutter/issues/36)
- Improved formatting for pub score [[#34]](https://github.com/clerk-community/clerk-sdk-flutter/issues/34) [[#35]](https://github.com/clerk-community/clerk-sdk-flutter/issues/35)

## 0.0.3-dev

- Pre-release alpha.

## 0.0.2-dev

- Pre-alpha development.

## 0.0.1

- Pre-alpha version.
