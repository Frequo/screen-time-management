# Screen Time Management

This repository contains two main components:

## 1. Spiral Notebook (Flutter App)

Located in the `spiral_notebook/` directory, this is a cross-platform Flutter application. It includes:

- **User Authentication:** Login screen for account creation and sign-in.
- **Multiple Screens:** Modular screens for home, focus, inventory, character view, gacha, info, and settings.
- **Firebase Integration:** Uses `firebase_core` for backend services.
- **Platform Support:** Android, iOS, web, Windows, macOS, and Linux.
- **Modern UI:** Built with Material Design and theming.

See `spiral_notebook/README.md` for Flutter-specific setup and resources.

## 2. Python Concepts

The `python_concepts.py` file at the root demonstrates basic Python programming concepts, including variables, conditionals, arithmetic, and user input. It is intended for educational or experimental use.

---

### Getting Started

- To run the Flutter app, follow the instructions in `spiral_notebook/README.md`.
- To experiment with Python, run `python3 python_concepts.py` from the root directory.

---

This project is a starting point for both Flutter and Python development. Contributions and improvements are welcome!


Character View Screen:
- in-depth view of the collected characters
- can individually view each character

Cutscene Screen:
- plays the gacha animation after pulling
- animation of an hourglass turning over and the sand forming the result in the bottom half

Focus Screen:
- Screen where you are timed for how long you stay uninterrupted from other things
- Based on this time, it gives a proportional reward

Gacha Screen:
- Show how much reward collected over time
- Can initiate a "pull" when the user has enough rewards
- pity system: guarantee if 200 pulls in

Info Screen:
- this screan should display how this game work essentially the tutorial (it should be simlar to a powerpoint where their a muilitple images and explaintions on them)

Inventory Screen:
- tune the difficulties (elementary - college) which affect reward rate
- start button: transfers to the focus or gacha screen (default inventory screen)

Login Screen:
- login to firebase

Settings Screen:
- accessible from the inventory at the top right corner

Bottom Navigation Bar
Gacha - Inventory - Focus

Art Style:
- similar to Battle Cats, but more colorful and not monochrome

42 Characters:
- chibi people, modern city

TODO: in the character view, there should be an info button in the top right corner that when press shows the artist credits and other metadata.




Checklist:
- Add the difficulty setting card into the onboarding screen
- Character view should be embedded into the inventory screen instead of being a separate screen, and the user can click on each character to view the details
- 