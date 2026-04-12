## 2025-04-12 - Missing ARIA labels on icon-only buttons
**Learning:** Found a specific app-wide accessibility issue pattern where icon-only buttons (like delete buttons in data tables and close buttons in modals) lacked `aria-label` attributes, making them inaccessible to screen readers.
**Action:** Always verify that icon-only buttons (`btn-icon-danger`, `modal-close`) have descriptive `aria-label`s attached to them when creating or modifying components in this app.
