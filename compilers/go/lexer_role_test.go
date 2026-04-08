package dotprompt

import (
	"testing"
)

// TestLexerRoleTokens tests that role markers are tokenized correctly
func TestLexerRoleTokens(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected TokenType
		value    string
	}{
		{"SystemRole", "# system", TokenRole, "system"},
		{"UserRole", "# user", TokenRole, "user"},
		{"ContextRole", "# context", TokenRole, "context"},
		{"SystemRoleWithSpaces", "#   system  ", TokenRole, "system"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tokens := Tokenize(tt.input)
			if len(tokens) == 0 {
				t.Fatalf("Expected tokens for input %q, got none", tt.input)
			}
			found := false
			for _, tok := range tokens {
				if tok.Type == tt.expected {
					if tok.Value != tt.value {
						t.Errorf("Expected role value %q, got %q", tt.value, tok.Value)
					}
					found = true
					break
				}
			}
			if !found {
				t.Errorf("Expected token type %v for input %q", tt.expected, tt.input)
			}
		})
	}
}

// TestLexerNonRoleComments ensures non-role lines starting with # are not treated as roles
func TestLexerNonRoleComments(t *testing.T) {
	tests := []struct {
		name  string
		input string
	}{
		{"CommentNotRole", "# this is a comment"},
		{"CommentWithHash", "## not a role marker"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tokens := Tokenize(tt.input)
			for _, tok := range tokens {
				if tok.Type == TokenRole {
					t.Errorf("Did not expect TokenRole for %q", tt.input)
				}
			}
		})
	}
}

// TestLexerRoleTokenExtraction verifies multiple role markers in sequence
func TestLexerRoleTokenExtraction(t *testing.T) {
	prompt := `# system
You are a helpful assistant.
# user
Hello
# context
Some context here`

	tokens := Tokenize(prompt)

	roleTokens := make([]Token, 0)
	for _, tok := range tokens {
		if tok.Type == TokenRole {
			roleTokens = append(roleTokens, tok)
		}
	}

	if len(roleTokens) != 3 {
		t.Fatalf("Expected 3 role tokens, got %d", len(roleTokens))
	}

	expectedRoles := []string{"system", "user", "context"}
	for i, expected := range expectedRoles {
		if roleTokens[i].Value != expected {
			t.Errorf("Expected role %q at position %d, got %q", expected, i, roleTokens[i].Value)
		}
	}
}
