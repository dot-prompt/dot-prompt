package dotprompt

import (
	"testing"
)

// ============================================================================
// PARSER AST GENERATION TESTS FOR ROLE FIELD AND MESSAGE SECTIONS
// ============================================================================

func TestParserRoleBlocks(t *testing.T) {
	tests := []struct {
		name     string
		prompt   string
		expected int // number of MessageNode in AST body
		roles    []MessageRole
	}{
		{
			name:     "SingleSystemRole",
			prompt:   "# system\nYou are helpful.",
			expected: 1,
			roles:    []MessageRole{RoleSystem},
		},
		{
			name:     "SingleUserRole",
			prompt:   "# user\nHello there!",
			expected: 1,
			roles:    []MessageRole{RoleUser},
		},
		{
			name:     "SingleContextRole",
			prompt:   "# context\nSome context",
			expected: 1,
			roles:    []MessageRole{RoleContext},
		},
		{
			name:     "SystemAndUser",
			prompt:   "# system\nYou are helpful.\n# user\nHello",
			expected: 2,
			roles:    []MessageRole{RoleSystem, RoleUser},
		},
		{
			name:     "AllThreeRoles",
			prompt:   "# system\nYou are AI.\n# context\nContext here.\n# user\nUser message",
			expected: 3,
			roles:    []MessageRole{RoleSystem, RoleContext, RoleUser},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tokens := Tokenize(tt.prompt)
			ast, err := Parse(tokens)
			if err != nil {
				t.Fatalf("Parse failed: %v", err)
			}

			messageNodes := make([]MessageNode, 0)
			for _, node := range ast.Body {
				if msg, ok := node.(MessageNode); ok {
					messageNodes = append(messageNodes, msg)
				}
			}

			if len(messageNodes) != tt.expected {
				t.Errorf("Expected %d message nodes, got %d", tt.expected, len(messageNodes))
			}

			for i, expectedRole := range tt.roles {
				if i >= len(messageNodes) {
					break
				}
				if messageNodes[i].Role != expectedRole {
					t.Errorf("Expected role %v at position %d, got %v", expectedRole, i, messageNodes[i].Role)
				}
			}
		})
	}
}
