# Plan: In-Place Prompt Editor

## Problem Statement
The current prompt editor has layout shifting issues when editing lines:
- When a user clicks/double-clicks to edit a line, the text jumps around
- The textarea appears in place but causes visual displacement
- Text doesn't stay in place during editing

## User Clarification (March 22, 2026)
- "When I click on a line the textarea is a small area on the left - it doesn't take the same place or space as the text"
- "Instead of using a textarea, use a form field"

## Current Implementation Analysis

### Source Editor Component (dev_ui.ex lines 279-321)
```elixir
# Current structure - each line:
<div class="cl">
  <span class="ln">line number</span>
  <%= if @editing_line == i do %>
    <form>  # <-- Replaces .cc span entirely
      <textarea>line content</textarea>
    </form>
  <% else %>
    <span class="cc">line content</span>
  <% end %>
</div>
```

### CSS Classes (root.html.heex)
- `.cl`: `display: flex; align-items: flex-start; position: relative;`
- `.cc`: `flex: 1; white-space: pre-wrap; word-break: break-word;`
- `.ln`: `width: 40px; flex-shrink: 0;`

### Root Cause of Layout Shift
1. The `<span class="cc">` containing the text is completely replaced with a `<form><textarea>`
2. The textarea has different box model properties
3. No explicit height on textarea causes it to be smaller than the content
4. **CRITICAL**: Textarea appears in the wrong position (on the left instead of after line number)

## Proposed Solution: In-Place Form Field Editing

### Key Changes
1. **Replace `<textarea>` with `<input type="text">` (form field)**
   - Single-line input field that matches the text styling
   - Easier to position and size correctly
   
2. **Fix positioning**
   - Input must start AFTER the line number (after the 40px line number column)
   - Must fill the SAME space as the original text content
   
3. **Fix sizing**
   - Set explicit height to match the line height
   - Width: 100% to fill the content area

### Implementation Steps

**Step 1: Modify source_editor in dev_ui.ex**
- Replace `<textarea>` with `<input type="text">`
- Add proper class for styling

**Step 2: Add CSS in root.html.heex**
- Style the input to match `.cc` styling
- Position after line number (left: 40px)
- Set width to fill content area

**Step 3: Add JavaScript in app.js**
- Auto-focus input when editing starts
- Handle Enter key to save
- Handle Escape to cancel

### Files to Modify

1. **dot_prompt/apps/dot_prompt_server/lib/dot_prompt_server_web/live/dev_ui.ex**
   - Modify `source_editor` component (lines 279-321)
   - Replace textarea with input type="text"

2. **dot_prompt/apps/dot_prompt_server/assets/js/app.js**
   - Update SectionEdit hook for input handling

3. **dot_prompt/apps/dot_prompt_server/lib/dot_prompt_server_web/layouts/root.html.heex**
   - Add CSS for input positioning and styling

## Success Criteria
- [ ] Form field appears in the correct position (after line number)
- [ ] Form field fills the same width as the original text
- [ ] Form field matches the text styling (font, size, color)
- [ ] Single-click and double-click work as expected
- [ ] Enter key saves, Escape cancels editing
