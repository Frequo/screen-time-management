# spiral_notebook

A new Flutter project.

## Character catalog

The live catalog is the Firestore document `catalog/characters` in
`hydroflask-acdaa`. Its shape is `{ "schemaVersion": 1, "characters": [...] }`.
The array preserves display order and publishes a whole roster atomically.
After deploying this app version, edits to that document refresh the roster,
profiles, collection counts, and draw pools while the app is open. Firebase is
currently configured for Android and iOS; other platforms use the local catalog.

Each character has a stable `id`, `name`, `title`, `rarity` (`common`, `rare`,
`epic`, or `legendary`), `description`, eight-digit ARGB hex `accent`, and two
required booleans:

- `pullable`: eligible for normal, tutorial, and pity draws when visible.
- `hidden`: omitted from the roster, profiles, recent results, and draw pools,
  including when already owned. Hidden overrides pullable.

Axel is Common with `pullable: true` and `hidden: false`. The other 42
characters have `pullable: false` and `hidden: true`. A visible but unpullable
character can remain in the collection after a limited release. Preserve IDs
when editing: hiding or removing entries does not delete players' owned copies.
Hidden is a UI setting; the shared catalog can still be read by clients.

Optional `portraitUrl` and `mainUrl` accept HTTPS image URLs (for example,
Firebase Storage download URLs) so new artwork does not require another app
release. Upload artwork before publishing its URL. Version the image URL when
replacing artwork. `portraitAsset` and `mainAsset` provide bundled fallbacks;
omitting them uses the existing placeholder artwork. New bundled directories
must still be registered in `pubspec.yaml` and require an app update.

The app starts with the last valid cached catalog, or `assets/characters.json`
on first launch, then subscribes to Firestore. Missing, malformed, or inaccessible
remote data leaves the last usable catalog in place. Publish an empty
`characters` array to intentionally clear the roster; deleting the document
does not clear cached content. The JSON file is the bootstrap/offline fallback
and initial migration input, not the live source after Firestore is populated.

Rarity weights remain 68/22/9/1 when all rarities are available. Empty pools are
excluded and the remaining weights normalized. With only Axel released, Common
is 100%. Pity accumulates until a visible, pullable legendary is released. An
empty draw pool disables draws without spending bits or changing pity.

### First-time Firestore migration

Preview the exact release configuration without credentials or dependencies:

```sh
node tools/seed_character_catalog.mjs --project hydroflask-acdaa
```

Install the migration dependencies and configure
[Application Default Credentials](https://firebase.google.com/docs/admin/setup#initialize_the_sdk_in_non-google_environments)
for a project administrator (for example, `gcloud auth application-default login`).
The app never receives administrative credentials.

```sh
cd tools
npm install
cd ..
node tools/seed_character_catalog.mjs --project hydroflask-acdaa --apply
firebase deploy --only firestore:rules --project hydroflask-acdaa
```

The script creates `catalog/characters`, verifies the saved values, and refuses
to overwrite an existing catalog. If Firebase CLI authentication has expired,
run `firebase login --reauth` before deploying the rules. Client rules allow
only reading this catalog document; publish later changes through the Firebase
console or trusted Admin SDK tooling. A successful preview alone does not
publish anything.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firestore rules

The app stores each account's profile and progress at `users/{uid}`. The
checked-in rules allow an authenticated user to access only the document whose
ID matches their Firebase Auth UID. The shared `catalog/characters` document
allows reads only; every other path is rejected.

From this directory, deploy the rules with:

```sh
firebase deploy --only firestore:rules
```
