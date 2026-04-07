package dotprompt

import (
	"strings"
	"testing"
)

// --- Happy Paths ---

func TestHappyPaths(t *testing.T) {
	comp := NewCompiler("")

	t.Run("Variables", func(t *testing.T) {
		prompt := "Hello @name!"
		params := map[string]interface{}{"name": "World"}
		out, _ := comp.CompileString(prompt, params)
		if out != "Hello World!" {
			t.Errorf("Expected Hello World!, got %q", out)
		}
	})

	t.Run("ComplexityIfElifElse", func(t *testing.T) {
		prompt := `if @v is 'a' do
A
elif @v is 'b' do
B
else do
C
end if`
		cases := []struct {
			v        string
			expected string
		}{
			{"a", "A"},
			{"b", "B"},
			{"c", "C"},
		}
		for _, tc := range cases {
			out, _ := comp.CompileString(prompt, map[string]interface{}{"v": tc.v})
			if strings.TrimSpace(out) != tc.expected {
				t.Errorf("For %s expected %s, got %s", tc.v, tc.expected, out)
			}
		}
	})

	t.Run("NaturalLanguageOps", func(t *testing.T) {
		params := map[string]interface{}{"age": 25}
		tests := []struct {
			cond     string
			expected bool
		}{
			{"above 20", true},
			{"below 20", false},
			{"min 25", true},
			{"max 24", false},
			{"between 20 and 30", true},
		}
		for _, tt := range tests {
			prompt := "if @age " + tt.cond + " do\nYES\nend if"
			out, _ := comp.CompileString(prompt, params)
			hasYes := strings.Contains(out, "YES")
			if hasYes != tt.expected {
				t.Errorf("Cond %s expected %v, got %v", tt.cond, tt.expected, hasYes)
			}
		}
	})
}

// --- Unhappy Paths ---

func TestUnhappyPaths(t *testing.T) {
	comp := NewCompiler("")

	t.Run("MissingVariable", func(t *testing.T) {
		prompt := "Hello @unknown!"
		out, _ := comp.CompileString(prompt, nil)
		if out != "Hello @unknown!" {
			t.Errorf("Expected leak-through @unknown, got %q", out)
		}
	})

	t.Run("UnclosedBlock", func(t *testing.T) {
		prompt := "init do\nparams:\n@v: str" // missing end init
		_, err := comp.CompileString(prompt, nil)
		if err == nil || !strings.Contains(err.Error(), "missing end init") {
			t.Errorf("Expected 'missing end init' error, got %v", err)
		}
	})

	t.Run("UnclosedIf", func(t *testing.T) {
		prompt := "if @v do\nSomething" // missing end if
		_, err := comp.CompileString(prompt, map[string]interface{}{"v": true})
		if err == nil || !strings.Contains(err.Error(), "missing end for if") {
			t.Errorf("Expected 'missing end for if' error, got %v", err)
		}
	})

	t.Run("RecursionLimit", func(t *testing.T) {
		// Mock a circular fragment by using CompileString with a recursive call
		// Since we don't have a real fs here, we'll verify it returns an error string on fragment error
		// which happens if Compile fails (e.g. file not found or recursion)
		out, _ := comp.CompileString("{missing}", nil)
		if !strings.Contains(out, "FRAGMENT ERROR") {
			t.Errorf("Expected FRAGMENT ERROR placeholder, got %q", out)
		}
	})
}

// --- Role and Message Section Tests ---

func TestRoleAndMessageSections(t *testing.T) {
	comp := NewCompiler("")

	t.Run("RoleFieldInInit", func(t *testing.T) {
		prompt := `init do
  role: assistant
end init
Hello @name!`
		tokens := Tokenize(prompt)
		ast, err := Parse(tokens)
		if err != nil {
			t.Fatalf("Parse failed: %v", err)
		}
		if ast.Schema.Role != "assistant" {
			t.Errorf("Expected role 'assistant', got %q", ast.Schema.Role)
		}
	})

	t.Run("SystemUserContextSections", func(t *testing.T) {
		prompt := `init do
end init
# system
You are a helpful assistant.
# user
Hello @name!
# context
The user is from @country.`
		tokens := Tokenize(prompt)
		ast, err := Parse(tokens)
		if err != nil {
			t.Fatalf("Parse failed: %v", err)
		}
		
		// Check that we have message nodes
		if len(ast.Body) != 3 {
			t.Errorf("Expected 3 message nodes, got %d", len(ast.Body))
		}

		// Check the first node is system
		if msg, ok := ast.Body[0].(MessageNode); ok {
			if msg.Role != RoleSystem {
				t.Errorf("Expected RoleSystem, got %v", msg.Role)
			}
		} else {
			t.Error("First node should be MessageNode")
		}

		// Check the second node is user
		if msg, ok := ast.Body[1].(MessageNode); ok {
			if msg.Role != RoleUser {
				t.Errorf("Expected RoleUser, got %v", msg.Role)
			}
		} else {
			t.Error("Second node should be MessageNode")
		}

		// Check the third node is context
		if msg, ok := ast.Body[2].(MessageNode); ok {
			if msg.Role != RoleContext {
				t.Errorf("Expected RoleContext, got %v", msg.Role)
			}
		} else {
			t.Error("Third node should be MessageNode")
		}
	})

	t.Run("RoleSectionWithVariables", func(t *testing.T) {
		prompt := `init do
end init
# user
Hello @name! You are @age years old.`
		params := map[string]interface{}{"name": "Alice", "age": 30}
		out, err := comp.CompileString(prompt, params)
		if err != nil {
			t.Fatalf("Compile failed: %v", err)
		}
		if out != "Hello Alice! You are 30 years old." {
			t.Errorf("Expected 'Hello Alice! You are 30 years old.', got %q", out)
		}
	})

	t.Run("MixedRoleSectionsAndText", func(t *testing.T) {
		prompt := `init do
end init
# system
You are a calculator.
# user
What is @a + @b?
The answer should be in @format format.`
		params := map[string]interface{}{"a": 5, "b": 3, "format": "JSON"}
		out, err := comp.CompileString(prompt, params)
		if err != nil {
			t.Fatalf("Compile failed: %v", err)
		}
		if !strings.Contains(out, "What is 5 + 3?") {
			t.Errorf("Expected 'What is 5 + 3?', got %q", out)
		}
		if !strings.Contains(out, "JSON format") {
			t.Errorf("Expected 'JSON format', got %q", out)
		}
	})

	t.Run("RoleSectionWithControlFlow", func(t *testing.T) {
		prompt := `init do
end init
# user
@user_input

if @is_question is true do
Please answer this question.
elif @needs_help is true do
Please help me with this.
else
Please proceed normally.
end if`
		params := map[string]interface{}{"user_input": "Hello!", "is_question": true, "needs_help": false}
		out, err := comp.CompileString(prompt, params)
		if err != nil {
			t.Fatalf("Compile failed: %v", err)
		}
		if !strings.Contains(out, "Please answer this question") {
			t.Errorf("Expected 'Please answer this question', got %q", out)
		}
	})
}
