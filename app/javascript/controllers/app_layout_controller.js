import { Controller } from "@hotwired/stimulus";

// The app shell: the phone's menu sheet and the assistant panel on the right.
// Connects to data-controller="app-layout"
export default class extends Controller {
  static targets = ["rightSidebar", "mobileSidebar"];
  static values = { userId: String };
  static classes = [
    "expandedSidebar",
    "collapsedSidebar",
    "expandedTransition",
    "collapsedTransition",
  ];

  openMobileSidebar() {
    this.mobileSidebarTarget.classList.remove("hidden");
  }

  closeMobileSidebar() {
    this.mobileSidebarTarget.classList.add("hidden");
  }

  toggleRightSidebar() {
    const isOpen = this.rightSidebarTarget.classList.contains("w-full");
    this.#updateUserPreference("show_ai_sidebar", !isOpen);
    this.#toggleSidebarWidth(this.rightSidebarTarget, isOpen);
  }

  // For actions that send content into the chat sidebar (quick prompts,
  // AI review): make sure it is visible, and never close it.
  openRightSidebar() {
    const isOpen = this.rightSidebarTarget.classList.contains("w-full");
    if (isOpen) return;

    this.#updateUserPreference("show_ai_sidebar", true);
    this.#toggleSidebarWidth(this.rightSidebarTarget, false);
  }

  #toggleSidebarWidth(el, isCurrentlyOpen) {
    const expandedClasses = [...this.expandedSidebarClasses, "border-l"];
    const collapsedClasses = [...this.collapsedSidebarClasses, "border-l-0"];

    if (isCurrentlyOpen) {
      el.classList.remove(...expandedClasses);
      el.classList.add(...collapsedClasses);
      el.inert = true;
    } else {
      el.classList.add(...expandedClasses);
      el.classList.remove(...collapsedClasses);
      el.inert = false;
    }
  }

  #updateUserPreference(field, value) {
    fetch(`/users/${this.userIdValue}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        Accept: "application/json",
      },
      body: new URLSearchParams({
        [`user[${field}]`]: value,
      }).toString(),
    });
  }
}
