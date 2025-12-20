# AGENTS.md – Learning Lab Flutter App

## Project Overview
Flutter + Firebase app for **cascading peer learning**.  
Students learn a mini-lesson from an advanced peer, then teach it forward.
Instructors build a curriculum of Lessons, monitor progress, and coordinate Sessions.
Students can find other students to learn from, teach to, and track their progress.

## Unique Terms
- **Lesson**: An atomic unit of learning, e.g. a mini-lesson. Lesson DOES NOT mean a course session. A course session is referred to as a **Session**.
- **Teachable Item**: A teachable item is an atomic unit of a subject that can be taught. It's used by instructors to build a curriculum. The teachable item is not part of the final curriculum. A lesson is going to teach the teachable item. Think of the teachable item as the concept of a particular chess opening. And the lesson is the approach on how that would be taught.

## Architecture Rules
- Each Firebase collection has a data class, e.g. Course.
- Each data class has a corresponding `XxxFunctions` class for Firestore access, e.g. CourseFunctions.
- All Firebase access is encapsulated in these `XxxFunctions` classes.
- **DON’T** call Firebase APIs directly from widgets, providers, or models.
- **DO** keep provider names in `XxxState` form to signal state holders.

## UX Guidelines
- Make icons grey by default unless there is a special reason.
- Do not use absolute width or height. Use dynamic layouts based on the available width (e.g. all available width or split the width among two children as 1:3). Exceptions are things like profile image icons, which can have a max radius. Basically, some things should appear a certain size like icons or avatars. However, for actually laying out things, use responsive/adaptable dimensions, no absolute width/height

## Coding Style
- When structuring methods, break them into units that do one logical thing. Prefer to make a sub-method for each logical unit. For example, instead of one giant method that does everything, break it down. Concrete example: To join a session has these steps: (1) load the session info. (2) If the user is already an inactive participant, reactivate the user. (3) Otherwise, add the user to the session. If all of this is three lines of code, leave it as a single method. However, if each step requires doing work, create sub-methods for each. That way the high level idea is clearly captured in the top level method.
- Prefer using types for references over using var.
- Prefer using types for references in methods over final.
- Prefer one class per file with exceptions for stateful widgets where it makes sense to combine the widget and state class. Also page arguments are fine in the same page. However, especially of a page has classes for widgets, the pattern is to create a subdirectory for each page under helper_widgets. (If the page is called CourseHomePage, it would have a subdirectory called course_home where all its classes for widgets go.)

## Build & Test Commands
```bash
flutter pub get
flutter analyze
flutter test
