# social_learning

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Backfill existing profile photo sizes

A command-line script now exists at `functions/src/scripts/backfillProfilePhotoSizes.ts` to create
`profilePhotoThumbnail` (320px) and `profilePhotoTiny` (80px) objects for existing users.
It also updates Firestore user fields:

- `profileFireStoragePath`
- `profileThumbnailFireStoragePath`
- `profileTinyFireStoragePath`

### Why this handles permissions safely

The script uses the Firebase Admin SDK, so it runs with service-account IAM permissions and is
not blocked by client-side Firebase Storage security rules that only allow users to write their own
photos. This lets you run a one-time migration without weakening end-user storage rules.

### Run

1. Authenticate with a service account that has Storage Object Admin + Firestore write access.
2. Dry run first:

```bash
npm --prefix functions run backfill:profile-photo-sizes -- --dry-run --limit=20
```

3. Write changes:

```bash
npm --prefix functions run backfill:profile-photo-sizes -- --write
```

Optional flags:

- `--uid=<firebaseAuthUid>` process one user
- `--start-after-uid=<firebaseAuthUid>` resume after a specific uid
- `--limit=<n>` cap records processed in one run

