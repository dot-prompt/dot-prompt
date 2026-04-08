package dotprompt

import (
	"strings"
	"testing"
)

// ============================================================================
// INTEGRATION TESTS PART 2
// ============================================================================

func TestEmptyRoleBlocks(t *testing.T) {
	comp := NewCompiler("")

	t.Run("EmptySystemBlock", func(t *testing.T) {
		prompt := "# system\n\n# user\nHello"

		result, err := comp.CompileStringStructured(prompt, nil)
		if err != nil {
			t.Fatalf("CompileStringStructured failed: %v", err)
		}

		if result.System != "" {
			t.Errorf("Expected empty system, got %q", result.System)
		}
	})

	t.Run("EmptyContextBlock", func(t *testing.T) {
		prompt := "# context\n\n# user\nHello"

		out, err := comp.CompileString(prompt, nil)
		if err != nil {
			t.Fatalf("CompileString failed: %v", err)
		}

		if !strings.Contains(out, "Hello") {
			t.Errorf("Expected user content, got %q", out)
		}
	})
}

func TestConsecutiveRoleBlocks(t *testing.T) {
	comp := NewCompiler("")

	t.Run("ConsecutiveSystemBlocks", func(t *testing.T) {
		prompt := "# system\nSystem 1\n# system\nSystem 2\n# user\nUser message"

		out, err := comp.CompileString(prompt, nil)
		if err != nil {
			t.Fatalf("CompileString failed: %v", err)
		}

		if !strings.Contains(out, "System 1") {
			t.Errorf("Expected 'System 1' in output, got %q", out)
		}
		if !strings.Contains(out, "System 2") {
			t.Errorf("Expected 'System 2' in output, got %q", out)
		}
	})
}

func TestStructuredOutputContextMerge(t *testing.T) {
	comp := NewCompiler("")

	t.Run("ContextBeforeUser", func(t *testing.T) {
		prompt := "# system\nSystem prompt.\n---\n# context\nContext data.\n# user\nUser data."

		result, err := comp.CompileStringStructured(prompt, nil)
		if err != nil {
			t.Fatalf("CompileStringStructured failed: %v", err)
		}

		if result.System != "System prompt." {
			t.Errorf("Expected system 'System prompt.', got %q", result.System)
		}
		if !strings.Contains(result.User, "Context data") {
			t.Errorf("Expected context in user field, got %q", result.User)
		}
		if !strings.Contains(result.User, "User data") {
			t.Errorf("Expected user data in user field, got %q", result.User)
		}
	})

	t.Run("MultipleContextBlocks", func(t *testing.T) {
		prompt := "# system\nSystem.\n---\n# context\nContext 1.\n# context\nContext 2.\n# user\nUser."

		result, err := comp.CompileStringStructured(prompt, nil)
		if err != nil {
			t.Fatalf("CompileStringStructured failed: %v", err)
		}

		if !strings.Contains(result.User, "Context 1") {
			t.Errorf("Expected 'Context 1' in user, got %q", result.User)
		}
		if !strings.Contains(result.User, "Context 2") {
			t.Errorf("Expected 'Context 2' in user, got %q", result.User)
		}
	})
}

func TestRoleBlockWithSeparator(t *testing.T) {
	comp := NewCompiler("")

	prompt := "# system\nSystem message.\n---\n# user\nUser message.\n---\nMore user content."

	result, err := comp.CompileStringStructured(prompt, nil)
	if err != nil {
		t.Fatalf("CompileStringStructured failed: %v", err)
	}

	if result.System != "System message." {
		t.Errorf("Expected system 'System message.', got %q", result.System)
	}
	if !strings.Contains(result.User, "User message") {
		t.Errorf("Expected user content, got %q", result.User)
	}
}
