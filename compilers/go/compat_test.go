package dotprompt

import (
	"strings"
	"testing"
)

// ============================================================================
// BACKWARD COMPATIBILITY WITH MODE FIELD TESTS
// ============================================================================

func TestBackwardCompatibilityModeField(t *testing.T) {
	tests := []struct {
		name     string
		prompt   string
		expected string
	}{
		{
			name:     "ModeFieldInInit",
			prompt:   "init do\nmode: chat\nend init\nHello",
			expected: "chat",
		},
		{
			name:     "ModeFieldInDef",
			prompt:   "init do\ndef:\nmode: completion\nend init\nHello",
			expected: "completion",
		},
		{
			name:     "ModeFieldWithLeadingWhitespace",
			prompt:   "init do\n  mode: code\nend init\nHello",
			expected: "code",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tokens := Tokenize(tt.prompt)
			ast, err := Parse(tokens)
			if err != nil {
				t.Fatalf("Parse failed: %v", err)
			}

			if ast.Schema.Mode != tt.expected {
				t.Errorf("Expected mode %q, got %q", tt.expected, ast.Schema.Mode)
			}
		})
	}
}

func TestBackwardCompatibilityRoleField(t *testing.T) {
	tests := []struct {
		name     string
		prompt   string
		expected string
	}{
		{
			name:     "RoleFieldInInit",
			prompt:   "init do\nrole: assistant\nend init\nHello",
			expected: "assistant",
		},
		{
			name:     "RoleFieldInDef",
			prompt:   "init do\ndef:\nrole: system\nend init\nHello",
			expected: "system",
		},
		{
			name:     "RoleFieldWithLeadingWhitespace",
			prompt:   "init do\n  role: admin\nend init\nHello",
			expected: "admin",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tokens := Tokenize(tt.prompt)
			ast, err := Parse(tokens)
			if err != nil {
				t.Fatalf("Parse failed: %v", err)
			}

			if ast.Schema.Role != tt.expected {
				t.Errorf("Expected role %q, got %q", tt.expected, ast.Schema.Role)
			}
		})
	}
}

func TestCompilerModeFieldCompatibility(t *testing.T) {
	comp := NewCompiler("")

	t.Run("ModeFieldStillWorks", func(t *testing.T) {
		prompt := `init do
mode: chat
end init
Hello @name!`

		params := map[string]interface{}{"name": "World"}
		out, err := comp.CompileString(prompt, params)
		if err != nil {
			t.Fatalf("CompileString failed: %v", err)
		}

		if !strings.Contains(out, "Hello World!") {
			t.Errorf("Expected 'Hello World!', got %q", out)
		}
	})

	t.Run("RoleFieldInSchema", func(t *testing.T) {
		prompt := `init do
role: assistant
end init
You are @role.`

		out, err := comp.CompileString(prompt, nil)
		if err != nil {
			t.Fatalf("CompileString failed: %v", err)
		}

		if !strings.Contains(out, "You are assistant.") {
			t.Errorf("Expected 'You are assistant.', got %q", out)
		}
	})
}

func TestBackwardCompatibilityMatchField(t *testing.T) {
	prompt := `init do
match: my-prompt
end init
Hello`

	tokens := Tokenize(prompt)
	ast, err := Parse(tokens)
	if err != nil {
		t.Fatalf("Parse failed: %v", err)
	}

	if ast.Schema.Name != "my-prompt" {
		t.Errorf("Expected name 'my-prompt', got %q", ast.Schema.Name)
	}
}

// ============================================================================
// DEPRECATION WARNING TESTS
// ============================================================================

func TestDeprecationNoticeForMode(t *testing.T) {
	// The mode field is deprecated in favor of role field
	// This test verifies backward compatibility
	prompt := `init do
mode: completion
end init
Prompt body`

	tokens := Tokenize(prompt)
	ast, err := Parse(tokens)
	if err != nil {
		t.Fatalf("Parse failed: %v", err)
	}

	if ast.Schema.Mode != "completion" {
		t.Errorf("Expected mode 'completion', got %q", ast.Schema.Mode)
	}
}

func TestRoleFieldPreferred(t *testing.T) {
	// Role field is the preferred way to specify message role
	prompt := `init do
role: assistant
end init
# system
You are @role.`

	tokens := Tokenize(prompt)
	ast, err := Parse(tokens)
	if err != nil {
		t.Fatalf("Parse failed: %v", err)
	}

	if ast.Schema.Role != "assistant" {
		t.Errorf("Expected role 'assistant', got %q", ast.Schema.Role)
	}
}

func TestBothModeAndRoleFields(t *testing.T) {
	// When both mode and role are specified, role takes precedence in schema
	// but both should be parsed correctly
	prompt := `init do
mode: chat
role: assistant
end init
Hello`

	tokens := Tokenize(prompt)
	ast, err := Parse(tokens)
	if err != nil {
		t.Fatalf("Parse failed: %v", err)
	}

	// Both should be parsed (backward compatible)
	if ast.Schema.Mode != "chat" {
		t.Errorf("Expected mode 'chat', got %q", ast.Schema.Mode)
	}
	if ast.Schema.Role != "assistant" {
		t.Errorf("Expected role 'assistant', got %q", ast.Schema.Role)
	}
}

func TestDeprecationWarningsDocumented(t *testing.T) {
	// This test documents expected deprecation behavior
	// The 'mode' field should still work but 'role' is preferred

	comp := NewCompiler("")

	// Test that mode field still compiles correctly
	prompt := `init do
mode: deprecated_mode_value
end init
Output with @var`

	params := map[string]interface{}{"var": "test"}
	out, err := comp.CompileString(prompt, params)
	if err != nil {
		t.Fatalf("CompileString failed: %v", err)
	}

	if !strings.Contains(out, "test") {
		t.Errorf("Expected variable substitution, got %q", out)
	}
}
