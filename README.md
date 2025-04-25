# ✅ Tasker - Simple macOS Menu Bar Task List

Tasker is a lightweight macOS application that lives in your menu bar, providing a quick and easy way to manage your daily tasks.

## ✨ Features

*   🖱️ **Menu Bar Access:** Quickly access your tasks from the system menu bar.
*   ➕ **Add Tasks:** Easily add new tasks via a text field in the popover.
*   ✔️ **Mark Complete:** Toggle task completion status with a click. Completed tasks are visually struck through.
*   🗑️ **Delete Tasks:** Remove individual tasks using the 'x' button that appears on hover.
*   🧹 **Remove Completed:** Clear all completed tasks from the list with a single button.
*   💨 **Clear List:** Remove all tasks from the list.
*   👻 **Transient Popover:** The task list appears in a popover window that dismisses automatically when you click elsewhere.
*   💫 **Animated Interface:** Uses subtle animations for adding, deleting, and completing tasks, and for popover resizing.
*   🚫 **Dock Icon Behavior:** The app icon briefly appears in the Dock on launch and then hides, running solely from the menu bar.
*   ➡️🖱️ **Right-Click Menu:** Right-click the menu bar icon for "About" and "Quit" options.

## 🚀 Installation (Recommended)

1.  **Download:** ⬇️ Go to the [Releases page](https://github.com/TJacks0n/Tasker/releases) (replace with your actual repo URL if different) and download the latest `.dmg` file.
2.  **Open DMG:** 💾 Double-click the downloaded `.dmg` file to open it.
3.  **Install:** 📦 Drag the `Tasker.app` icon into your `Applications` folder.
4.  **Launch:** ▶️ Open the `Tasker` application from your `Applications` folder. You may need to grant permissions the first time you run it. The Tasker icon will appear in your menu bar.

## 🛠️ Building & Running from Source

1.  **Clone the Repository:** 💻
    ```bash
    git clone https://github.com/TJacks0n/Tasker.git # Replace with your actual repo URL if different
    cd Tasker
    ```
2.  **Open in Xcode:** 🔧
    *   Open the `Tasker.xcodeproj` file in Xcode.
3.  **Select Target:** 🎯
    *   In the scheme menu at the top of the Xcode window (next to the Run/Stop buttons), select the `Tasker` scheme and choose `My Mac` as the target device.
4.  **Build & Run:** ▶️
    *   Press `Cmd+R` or click the Run button (▶) in Xcode.
    *   This will build the application and run it. The Tasker icon should appear in your macOS menu bar.

## 📖 Usage

*   🖱️ **Click** the Tasker icon in the menu bar to show/hide the task list popover.
*   ⌨️ **Type** a task in the text field and press `Enter` to add it.
*   ✅ **Click** the checkbox next to a task to mark it as complete/incomplete.
*   🖱️👆 **Hover** over a task to reveal the delete (`x`) button. Click it to remove the task.
*   🗑️ Use the **"Remove Completed"** or **"Clear List"** buttons at the bottom of the popover.
*   ➡️🖱️ **Right-click** the Tasker icon in the menu bar for the `About` and `Quit` options.
