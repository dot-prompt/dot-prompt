package dotprompt

import (
	"strings"
	"testing"
)

// ============================================================================
// COMPILER OUTPUT FORMAT TESTS
// ============================================================================

func TestCompilerRoleSectionsOutput(t *testing.T) {
	comp := NewCompiler("")

	t.Run("SystemRoleOutput", func(t *testing.T) {
		prompt := `# system
You are a helpful assistant.
# user
Hello`

		out, err := comp.CompileString(prompt, nil)
		if err != nil {
			t.Fatalf("CompileString failed: %v", err)
		}

		if !strings.Contains(out, "You are a helpful assistant.") {
			t.Errorf("Expected system content in output, got %q", out)
		}
		if !strings.Contains(out, "Hello") {
			t.Errorf("Expected user content in output, got %q", out)
		}
	})

	t.Run("ContextRoleOutput", func(t *testing.T) {
		prompt := `# context
This is context.
# user
This is user input`

		out, err := comp.CompileString(prompt, nil)
		if err != nil {
			t.Fatalf("CompileString failed: %v", err)
		}

		if !strings.Contains(out, "This is context.") {
			t.Errorf("Expected context content in output, got %q", out)
		}
		if !strings.Contains(out, "This is user input") {
			t.Errorf("Expected user content in output, got %q", out)
		}
	})
}

func TestCompilerStructuredOutputWithSeparator(t *testing.T) {
	comp := NewCompiler("")

	t.Run("SeparatorInStructuredOutput", func(t *testing.T) {
		prompt := `# system
System message.
---
# user
User message`

		result, err := comp.CompileStringStructured(prompt, nil)
		if err != nil {
			t.Fatalf("CompileStringStructured failed: %v", err)
		}

		if result.System != "System message." {
			t.Errorf("Expected system 'System message.', got %q", result.System)
		}
		if !strings.Contains(result.User, "CONTEXT") {
			t.Errorf("Expected CONTEXT in user, got %q", result.User)
		}
	})

	t.Run("NoSeparatorPutsEverythingInUser", func(t *testing.T) {
		prompt := `# system
System content.
# user
User content.`

		result, err := comp.CompileStringStructured(prompt, nil)
		if err != nil {
			t.Fatalf("CompileStringStructured failed: %v", err)
		}

		// Without separator, everything goes to user with CONTEXT/TASK separators
		if result.System != "" {
			t.Errorf("Expected empty system, got %q", result.System)
		}
		if !strings.Contains(result.User, "System content") {
			t.Errorf("Expected system content in user, got %q", result.User)
		}
	})
}

func TestCompilerVariablesInRoleSections(t *testing.T) {
	comp := NewCompiler("")

	prompt := `# system
You are a @role.
# user
Your name is @name.`

	params := map[string]interface{}{
		"role": "assistant",
		"name": "Bob",
	}

	out, err := comp.CompileString(prompt, params)
	if err != nil {
		t.Fatalf("CompileString failed: %v", err)
	}

	if !strings.Contains(out, "assistant") {
		t.Errorf("Expected 'assistant' in output, got %q", out)
	}
	if !strings.Contains(out, "Bob") {
		t.Errorf("Expected 'Bob' in output, got %q", out)
	}
}

func TestCompilerRoleWithConditionals(t *testing.T) {
	comp := NewCompiler("")

	prompt := `# system
Base system.
# user
if @show_extra do
Here is extra info.
else do
Basic info.
end if`

	params := map[string]interface{}{"show_extra": true}

	out, err := comp.CompileString(prompt, params)
	if err != nil {
		t.Fatalf("CompileString failed: %v", err)
	}

	if !strings.Contains(out, "extra info") {
		t.Errorf("Expected conditional content in output, got %q", out)
	}
}
