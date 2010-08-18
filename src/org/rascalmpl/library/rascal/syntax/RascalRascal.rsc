module rascal::syntax::RascalRascal


syntax BooleanLiteral
	= lex "false" 
	| lex "true" ;

syntax Literal
	= DateTime: DateTimeLiteral dateTimeLiteral 
	| RegExp: RegExpLiteral regExpLiteral 
	| Real: RealLiteral realLiteral 
	| Integer: IntegerLiteral integerLiteral 
	| Boolean: BooleanLiteral booleanLiteral 
	| String: StringLiteral stringLiteral 
	| Location: LocationLiteral locationLiteral ;

syntax Module
	= Default: Header header Body body ;

syntax Alternative
	= NamedType: Name name Type type ;

syntax ModuleParameters
	= Default: "[" {TypeVar ","}+ parameters "]" ;

syntax DateAndTime
	= lex "$" DatePart "T" TimePartNoTZ TimeZonePart? ;

syntax Asterisk
	= lex [*] 
	# [/] ;

syntax Strategy
	= Outermost: "outermost" 
	| TopDown: "top-down" 
	| BottomUp: "bottom-up" 
	| BottomUpBreak: "bottom-up-break" 
	| TopDownBreak: "top-down-break" 
	| Innermost: "innermost" ;

syntax UnicodeEscape
	= lex "\\" [u]+ [0-9A-Fa-f] [0-9A-Fa-f] [0-9A-Fa-f] [0-9A-Fa-f] ;

syntax TypeArg
	= Default: Type type 
	| Named: Type type Name name ;

syntax OctalIntegerLiteral
	= lex [0] [0-7]+ 
	# [0-9A-Z_a-z] ;

syntax Variable
	= Initialized: Name name "=" Expression initial 
	| UnInitialized: Name name ;

syntax Renaming
	= Default: Name from "=\>" Name to ;

syntax Catch
	= Default: "catch" ":" Statement body 
	| Binding: "catch" Pattern pattern ":" Statement body ;

syntax HexLongLiteral
	= lex [0] [Xx] [0-9A-Fa-f]+ [Ll] 
	# [0-9A-Z_a-z] ;

syntax PathChars
	= lex URLChars [|] ;

syntax Signature
	= NoThrows: Type type FunctionModifiers modifiers Name name Parameters parameters 
	| WithThrows: Type type FunctionModifiers modifiers Name name Parameters parameters "throws" {Type ","}+ exceptions ;

syntax Sym
	= StartOfLine: "^" 
	| IterSep: "{" Sym symbol StringConstant sep "}" "+" 
	| Column: "@" IntegerLiteral column 
	| CharacterClass: Class charClass 
	| Literal: StringConstant string 
	| EndOfLine: "$" 
	| Labeled: Sym symbol NonterminalLabel label 
	| Nonterminal: Nonterminal nonterminal 
	| Parameter: "&" Nonterminal nonterminal 
	| IterStar: Sym symbol "*" 
	| Parametrized: ParameterizedNonterminal pnonterminal "[" {Sym ","}+ parameters "]" 
	| Optional: Sym symbol "?" 
	| IterStarSep: "{" Sym symbol StringConstant sep "}" "*" 
	| CaseInsensitiveLiteral: CaseInsensitiveStringConstant cistring 
	| Iter: Sym symbol "+" ;

syntax TimePartNoTZ
	= lex [0-2] [0-9] [0-5] [0-9] [0-5] [0-9] [,.] [0-9] [0-9] 
	| lex [0-2] [0-9] ":" [0-5] [0-9] ":" [0-5] [0-9] [,.] [0-9] [0-9] [0-9] 
	| lex [0-2] [0-9] [0-5] [0-9] [0-5] [0-9] [,.] [0-9] [0-9] [0-9] 
	| lex [0-2] [0-9] [0-5] [0-9] [0-5] [0-9] 
	| lex [0-2] [0-9] [0-5] [0-9] [0-5] [0-9] [,.] [0-9] 
	| lex [0-2] [0-9] ":" [0-5] [0-9] ":" [0-5] [0-9] 
	| lex [0-2] [0-9] ":" [0-5] [0-9] ":" [0-5] [0-9] [,.] [0-9] 
	| lex [0-2] [0-9] ":" [0-5] [0-9] ":" [0-5] [0-9] [,.] [0-9] [0-9] ;

syntax DecimalLongLiteral
	= lex [1-9] [0-9]* [Ll] 
	| lex "0" [Ll] 
	# [0-9A-Z_a-z] ;

syntax CharClass
	= Complement: "~" CharClass charClass 
	> left /*memo()*/ Difference: CharClass lhs "/" CharClass rhs 
	> left /*memo()*/ Intersection: CharClass lhs "/\\" CharClass rhs 
	> left Union: CharClass lhs "\\/" CharClass rhs 
	| SimpleCharclass: "[" OptCharRanges optionalCharRanges "]" 
	| bracket /*avoid()*/ Bracket: "(" CharClass charClass ")" ;

syntax SingleQuotedStrCon
	= lex [\'] SingleQuotedStrChar* chars [\'] ;

syntax Header
	= Parameters: Tags tags "module" QualifiedName name ModuleParameters params Import* imports 
	| Default: Tags tags "module" QualifiedName name Import* imports ;

syntax Name
	= lex EscapedName 
	| lex [A-Z_a-z] [0-9A-Z_a-z]* 
	# [0-9A-Z_a-z] 
	- /*reject()*/ RascalReservedKeywords ;

syntax SyntaxDefinition
	= Layout: "layout" Sym defined "=" Prod production ";" 
	| Language: Start start "syntax" Sym defined "=" Prod production ";" ;

syntax Kind
	= View: "view" 
	| Variable: "variable" 
	| All: "all" 
	| Anno: "anno" 
	| Data: "data" 
	| Function: "function" 
	| Rule: "rule" 
	| Alias: "alias" 
	| Module: "module" 
	| Tag: "tag" ;

syntax Test
	= Labeled: Tags tags "test" Expression expression ":" StringLiteral labeled 
	| Unlabeled: Tags tags "test" Expression expression ;

syntax ImportedModule
	= Renamings: QualifiedName name Renamings renamings 
	| Default: QualifiedName name 
	| ActualsRenaming: QualifiedName name ModuleActuals actuals Renamings renamings 
	| Actuals: QualifiedName name ModuleActuals actuals ;

syntax StrCon
	= lex [\"] StrChar* chars [\"] ;

syntax Target
	= Empty: 
	| Labeled: Name name ;

syntax IntegerLiteral
	= /*prefer()*/ DecimalIntegerLiteral: DecimalIntegerLiteral decimal 
	| /*prefer()*/ HexIntegerLiteral: HexIntegerLiteral hex 
	| /*prefer()*/ OctalIntegerLiteral: OctalIntegerLiteral octal ;

syntax OptCharRanges
	= Present: CharRanges ranges 
	| Absent: ;

syntax FunctionBody
	= Default: "{" Statement* statements "}" ;

syntax Symbol
	= Literal: StrCon string 
	| IterSep: "{" Symbol symbol StrCon sep "}" "+" 
	| Sequence: "(" Symbol head Symbol+ tail ")" 
	| Optional: Symbol symbol "?" 
	| Empty: "(" ")" 
	| CaseInsensitiveLiteral: SingleQuotedStrCon singelQuotedString 
	| IterStar: Symbol symbol "*" 
	| Optional: Symbol symbol "?" 
	| Iter: Symbol symbol "+" 
	> right Alternative: Symbol lhs "|" Symbol rhs 
	| Iter: Symbol symbol "+" 
	| IterStarSep: "{" Symbol symbol StrCon sep "}" "*" 
	| CharacterClass: CharClass charClass 
	| IterStar: Symbol symbol "*" 
	| right Alternative: Symbol lhs "|" Symbol rhs ;

syntax Expression
	= Tuple: "\<" {Expression ","}+ elements "\>" 
	| bracket Bracket: "(" Expression expression ")" 
	| Closure: Type type Parameters parameters "{" Statement+ statements "}" 
	| StepRange: "[" Expression first "," Expression second ".." Expression last "]" 
	| VoidClosure: Parameters parameters "{" Statement* statements "}" 
	| Visit: Label label Visit visit 
	| Reducer: "(" Expression init "|" Expression result "|" {Expression ","}+ generators ")" 
	| NonEmptyBlock: "{" Statement+ statements "}" 
	| ReifiedType: BasicType basicType "(" {Expression ","}* arguments ")" 
	| Literal: Literal literal 
	| Comprehension: Comprehension comprehension 
	| Set: "{" {Expression ","}* elements "}" 
	| right IfThenElse: Expression condition "?" Expression thenExp ":" Expression elseExp 
	> Default: Expression from ":" Expression to 
	| non-assoc IfDefinedOtherwise: Expression lhs "?" Expression rhs 
	> non-assoc (  non-assoc Match: Pattern pattern ":=" Expression expression  
		> non-assoc NoMatch: Pattern pattern "!:=" Expression expression 
	)
	> /*prefer()*/ Enumerator: Pattern pattern "\<-" Expression expression 
	> left Equals: Expression lhs "==" Expression rhs 
	| ReifyType: "#" Type type 
	| Range: "[" Expression first ".." Expression last "]" 
	| Map: "(" {Mapping[Expression] ","}* mappings ")" 
	| Expression "+" Expression 
	| Expression "*" Expression 
	> "-" Expression 
	| List: "[" {Expression ","}* elements "]" 
	| It: "it" 
	| All: "all" "(" {Expression ","}+ generators ")" 
	| QualifiedName: QualifiedName qualifiedName 
	| Subscript: Expression expression "[" {Expression ","}+ subscripts "]" 
	> ReifyType: "#" Type type 
	| Subscript: Expression expression "[" {Expression ","}+ subscripts "]" 
	| FieldAccess: Expression expression "." Name field 
	| FieldUpdate: Expression expression "[" Name key "=" Expression replacement "]" 
	| FieldProject: Expression expression "\<" {Field ","}+ fields "\>" 
	| ReifiedType: BasicType basicType "(" {Expression ","}* arguments ")" 
	| CallOrTree: Expression expression "(" {Expression ","}* arguments ")" 
	> IsDefined: Expression argument "?" 
	> Negation: "!" Expression argument 
	| Negative: "-" Expression argument 
	> TransitiveClosure: Expression argument "+" 
	| TransitiveReflexiveClosure: Expression argument "*" 
	> GetAnnotation: Expression expression "@" Name name 
	| SetAnnotation: Expression expression "[" "@" Name name "=" Expression value "]" 
	> left Composition: Expression lhs "o" Expression rhs 
	> left (  left Product: Expression lhs "*" Expression rhs  
		> left Join: Expression lhs "join" Expression rhs 
	)
	> left (  left Division: Expression lhs "/" Expression rhs  
		> left Modulo: Expression lhs "%" Expression rhs 
	)
	> left Intersection: Expression lhs "&" Expression rhs 
	> left (  left Subtraction: Expression lhs "-" Expression rhs  
		> left Addition: Expression lhs "+" Expression rhs 
	)
	> non-assoc (  non-assoc NotIn: Expression lhs "notin" Expression rhs  
		> non-assoc In: Expression lhs "in" Expression rhs 
	)
	> non-assoc (  non-assoc GreaterThanOrEq: Expression lhs "\>=" Expression rhs  
		> non-assoc LessThanOrEq: Expression lhs "\<=" Expression rhs 
		> non-assoc LessThan: Expression lhs "\<" Expression rhs 
		> non-assoc GreaterThan: Expression lhs "\>" Expression rhs 
	)
	> left (  left Equals: Expression lhs "==" Expression rhs  
		> right IfThenElse: Expression condition "?" Expression thenExp ":" Expression elseExp 
		> left NonEquals: Expression lhs "!=" Expression rhs 
	)
	> non-assoc IfDefinedOtherwise: Expression lhs "?" Expression rhs 
	> non-assoc (  right Equivalence: Expression lhs "\<==\>" Expression rhs  
		> right Implication: Expression lhs "==\>" Expression rhs 
	)
	> left And: Expression lhs "&&" Expression rhs 
	> left Or: Expression lhs "||" Expression rhs 
	| CallOrTree: Expression expression "(" {Expression ","}* arguments ")" 
	| Any: "any" "(" {Expression ","}+ generators ")" ;

syntax UserType
	= Parametric: QualifiedName name "[" {Type ","}+ parameters "]" 
	| Name: QualifiedName name ;

syntax Import
	= Default: "import" ImportedModule module ";" 
	| Extend: "extend" ImportedModule module ";" 
	| Syntax: SyntaxDefinition syntax ;

syntax Body
	= Toplevels: Toplevel* toplevels ;

syntax URLChars
	= lex [\000-\b\013-\f\016-\037!-;=-{}-\u15151515]* ;

syntax LanguageAction
	= Action: "{" Statement* statements "}" 
	| Build: "=\>" Expression expression ;

syntax TimeZonePart
	= lex [+\-] [0-1] [0-9] [0-5] [0-9] 
	| lex "Z" 
	| lex [+\-] [0-1] [0-9] 
	| lex [+\-] [0-1] [0-9] ":" [0-5] [0-9] ;

syntax ProtocolPart
	= Interpolated: PreProtocolChars pre Expression expression ProtocolTail tail 
	| NonInterpolated: ProtocolChars protocolChars ;

syntax StringTemplate
	= IfThenElse: "if" "(" {Expression ","}+ conditions ")" "{" Statement* preStatsThen StringMiddle thenString Statement* postStatsThen "}" "else" "{" Statement* preStatsElse StringMiddle elseString Statement* postStatsElse "}" 
	| IfThen: "if" "(" {Expression ","}+ conditions ")" "{" Statement* preStats StringMiddle body Statement* postStats "}" 
	| For: "for" "(" {Expression ","}+ generators ")" "{" Statement* preStats StringMiddle body Statement* postStats "}" 
	| DoWhile: "do" "{" Statement* preStats StringMiddle body Statement* postStats "}" "while" "(" Expression condition ")" 
	| While: "while" "(" Expression condition ")" "{" Statement* preStats StringMiddle body Statement* postStats "}" ;

syntax PreStringChars
	= lex [\"] StringCharacter* [\<] ;

syntax CaseInsensitiveStringConstant
	= /*term(category("Constant"))*/ lex "\'" StringCharacter* "\'" ;

syntax Backslash
	= lex [\\] 
	# [/\<\>\\] ;

syntax Label
	= Empty: 
	| Default: Name name ":" ;

syntax ShortChar
	= lex [\\] [\032-/:-@\[-`nrt{-\u15151515] escape 
	| lex [0-9A-Za-z] character ;

syntax NumChar
	= lex [\\] [0-9]+ number ;

syntax NoElseMayFollow
	= Default: 
	# [e] [l] [s] [e] ;

syntax MidProtocolChars
	= lex "\>" URLChars "\<" ;

syntax NamedBackslash
	= lex [\\] 
	# [\<\>\\] ;

syntax JustDate
	= lex "$" DatePart ;

syntax Field
	= Name: Name fieldName 
	| Index: IntegerLiteral fieldIndex ;

syntax PostPathChars
	= lex "\>" URLChars "|" ;

syntax PathPart
	= Interpolated: PrePathChars pre Expression expression PathTail tail 
	| NonInterpolated: PathChars pathChars ;

syntax DatePart
	= lex [0-9] [0-9] [0-9] [0-9] [0-1] [0-9] [0-3] [0-9] 
	| lex [0-9] [0-9] [0-9] [0-9] "-" [0-1] [0-9] "-" [0-3] [0-9] ;

syntax FunctionModifier
	= Java: "java" ;

syntax CharRanges
	= Range: CharRange range 
	| bracket Bracket: "(" CharRanges ranges ")" 
	| right /*memo()*/ Concatenate: CharRanges lhs CharRanges rhs ;

syntax Assignment
	= Product: "*=" 
	| Division: "/=" 
	| Intersection: "&=" 
	| Subtraction: "-=" 
	| Default: "=" 
	| Addition: "+=" 
	| IfDefined: "?=" ;

syntax Assignable
	= FieldAccess: Assignable receiver "." Name field 
	| Subscript: Assignable receiver "[" Expression subscript "]" 
	| IfDefinedOrDefault: Assignable receiver "?" Expression defaultExpression 
	> non-assoc (  Tuple: "\<" {Assignable ","}+ elements "\>"  
		> non-assoc Annotation: Assignable receiver "@" Name annotation 
		> non-assoc Constructor: Name name "(" {Assignable ","}+ arguments ")" 
	)
	| Variable: QualifiedName qualifiedName ;

syntax StringConstant
	= /*term(category("Constant"))*/ lex "\"" StringCharacter* "\"" ;

syntax Assoc
	= NonAssociative: "non-assoc" 
	| Associative: "assoc" 
	| Left: "left" 
	| Right: "right" ;

syntax Replacement
	= Conditional: Expression replacementExpression "when" {Expression ","}+ conditions 
	| Unconditional: Expression replacementExpression ;

syntax TagChar
	= lex [\000-|~-\u15151515] 
	| lex [\\] [\\}] ;

syntax ParameterizedNonterminal
	= lex [A-Z] [0-9A-Z_a-z]* 
	# [\000-Z\\-\u15151515] ;

syntax DataTarget
	= Labeled: Name label ":" 
	| Empty: ;

syntax StringCharacter
	= lex [\000-!#-&(-;=?-\[\]-\u15151515] 
	| lex UnicodeEscape 
	| lex OctalEscapeSequence 
	| lex "\\" [\"\'\<\>\\bfnrt] ;

syntax JustTime
	= lex "$T" TimePartNoTZ TimeZonePart? ;

syntax StrChar
	= lex "\\\"" 
	| lex "\\t" 
	| lex newline: "\\n" 
	| lex "\\" [0-9] a [0-9] b [0-9] c 
	| lex [\032-!#-\[\]-\u15151515] 
	| lex "\\\\" ;

syntax MidStringChars
	= lex [\>] StringCharacter* [\<] ;

syntax ProtocolChars
	= lex [|] URLChars "://" ;

syntax RegExpModifier
	= lex [dims]* ;

syntax EscapedName
	= lex [\\] [A-Z_a-z] [\-0-9A-Z_a-z]* 
	# [\-0-9A-Z_a-z] ;

syntax Formal
	= TypeName: Type type Name name ;

syntax Parameters
	= VarArgs: "(" Formals formals "..." ")" 
	| Default: "(" Formals formals ")" ;

syntax Character
	= Top: "\\TOP" 
	| EOF: "\\EOF" 
	| Short: ShortChar shortChar 
	| Bottom: "\\BOT" 
	| Numeric: NumChar numChar ;

syntax RegExp
	= lex "\<" Name ":" NamedRegExp* "\>" 
	| lex "\<" Name "\>" 
	| lex [\\] [/\<\>\\] 
	| lex Backslash 
	| lex [\000-.0-;=?-\[\]-\u15151515] ;

layout LAYOUTLIST
	= LAYOUT* 
	# [/] [/] 
	# [\t-\n\r\ ] 
	# [/] [*] ;

syntax SingleQuotedStrChar
	= lex [\032-&(-\[\]-\u15151515] 
	| lex "\\t" 
	| lex "\\\'" 
	| lex "\\" [0-9] a [0-9] b [0-9] c 
	| lex "\\\\" 
	| lex "\\n" ;

syntax LocalVariableDeclaration
	= Default: Declarator declarator 
	| Dynamic: "dynamic" Declarator declarator ;

syntax RealLiteral
	= lex [0-9]+ "." [0-9]* [DFdf]? 
	| lex [0-9]+ "." [0-9]* [Ee] [+\-]? [0-9]+ [DFdf]? 
	| lex "." [0-9]+ [Ee] [+\-]? [0-9]+ [DFdf]? 
	| lex [0-9]+ [Ee] [+\-]? [0-9]+ [DFdf]? 
	| lex [0-9]+ [DFdf] 
	| lex "." [0-9]+ [DFdf]? 
	| lex [0-9]+ [Ee] [+\-]? [0-9]+ [DFdf] 
	# [0-9A-Z_a-z] ;

syntax Range
	= FromTo: Char start "-" Char end 
	| Character: Char character ;

syntax LocationLiteral
	= Default: ProtocolPart protocolPart PathPart pathPart ;

syntax ShellCommand
	= Quit: "quit" 
	| Undeclare: "undeclare" QualifiedName name 
	| Help: "help" 
	| SetOption: "set" QualifiedName name Expression expression 
	| Edit: "edit" QualifiedName name 
	| Unimport: "unimport" QualifiedName name 
	| ListDeclarations: "declarations" 
	| History: "history" 
	| Test: "test" 
	| ListModules: "modules" ;

syntax StringMiddle
	= Interpolated: MidStringChars mid Expression expression StringMiddle tail 
	| Template: MidStringChars mid StringTemplate template StringMiddle tail 
	| Mid: MidStringChars mid ;

syntax QualifiedName
	= Default: {Name "::"}+ names 
	# [:] [:] ;

syntax DecimalIntegerLiteral
	= lex "0" 
	| lex [1-9] [0-9]* 
	# [0-9A-Z_a-z] ;

syntax DataTypeSelector
	= Selector: QualifiedName sort "." Name production ;

syntax StringTail
	= MidInterpolated: MidStringChars mid Expression expression StringTail tail 
	| Post: PostStringChars post 
	| MidTemplate: MidStringChars mid StringTemplate template StringTail tail ;

syntax PatternWithAction
	= Arbitrary: Pattern pattern ":" Statement statement 
	| Replacing: Pattern pattern "=\>" Replacement replacement ;

syntax LAYOUT
	= lex Comment 
	| lex whitespace: [\t\n\r\ ] ;

syntax Visit
	= GivenStrategy: Strategy strategy "visit" "(" Expression subject ")" "{" Case+ cases "}" 
	| DefaultStrategy: "visit" "(" Expression subject ")" "{" Case+ cases "}" ;

syntax Command
	= Shell: ":" ShellCommand command 
	| /*prefer()*/ Expression: Expression expression 
	| /*prefer()*/ Expression: Expression expression 
	> NonEmptyBlock: "{" Statement+ statements "}" 
	| /*avoid()*/ Declaration: Declaration declaration 
	| Statement: Statement statement 
	| Import: Import imported ;

syntax TagString
	= lex "{" TagChar* "}" ;

syntax ProtocolTail
	= Post: PostProtocolChars post 
	| Mid: MidProtocolChars mid Expression expression ProtocolTail tail ;

syntax Nonterminal
	= lex [A-Z] [0-9A-Z_a-z]* 
	# [\[] 
	# [0-9A-Z_a-z] ;

syntax PathTail
	= Mid: MidPathChars mid Expression expression PathTail tail 
	| Post: PostPathChars post ;

syntax CommentChar
	= lex ![*]
	| lex Asterisk ;

syntax Visibility
	= Default: 
	| Private: "private" 
	| Public: "public" ;

syntax StringLiteral
	= Interpolated: PreStringChars pre Expression expression StringTail tail 
	| Template: PreStringChars pre StringTemplate template StringTail tail 
	| NonInterpolated: StringConstant constant ;

syntax Comment
	= /*term(category("Comment"))*/ lex "/*" CommentChar* "*/" 
	| /*term(category("Comment"))*/ lex "//" ![\n]* [\n] ;

syntax RegExp
	= /*term(category("MetaVariable"))*/ lex [\<]  Expression  [\>] ;

syntax Renamings
	= Default: "renaming" {Renaming ","}+ renamings ;

syntax Tags
	= Default: Tag* tags ;

syntax Formals
	= Default: {Formal ","}* formals ;

syntax PostProtocolChars
	= lex "\>" URLChars "://" ;

syntax Start
	= Absent: 
	| Present: "start" ;

syntax Statement
	= non-assoc Try: "try" Statement body Catch+ handlers 
	| Expression: Expression expression ";" 
	| Assert: "assert" Expression expression ";" 
	| TryFinally: "try" Statement body Catch+ handlers "finally" Statement finallyBody 
	| While: Label label "while" "(" {Expression ","}+ conditions ")" Statement body 
	| FunctionDeclaration: FunctionDeclaration functionDeclaration 
	| Return: "return" Statement statement 
	| Fail: "fail" Target target ";" 
	| NonEmptyBlock: Label label "{" Statement+ statements "}" 
	| Break: "break" Target target ";" 
	| Solve: "solve" "(" {QualifiedName ","}+ variables Bound bound ")" Statement body 
	| Expression: Expression expression ";" 
	> NonEmptyBlock: "{" Statement+ statements "}" 
	| Visit: Label label Visit visit 
	| Throw: "throw" Statement statement 
	| VariableDeclaration: LocalVariableDeclaration declaration ";" 
	| DoWhile: Label label "do" Statement body "while" "(" Expression condition ")" ";" 
	| IfThenElse: Label label "if" "(" {Expression ","}+ conditions ")" Statement thenStatement "else" Statement elseStatement 
	| For: Label label "for" "(" {Expression ","}+ generators ")" Statement body 
	| Switch: Label label "switch" "(" Expression expression ")" "{" Case+ cases "}" 
	| Append: "append" DataTarget dataTarget Statement statement 
	| EmptyStatement: ";" 
	| Continue: "continue" Target target ";" 
	| GlobalDirective: "global" Type type {QualifiedName ","}+ names ";" 
	| Assignment: Assignable assignable Assignment operator Statement statement 
	| IfThen: Label label "if" "(" {Expression ","}+ conditions ")" Statement thenStatement NoElseMayFollow noElseMayFollow 
	| Visit: Label label Visit visit 
	| AssertWithMessage: "assert" Expression expression ":" Expression message ";" 
	| Insert: "insert" DataTarget dataTarget Statement statement 
	| non-assoc (  non-assoc Throw: "throw" Statement statement  
		> non-assoc Insert: "insert" DataTarget dataTarget Statement statement 
		> Assignment: Assignable assignable Assignment operator Statement statement 
		> non-assoc Return: "return" Statement statement 
		> non-assoc Append: "append" DataTarget dataTarget Statement statement 
	)
	> FunctionDeclaration: FunctionDeclaration functionDeclaration 
	| VariableDeclaration: LocalVariableDeclaration declaration ";" ;

syntax StructuredType
	= Default: BasicType basicType "[" {TypeArg ","}+ arguments "]" ;

syntax NonterminalLabel
	= lex [a-z] [0-9A-Z_a-z]* 
	# [0-9A-Z_a-z] ;

syntax FunctionType
	= TypeArguments: Type type "(" {TypeArg ","}* arguments ")" ;

syntax Case
	= PatternWithAction: "case" PatternWithAction patternWithAction 
	| Default: "default" ":" Statement statement ;

syntax Declarator
	= Default: Type type {Variable ","}+ variables 
	| Default: Type type {Variable ","}+ variables 
	> Optional: Symbol symbol "?" 
	| Iter: Symbol symbol "+" 
	| IterStar: Symbol symbol "*" ;

syntax Bound
	= Empty: 
	| Default: ";" Expression expression ;

syntax RascalReservedKeywords
	= "module" 
	| "true" 
	| "bag" 
	| "num" 
	| "node" 
	| "finally" 
	| "private" 
	| "real" 
	| "list" 
	| "fail" 
	| "lex" 
	| "if" 
	| "tag" 
	| "extend" 
	| "append" 
	| "repeat" 
	| "rel" 
	| "void" 
	| "non-assoc" 
	| "assoc" 
	| "test" 
	| "anno" 
	| "layout" 
	| "LAYOUT" 
	| "data" 
	| "join" 
	| "it" 
	| "bracket" 
	| "in" 
	| "import" 
	| "view" 
	| "false" 
	| "global" 
	| "all" 
	| "dynamic" 
	| "solve" 
	| "type" 
	| "try" 
	| "catch" 
	| "notin" 
	| "reified" 
	| "else" 
	| "insert" 
	| "switch" 
	| "return" 
	| "case" 
	| "adt" 
	| "while" 
	| "str" 
	| "throws" 
	| "visit" 
	| "tuple" 
	| "for" 
	| "assert" 
	| "loc" 
	| "default" 
	| "on" 
	| "map" 
	| "alias" 
	| "lang" 
	| "int" 
	| "any" 
	| "bool" 
	| "public" 
	| "one" 
	| "throw" 
	| "set" 
	| "cf" 
	| "fun" 
	| "non-terminal" 
	| "rule" 
	| "constructor" 
	| "datetime" 
	| "value" 
	# [\-0-9A-Z_a-z] ;

syntax Type
	= Basic: BasicType basic 
	| User: UserType user 
	| Function: FunctionType function 
	| bracket Bracket: "(" Type type ")" 
	| Structured: StructuredType structured 
	| Selector: DataTypeSelector selector 
	| Variable: TypeVar typeVar 
	| Symbol: Symbol symbol 
	> Sort: QualifiedName name 
	| right Alternative: Symbol lhs "|" Symbol rhs ;

syntax Declaration
	= DataAbstract: Tags tags Visibility visibility "data" UserType user ";" 
	| Annotation: Tags tags Visibility visibility "anno" Type annoType Type onType "@" Name name ";" 
	| Test: Test test ";" 
	| View: Tags tags Visibility visibility "view" Name view "\<:" Name superType "=" {Alternative "|"}+ alts ";" 
	| Variable: Tags tags Visibility visibility Type type {Variable ","}+ variables ";" 
	| Alias: Tags tags Visibility visibility "alias" UserType user "=" Type base ";" 
	| Function: FunctionDeclaration functionDeclaration 
	| Tag: Tags tags Visibility visibility "tag" Kind kind Name name "on" {Type ","}+ types ";" 
	| Rule: Tags tags "rule" Name name PatternWithAction patternAction ";" 
	| Data: Tags tags Visibility visibility "data" UserType user "=" {Variant "|"}+ variants ";" ;

syntax Class
	= SimpleCharclass: "[" Range* ranges "]" 
	| Complement: "!" Class charClass 
	> left Difference: Class lhs "-" Class rhs 
	> left Intersection: Class lhs "&&" Class rhs 
	> left Union: Class lhs "||" Class rhs 
	| bracket Bracket: "(" Class charclass ")" ;

syntax RegExpLiteral
	= lex "/" RegExp* "/" RegExpModifier ;

syntax CharRange
	= Character: Character character 
	| Range: Character start "-" Character end ;

syntax FunctionModifiers
	= List: FunctionModifier* modifiers ;

syntax Comprehension
	= Set: "{" {Expression ","}+ results "|" {Expression ","}+ generators "}" 
	| Map: "(" Expression from ":" Expression to "|" {Expression ","}+ generators ")" 
	| List: "[" {Expression ","}+ results "|" {Expression ","}+ generators "]" ;

syntax Variant
	= NAryConstructor: Name name "(" {TypeArg ","}* arguments ")" ;

syntax FunctionDeclaration
	= Abstract: Tags tags Visibility visibility Signature signature ";" 
	| Default: Tags tags Visibility visibility Signature signature FunctionBody body ;

syntax PreProtocolChars
	= lex "|" URLChars "\<" ;

syntax NamedRegExp
	= lex [\\] [/\<\>\\] 
	| lex "\<" Name "\>" 
	| lex NamedBackslash 
	| lex [\000-.0-;=?-\[\]-\u15151515] ;

syntax ProdModifier
	= Lexical: "lex" 
	| Associativity: Assoc associativity 
	| Bracket: "bracket" ;

syntax Toplevel
	= GivenVisibility: Declaration declaration ;

syntax PostStringChars
	= lex [\>] StringCharacter* [\"] ;

syntax HexIntegerLiteral
	= lex [0] [Xx] [0-9A-Fa-f]+ 
	# [0-9A-Z_a-z] ;

syntax OctalEscapeSequence
	= lex "\\" [0-7] [0-7] 
	| lex "\\" [0-3] [0-7] [0-7] 
	| lex "\\" [0-7] 
	# [0-7] ;

syntax TypeVar
	= Bounded: "&" Name name "\<:" Type bound 
	| Free: "&" Name name ;

syntax OctalLongLiteral
	= lex [0] [0-7]+ [Ll] 
	# [0-9A-Z_a-z] ;

syntax BasicType
	= Num: "num" 
	| Loc: "loc" 
	| Node: "node" 
	| ReifiedType: "type" 
	| Bag: "bag" 
	| Int: "int" 
	| Relation: "rel" 
	| ReifiedTypeParameter: "parameter" 
	| Real: "real" 
	| ReifiedFunction: "fun" 
	| Tuple: "tuple" 
	| String: "str" 
	| Bool: "bool" 
	| ReifiedReifiedType: "reified" 
	| Void: "void" 
	| ReifiedNonTerminal: "non-terminal" 
	| Value: "value" 
	| DateTime: "datetime" 
	| Set: "set" 
	| Map: "map" 
	| ReifiedConstructor: "constructor" 
	| List: "list" 
	| ReifiedAdt: "adt" 
	| Lex: "lex" ;

syntax Char
	= /*term(category("Constant"))*/ lex [\000-\037!#-&(-,.-;=?-Z^-\u15151515] 
	| /*term(category("Constant"))*/ lex UnicodeEscape 
	| /*term(category("Constant"))*/ lex "\\" [\ \"\'\-\<\>\[-\]bfnrt] 
	| /*term(category("Constant"))*/ lex OctalEscapeSequence ;

syntax Prod
	= AssociativityGroup: Assoc associativity "(" Prod group ")" 
	| Unlabeled: ProdModifier* modifiers Sym* args 
	| non-assoc Action: Prod prod LanguageAction action 
	| Reference: ":" Name referenced 
	| Labeled: ProdModifier* modifiers Name name ":" Sym* args 
	| Others: "..." 
	> left Reject: Prod lhs "-" Prod rhs 
	> left Follow: Prod lhs "#" Prod rhs 
	> left First: Prod lhs "\>" Prod rhs 
	> left All: Prod lhs "|" Prod rhs ;

syntax DateTimeLiteral
	= /*prefer()*/ DateLiteral: JustDate date 
	| /*prefer()*/ TimeLiteral: JustTime time 
	| /*prefer()*/ DateAndTimeLiteral: DateAndTime dateAndTime ;

syntax PrePathChars
	= lex URLChars "\<" ;

syntax Mapping[&Expression]
	= Default: &Expression from ":" &Expression to ;

syntax LongLiteral
	= /*prefer()*/ DecimalLongLiteral: DecimalLongLiteral decimalLong 
	| /*prefer()*/ OctalLongLiteral: OctalLongLiteral octalLong 
	| /*prefer()*/ HexLongLiteral: HexLongLiteral hexLong ;

syntax MidPathChars
	= lex "\>" URLChars "\<" ;

syntax Pattern
	= CallOrTree: Pattern expression "(" {Pattern ","}* arguments ")" 
	> Guarded: "[" Type type "]" Pattern pattern 
	| Descendant: "/" Pattern pattern 
	| VariableBecomes: Name name ":" Pattern pattern 
	| Anti: "!" Pattern pattern 
	| TypedVariableBecomes: Type type Name name ":" Pattern pattern 
	| MultiVariable: QualifiedName qualifiedName "*" 
	| TypedVariable: Type type Name name ;

syntax Tag
	= /*term(category("Comment"))*/ Default: "@" Name name TagString contents 
	| /*term(category("Comment"))*/ Empty: "@" Name name 
	| /*term(category("Comment"))*/ Expression: "@" Name name "=" Expression expression ;

syntax ModuleActuals
	= Default: "[" {Type ","}+ types "]" ;



syntax "map"
	= ...
	# ;

syntax "loc"
	= ...
	# ;

syntax "default"
	= ...
	# ;

syntax "assert"
	= ...
	# ;

syntax "visit"
	= ...
	# ;

syntax "throws"
	= ...
	# ;

syntax "value"
	= ...
	# ;

syntax "datetime"
	= ...
	# ;

syntax "fun"
	= ...
	# ;

syntax "|"
	= ...
	# ;

syntax "non-terminal"
	= ...
	# ;

syntax "set"
	= ...
	# ;

syntax "one"
	= ...
	# ;

syntax "public"
	= ...
	# ;

syntax "o"
	= ...
	# ;

syntax "module"
	= ...
	# ;

syntax "extend"
	= ...
	# ;

syntax "append"
	= ...
	# ;

syntax "fail"
	= ...
	# ;

syntax "if"
	= ...
	# ;

syntax "node"
	= ...
	# ;

syntax "case"
	= ...
	# ;

syntax "return"
	= ...
	# ;

syntax "while"
	= ...
	# ;

syntax "str"
	= ...
	# ;

syntax "switch"
	= ...
	# ;

syntax ":"
	= ...
	# ;

syntax ":"
	= ...
	# ;

syntax "type"
	= ...
	# ;

syntax "reified"
	= ...
	# ;

syntax "notin"
	= ...
	# ;

syntax "else"
	= ...
	# ;

syntax "\>"
	= ...
	# ;

syntax "solve"
	= ...
	# ;

syntax "?"
	= ...
	# ;

syntax "dynamic"
	= ...
	# ;

syntax "\<"
	= ...
	# ;

syntax "\<"
	= ...
	# ;

syntax "="
	= ...
	# ;

syntax "="
	= ...
	# ;

syntax "false"
	= ...
	# ;

syntax "!"
	= ...
	# ;

syntax "!"
	= ...
	# ;

syntax "!"
	= ...
	# ;

syntax "on "
	= ...
	# ;

syntax "&"
	= ...
	# ;

syntax "&"
	= ...
	# ;

syntax "in"
	= ...
	# ;

syntax "*"
	= ...
	# ;

syntax "join"
	= ...
	# ;

syntax "it"
	= ...
	# ;

syntax "+"
	= ...
	# ;

syntax "."
	= ...
	# ;

syntax "/"
	= ...
	# ;

syntax ","
	= ...
	# ;

syntax "-"
	= ...
	# ;

syntax "tuple"
	= ...
	# ;

syntax "for"
	= ...
	# ;

syntax "constructor"
	= ...
	# ;

syntax "rule"
	= ...
	# ;

syntax "throw"
	= ...
	# ;

syntax "bool"
	= ...
	# ;

syntax "int"
	= ...
	# ;

syntax "any"
	= ...
	# ;

syntax "test"
	= ...
	# ;

syntax "void"
	= ...
	# ;

syntax "://"
	= ...
	# ;

syntax "tag"
	= ...
	# ;

syntax "repeat"
	= ...
	# ;

syntax "rel"
	= ...
	# ;

syntax "list"
	= ...
	# ;

syntax "real"
	= ...
	# ;

syntax "finally"
	= ...
	# ;

syntax "private"
	= ...
	# ;

syntax "\<="
	= ...
	# ;

syntax "num"
	= ...
	# ;

syntax "true"
	= ...
	# ;

syntax "adt"
	= ...
	# ;

syntax "try"
	= ...
	# ;

syntax "catch"
	= ...
	# ;

syntax "insert"
	= ...
	# ;

syntax "global"
	= ...
	# ;

syntax "=="
	= ...
	# ;

syntax "all"
	= ...
	# ;

syntax "import"
	= ...
	# ;

syntax "view"
	= ...
	# ;

syntax "data"
	= ...
	# ;

syntax "anno"
	= ...
	# ;
