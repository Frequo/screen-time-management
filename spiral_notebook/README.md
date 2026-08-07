# spiral_notebook

A new Flutter project.

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
ID matches their Firebase Auth UID and reject every other path.

From this directory, deploy the rules with:

```sh
firebase deploy --only firestore:rules
```
