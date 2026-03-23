# Error Handling & Display System Plan (Revised)

## Problem Statement

The UI isn't rendering properly and there are no visible error messages when things fail. Users get no feedback when:
- Compilation fails
- Rendering fails  
- Any backend operation fails

## Current Architecture Analysis

### Existing Error Handling

| Component | Status | Notes |
|-----------|--------|-------|
| `DotPrompt.compile/3` | ✅ Returns `{:error, %{error: "type", message: "..."}}` | Already has structured errors |
| `DotPrompt.render/4` | ✅ Returns `{:error, %{error: "type", message: "..."}}` | Already has structured errors |
| `CompileController` | ✅ Returns JSON errors | But errors may not reach LiveView |
| `RenderController` | ✅ Returns JSON errors | But errors may not reach LiveView |
| `ViewerLive` | ✅ Has error display | Lines 69-74 show errors |
| `DevUI` (LiveView) | ❌ Error NOT rendered | `@error` assign exists but template doesn't display it |

### Critical Gaps (Refined)

1. **Missing HTML error renderer** - `config/config.exs` only defines JSON format
2. **Error display missing in DevUI** - Template never renders `@error` assign
3. **HTTP-to-LiveView error flow** - Controller errors don't propagate to LiveView socket
4. **No tests** - Error paths aren't tested

---

## Solution Architecture

```mermaid
graph TB
    subgraph "Error Sources"
        A[DotPrompt Library] --> B[HTTP API]
        A --> C[Direct LiveView Call]
    end
    
    subgraph "Error Flow Problem"
        B -->|Current| D[No path to LiveView]
        C -->|Works| E[@error assign set]
    end
    
    subgraph "Required Fix"
        B --> F[push_event to LiveView]
        F --> G[@error assign updated]
    end
    
    subgraph "Display"
        G --> H[Error Banner in DevUI]
    end
    
    style D fill:#ff6b6b
    style F fill:#51cf66
    style H fill:#51cf66
```

---

## Implementation Tasks (Revised)

### Phase 1: Fix Endpoint & Create ErrorHTML (P0 - Atomic)

#### Task 1.1: Create ErrorHTML Controller
- **File**: `apps/dot_prompt_server/lib/dot_prompt_server_web/controllers/error_html.ex`
- **Create**: ErrorHTML controller with render/2
- **Handle**: 404, 500, 403, and other common errors
- **Return**: Simple HTML error page with message
- **Status**: [ ]

#### Task 1.2: Wire ErrorHTML in Endpoint Config
- **File**: `config/config.exs`
- **Modify**: Add `html: DotPromptServerWeb.ErrorHTML` to render_errors
- **Status**: [ ]

### Phase 2: Fix Error Flow from Controllers to LiveView (P0)

#### Task 2.1: Audit HTTP Error Paths
- **Check**: How compile/render errors reach the UI
- **Issue**: Controllers return JSON but LiveView doesn't consume them
- **Status**: [ ]

#### Task 2.2: Implement HTTP-to-LiveView Error Flow
- **Option A**: Use `push_event` to send errors from controller responses to LiveView
- **Option B**: Have LiveView call HTTP APIs directly via `Phx.Gen` or internal API
- **Decision**: Likely Option B is cleaner - have LiveView make the compile/render calls directly
- **Status**: [ ]

### Phase 3: Add Error Display to DevUI (P0)

#### Task 3.1: Add Error Banner to DevUI Template
- **Location**: `dev_ui.ex` render function
- **Add**: Error banner section (similar to viewer_live.ex:69-74)
- **Content**: 
  - Error type (e.g., "syntax_error")
  - Error message (user-friendly)
  - Context (file, line number if available)
  - Actionable guidance (e.g., "Check line X for invalid syntax")
- **UX**: Dismissible, but allows viewing last error
- **Status**: [ ]

#### Task 3.2: Ensure All Error Cases Set @error Assign
- **Audit**: All `do_compile`, `handle_event`, etc. paths
- **Ensure**: Every error case sets `error` assign with message
- **Status**: [ ]

### Phase 4: Error Classification & Context (P1)

#### Task 4.1: Audit Existing Error Types
- **Review**: What error types does DotPrompt actually emit?
- **List**: syntax_error, validation_error, param_error, runtime_error, etc.
- **Goal**: Don't create new taxonomy - use existing one
- **Status**: [ ]

#### Task 4.2: Add Contextual Information to Errors
- **Enhance**: Error messages to include:
  - File name (for file-based errors)
  - Line/column numbers (for parse errors)
  - Parameter name (for param errors)
- **Example**: "syntax_error at line 5: unexpected token '}'"
- **Status**: [ ]

### Phase 5: Testing (P1)

#### Task 5.1: Unit Test Controller Error Responses
- **Files**: CompileController, RenderController
- **Test**: Each error case returns proper JSON
- **Status**: [ ]

#### Task 5.2: Integration Test Error Banner
- **Test**: LiveView displays error banner when compilation fails
- **Status**: [ ]

---

## File Changes Summary

| File | Change Type | Priority |
|------|-------------|----------|
| `config/config.exs` | Modify | P0 |
| `lib/dot_prompt_server_web/controllers/error_html.ex` | Create | P0 |
| `lib/dot_prompt_server_web/live/dev_ui.ex` | Modify | P0 |
| `lib/dot_prompt_server_web/controllers/compile_controller.ex` | Modify | P0 |
| `lib/dot_prompt_server_web/controllers/render_controller.ex` | Modify | P0 |
| `lib/dot_prompt.ex` | Modify | P1 |

---

## Success Criteria

After implementation:
1. ✅ Any compilation error shows a clear error banner in the DevUI
2. ✅ Any render error shows a clear error message  
3. ✅ HTTP errors (404, 500) show proper HTML error pages
4. ✅ Error messages include context (file, line, parameter name)
5. ✅ Error messages provide actionable guidance
6. ✅ Error paths are tested

---

## Notes

- **Deferred**: Telemetry integration - separate concern with its own design
- **Not needed**: handle_disconnect callback - for network issues, not app errors
- **ViewerLive reference**: Uses pattern at lines 69-74 for error banner

---

## Testing Checklist

| Test | Description |
|------|-------------|
| Controller returns 422 on compile error | Verify JSON error response |
| Controller returns 422 on render error | Verify JSON error response |
| LiveView shows error banner | Integration test |
| Error banner shows message + context | UX verification |
| 404 shows HTML page | HTTP error handling |
| 500 shows HTML page | HTTP error handling |
