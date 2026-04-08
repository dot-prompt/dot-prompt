package dotprompt

import (
	"strings"
	"testing"
)

// ============================================================================
// INTEGRATION TESTS FOR ROLE FIELD AND MESSAGE SECTIONS
// ============================================================================

func TestRoleFieldIntegration(t *testing.T) {
	comp := NewCompiler("")

	t.Run("FullPromptWithAllRolesCompiles", func(t *testing.T) {
		prompt := "# system\nYou are a helpful AI assistant.\nYou specialize in @specialty.\n\n# context\nUser background: @user_background\nPrevious conversation: @history\n\n# user\n@query\n\nPlease provide a detailed response."

		params := map[string]interface{}{
			"specialty":       "programming",
			"user_background": "Experienced developer",
			"history":         "Discussing Go",
			"query":           "Explain Go channels",
		}

		out, err := comp.CompileString(prompt, params)
		if err != nil {
			t.Fatalf("CompileString failed: %v", err)
		}

		// The output should contain all content
		if !strings.Contains(out, "helpful AI assistant") {
			t.Errorf("Expected system content in output, got %q", out)
		}
		if !strings.Contains(out, "programming") {
			t.Errorf("Expected specialty variable in output, got %q", out)
		}
		if !strings.Contains(out, "Experienced developer") {
			t.Errorf("Expected user_background in output, got %q", out)
		}
	})

	t.Run("VariablesResolvedInRoles", func(t *testing.T) {
		prompt := "# system\nYou are a @agent_type.\n# user\nThe user wants: @request"

		params := map[string]interface{}{
			"agent_type": "customer support agent",
			"request":    "help with billing",
		}


		out, err := comp.CompileString(prompt, params)
		if err != nil {
			t.Fatalf("CompileString failed: %v", err)
		}

		if !strings.Contains(out, "customer support agent") {
			t.Errorf("Expected agent_type in output, got %q", out)
		}
		if !strings.Contains(out, "billing") {
			t.Errorf("Expected request in output, got %q", out)
		}
	})

	t.Run("StructuredOutputWithSeparatorPutsBeforeInSystem", func(t *testing.T) {
		// Structured output uses --- separator, not role markers
		prompt := "# system\nSystem content.\n---\nUser content."

		result, err := comp.CompileStringStructured(prompt, nil)
		if err != nil {
			t.Fatalf("CompileStringStructured failed: %v", err)
		}

		if result.System != "System content." {
			t.Errorf("Expected system 'System content.', got %q", result.System)
		}
		if !strings.Contains(result.User, "User content") {
			t.Errorf("Expected user content, got %q", result.User)
		}
	})
}
