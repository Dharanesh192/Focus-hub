# How Flutter Turns Code into UI

Flutter doesn't draw your UI directly from the Dart code you write. It goes through a series of transformations — each one turning a more abstract representation into a more concrete one — until it finally becomes pixels on the screen. Below is the step-by-step journey.

```
Code → Compiled Code → Executable → Runtime → Widget Tree → Element Tree → RenderObject Tree → Screen
```

---

## Step 1: The Code

This is the Dart source code you actually write — your `StatelessWidget`s, `StatefulWidget`s, and everything wired together with `build()` methods. At this stage, it's just text in `.dart` files sitting in your project.

## Step 2: `flutter run command` Compiles the Code

When you run the flutter run command, Flutter takes your source `code` and compiles it. This is the point where your human-readable Dart gets processed by the compiler into a form the machine can work with.

## Step 3: Compiled Code Becomes Executable Code

The output of the compile step is `compiled code`, which is then turned into `executable code` — the actual binary/package that can be launched on a device or emulator. This is no longer "your code" in a readable sense; it's ready to run.

## Step 4: The Runtime Takes Over

Once the executable is launched, the **Flutter runtime** kicks in. During the runtime, the compiled code is loaded into `[built()]`, kicking off the process that builds the **Widget Tree**. This is the transition point from "static compiled program" to "a live, running app that is actively constructing its UI."

## Step 5: The Widget Tree is Built

This is the first UI-related structure Flutter builds. It's a basic tree of `Element` nodes describing **what** the UI should look like — a blueprint, not the actual rendering.

```
        Element
       /        \
   Element     Element
      |
   Element
```

A widget tree is fundamentally **immutable and lightweight** — it's just configuration. Every time `build()` runs, a brand new widget tree is created. This is why widgets themselves are cheap to create and throw away.

## Step 6: The Widget Tree Becomes the Element Tree

This is a **runtime structure** of the widget tree, known as the **Element Tree**. It contains the build/content for each element and maintains:
- The **child-parent relationship** between elements and their properties
- The **lifecycle information** of each element (created, mounted, updated, disposed)

Unlike the widget tree, the element tree is **persistent** — it survives across rebuilds. Flutter reuses existing elements when possible instead of recreating them, which is a big part of why Flutter's rebuilds are fast. The element tree acts as the glue between the widget tree (what to show) and the render tree (how to actually paint it).

## Step 7: The Element Tree Produces the RenderObject Tree

Each element that needs to be drawn on screen is linked to a **RenderObject**. Together, these form the **RenderObject Tree**.

```
                        RenderView
                       /    |     \      \
                Heading  TextField  Paragraph  Image
```

This tree performs and handles the **actual UI work**:
- **Layout** — figuring out size and position
- **Painting** — calculating pixels and how things visually appear

It also **provides constraints and size information** to both the parent and child render objects, so each element knows how much space it has and how much space it needs — this negotiation between parent and child constraints is core to how Flutter's layout algorithm works.

## Step 8: Pixels on Screen

Once the RenderObject Tree has computed layout and painting, Flutter composites everything and hands it off to the GPU to actually display it on screen — completing the journey from `code` to pixels.

---

## Quick Recap

| Stage | What it represents | Mutability |
|---|---|---|
| Code | Human-written Dart | N/A |
| Compiled/Executable Code | Machine-runnable binary | N/A |
| Widget Tree | Blueprint / configuration ("what") | Immutable, rebuilt often |
| Element Tree | Runtime structure, manages lifecycle | Persistent, reused across rebuilds |
| RenderObject Tree | Layout + painting ("how") | Persistent, mutated in place |

**Core idea:** The Widget Tree describes *what* the UI should look like, the Element Tree manages *how it's connected and remembered* over time, and the RenderObject Tree actually *does the work* of measuring, positioning, and painting pixels.

## Notes on Widget Tree Structure

A widget tree is a basic hierarchy of one or more widget classes. It contains the configuration of each widget, what its children widgets contain, what its parent widget contains, and how this configuration ties together across the tree.

As widget description is a `[widget of the widget tree]`, this can combine together to form the whole widget tree.
