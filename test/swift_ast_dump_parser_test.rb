require "test_helper"

class SwiftAstParserTest < Minitest::Test
  def test_simple_objects
    node = SwiftAST::Node.new('name')
    assert !node.nil?, 'it should be able to create simple node'
    assert_equal node.name, 'name'

    assert !SwiftAST::Parser.new.nil?, 'Parser should be created!'
  end

  def test_simple_node_parse
    parser = SwiftAST::Parser.new
    ast = parser.parse('(hello )')
    assert !ast.nil?, 'Parser should return ast1'
    assert_kind_of SwiftAST::Node, ast, 'Parser should have correct root node'
  end

  def test_simple_node_parse_name
    ast = SwiftAST::Parser.new.parse('(hello )')
    assert_equal ast.name, 'hello'
  end

  def test_simple_node_parameters
    ast = SwiftAST::Parser.new.parse('(hello one)')
    assert_equal ast.name, 'hello'
    assert_equal ast.parameters, ['one']
  end

  def test_multiple_node_parameters
    ast = SwiftAST::Parser.new.parse('(hello one two)')
    assert_equal ast.name, 'hello'
    assert_equal ast.parameters, %w[one two]
  end

  def test_multiple_string_parameters
    ast = SwiftAST::Parser.new.parse("(hello 'one' \"two\")")
    assert_equal ast.name, 'hello'
    assert_equal ast.parameters, %w[one two]
  end

  def test_custom_node_with_assignment
    ast = SwiftAST::Parser.new.parse('(assignment weather=cool temperature=123)')
    assert_equal ast.name, 'assignment'
    assert_equal ast.parameters, ['weather=cool', 'temperature=123']
  end

  def test_custom_node_paramters
    ast = SwiftAST::Parser.new.parse("(hello \"Protocol1\" <Self : Protocol1> interface type='Protocol1.Protocol' access=internal @_fixed_layout requirement signature=<Self>)")
    assert_equal ast.name, 'hello'
    assert_equal ast.parameters, ['Protocol1', '<Self : Protocol1>', 'interface', "type='Protocol1.Protocol'", 'access=internal', '@_fixed_layout', 'requirement', 'signature=<Self>']
  end

  def test_node_filetype_parameter
    ast = SwiftAST::Parser.new.parse("(component id='Protocol1' bind=SourcekittenWithComplexDependencies.(file).Protocol1@/Users/paultaykalo/Projects/objc-dependency-visualizer/test/fixtures/sourcekitten-with-properties/SourcekittenExample/FirstFile.swift:12:10)")
    assert_equal ast.name, 'component'
    assert_equal ast.parameters, ["id='Protocol1'", 'bind=SourcekittenWithComplexDependencies.(file).Protocol1@/Users/paultaykalo/Projects/objc-dependency-visualizer/test/fixtures/sourcekitten-with-properties/SourcekittenExample/FirstFile.swift:12:10']
  end

  def test_node_filetype_parameter2
    ast = SwiftAST::Parser.new.parse("(component id='Protocol1' bind=SourcekittenWithComplexDependencies.(file).Protocol1.<anonymous>.@/Users/paultaykalo/Projects/A.swift:12:10)")
    assert_equal ast.name, 'component'
    assert_equal ast.parameters, ["id='Protocol1'", 'bind=SourcekittenWithComplexDependencies.(file).Protocol1.<anonymous>.@/Users/paultaykalo/Projects/A.swift:12:10']
  end

  def test_node_range_parameter
    ast = SwiftAST::Parser.new.parse("(constructor_ref_call_expr implicit type='(_MaxBuiltinIntegerType) -> Int' location=/Users/paultaykalo/Projects/objc-dependency-visualizer/test/fixtures/sourcekitten-with-properties/SourcekittenExample/FirstFile.swift:23:22 range=[/Users/paultaykalo/Projects/objc-dependency-visualizer/test/fixtures/sourcekitten-with-properties/SourcekittenExample/FirstFile.swift:23:22 - line:23:22] nothrow)")
    assert_equal ast.name, 'constructor_ref_call_expr'
    assert_equal ast.parameters, ['implicit', "type='(_MaxBuiltinIntegerType) -> Int'", 'location=/Users/paultaykalo/Projects/objc-dependency-visualizer/test/fixtures/sourcekitten-with-properties/SourcekittenExample/FirstFile.swift:23:22', 'range=[/Users/paultaykalo/Projects/objc-dependency-visualizer/test/fixtures/sourcekitten-with-properties/SourcekittenExample/FirstFile.swift:23:22 - line:23:22]', 'nothrow']
  end

  def test_node_range_recursive_parameter
    ast = SwiftAST::Parser.new.parse('(with_recursive [with E[abstract:ProtocolForGeneric]])')
    assert_equal ast.name, 'with_recursive'
    assert_equal ast.parameters, ['[with E[abstract:ProtocolForGeneric]]']
  end

  def test_node_builtin_literal
    ast = SwiftAST::Parser.new.parse('(constructor_ref_call_expr arg_labels=_builtinBooleanLiteral:)')
    assert_equal ast.name, 'constructor_ref_call_expr'
    assert_equal ast.parameters, ['arg_labels=_builtinBooleanLiteral:']
  end

  def test_comma_parsing
    ast = SwiftAST::Parser.new.parse('(constructor_ref_call_expr inherits: UIResponder, UIApplicationDelegate)')
    assert_equal ast.name, 'constructor_ref_call_expr'
    assert_equal ast.parameters, ['inherits:', 'UIResponder,', 'UIApplicationDelegate']
  end

  def test_nilliteral_parameter_parsing
    ast = SwiftAST::Parser.new.parse("(declref_expr implicit type='(Optional<UIWindow>.Type) -> (()) -> Optional<UIWindow>' decl=Swift.(file).Optional.init(nilLiteral:) [with UIWindow] function_ref=single)
")
    assert_equal ast.name, 'declref_expr'
    assert_equal ast.parameters, ['implicit', "type='(Optional<UIWindow>.Type) -> (()) -> Optional<UIWindow>'", 'decl=Swift.(file).Optional.init(nilLiteral:)', '[with UIWindow]', 'function_ref=single']
  end

  def test_children_parsing
    source = ''"
    (brace_stmt\
        (return_stmt implicit))
    "''
    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, 'brace_stmt'
    assert_equal ast.parameters, []
    assert !ast.children.empty?, 'Parser should be able to parse subtrees'

    return_statement = ast.children.first
    assert_equal return_statement.name, 'return_stmt'
    assert_equal return_statement.parameters, ['implicit']
  end

  def test_multiple_children_parsing
    source = %{
    (func_decl implicit 'anonname=0x7f85f59df460' interface type='(AppDelegate) -> (Builtin.RawPointer, inout Builtin.UnsafeValueBuffer) -> (Builtin.RawPointer, Builtin.RawPointer?)' access=internal materializeForSet_for=window\
    (parameter_list\
    (parameter "self" type='AppDelegate' interface type='AppDelegate'))\
    (parameter_list\
    (parameter "buffer" type='Builtin.RawPointer' interface type='Builtin.RawPointer')\
    (parameter "callbackStorage" type='inout Builtin.UnsafeValueBuffer' interface type='inout Builtin.UnsafeValueBuffer' mutable)))\
    }

    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, 'func_decl'
    assert_equal ast.children.count, 2
  end

  def test_complex_file_parsing
    source = IO.read('./test/fixtures/swift-dump-ast/appdelegate.ast')
    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, 'source_file'
  end

  def test_even_more_complex_file_parsing
    source = IO.read('./test/fixtures/swift-dump-ast/first-file.ast')
    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, 'source_file'
  end

  def test_some_unusual_params
    source = %{
    (string_expr
        builtin_initializer=Swift.(file).String.init(_builtinStringLiteral:utf8CodeUnitCount:isASCII:)
        initializer=**NULL**
        names='',animated
        req===(_:_:)
        decl=CoreGraphics.(file).CGFloat.+
        discriminator=0.$0@/path/TheView.swift:115:39
        decl=Swift.(file).??
        [with String]
        decl=Swift.(file).+=
        decl=Swift.(file)...<
        decl=Swift.(file).<
        captures=(self)
      (parameter_list)\
    )
    }

    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, 'string_expr'
    assert_equal ast.parameters, [
      'builtin_initializer=Swift.(file).String.init(_builtinStringLiteral:utf8CodeUnitCount:isASCII:)',
      'initializer=**NULL**',
      "names='',animated",
      'req===(_:_:)',
      'decl=CoreGraphics.(file).CGFloat.+',
      'discriminator=0.$0@/path/TheView.swift:115:39',
      'decl=Swift.(file).??',
      '[with String]',
      'decl=Swift.(file).+=',
      'decl=Swift.(file)...<',
      'decl=Swift.(file).<',
      'captures=(self)'
    ]
    assert_equal ast.children.count, 1
  end

  def test_unusual_function_params
    source = %{
(string_expr
    builtin_initializer=String
    [with String[String: StringProtocol module Swift], String[String: StringProtocol module Swift], String[String: StringProtocol module Swift]]0: String
    (parameter_list)1: String
    (parameter_list)
)
}

    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, 'string_expr'
    assert_equal ast.children.length, 1
    assert_equal ast.parameters, [
      'builtin_initializer=String',
      '[with String[String: StringProtocol module Swift], String[String: StringProtocol module Swift], String[String: StringProtocol module Swift]]0: String'
    ]
  end

  def test_raw_log_parsing
    source = IO.read('./test/fixtures/swift-dump-ast/cell-file.ast')
    ast = SwiftAST::Parser.new.parse_build_log_output(source)
    assert_equal ast.name, 'ast'
    assert_equal ast.children.count, 2
  end

  def test_enum_case_usage
    source = %{
      (pattern_enum_element type='(CameraAuthorizationStatus)' (CameraAuthorizationStatus).authorized)
    }
    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, 'pattern_enum_element'
    assert_equal ast.parameters, [
      "type='(CameraAuthorizationStatus)'",
      "(CameraAuthorizationStatus).authorized"
    ]    
  end

  def test_complex_pattern_enum_element
    source = %{
      (pattern_enum_element type='(Result<(ProductDict, UserDict), NSError>)' (Result<(ProductDict, UserDict), NSError>).success
    }
    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, 'pattern_enum_element'
    assert_equal ast.parameters, [
      "type='(Result<(ProductDict, UserDict), NSError>)'",
      "(Result<(ProductDict, UserDict), NSError>).success"
    ]    
  end

  def test_even_complex_pattern_enum_element
    source = %{
      (pattern_enum_element type='(Result<([[String : Any]], [[String : Any]], [[String : Any]]), SyncCheckoutDataOperation.SyncCheckoutDataOperationError>)' (Result<([[String : Any]], [[String : Any]], [[String : Any]]), SyncCheckoutDataOperation.SyncCheckoutDataOperationError>).success
    }
    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, 'pattern_enum_element'
    assert_equal ast.parameters, [
      "type='(Result<([[String : Any]], [[String : Any]], [[String : Any]]), SyncCheckoutDataOperation.SyncCheckoutDataOperationError>)'",
      "(Result<([[String : Any]], [[String : Any]], [[String : Any]]), SyncCheckoutDataOperation.SyncCheckoutDataOperationError>).success"
    ]        
  end

  def test_another_pattern_enum_element
        source = %{
    (pattern_enum_element type='(OperationState<UIImage?, NSError>)' (OperationState<UIImage?, NSError>).pending))
    }
    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, 'pattern_enum_element'
    assert_equal ast.parameters, [
      "type='(OperationState<UIImage?, NSError>)'",
      "(OperationState<UIImage?, NSError>).pending"
    ]        
  end

  def test_tuple_shuffle_usage
    source = %{
         (tuple_shuffle_expr implicit [with ([ProductDict], UserDict)]0: ([ProductDict], UserDict)

                                  (tuple_expr type='()' range=[er.swift:34:34 - line:34:35]))
              
    }
    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, 'tuple_shuffle_expr'
    assert_equal ast.parameters, [
      "implicit",
      "[with ([ProductDict], UserDict)]0: ([ProductDict], UserDict)"
    ]    

  end  

  def test_unexpected_words_between_items
    source = %{
      (item param
         (child one) Unexpected word
         (child two) Unexpected word
      )              
    }
    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, 'item'
    assert_equal ast.children.length, 2
    assert_equal ast.parameters, [
      "param"
    ]    

    
  end

  def test_hashtags_in_elements_names
    source = %{
      (#if_decl
        (#if: active)
        )
    }

    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, '#if_decl'
    assert_equal ast.children.count, 1
    assert_equal ast.children.first.name, '#if:'
  end

  def test_if_config_elements
    source = %{
 (class_decl "ROLogger" interface type='ROLogger.Type' access=internal @_fixed_layout inherits: Loggable
   (#if_decl
(#if: active
       (sequence_expr type='<null>'
         (unresolved_decl_ref_expr type='<null>' name=DEBUG function_ref=unapplied)
         (unresolved_decl_ref_expr type='<null>' name=|| function_ref=unapplied)
         (unresolved_decl_ref_expr type='<null>' name=BETA function_ref=unapplied))
       (struct_decl "LeLogger" interface type='ROLogger.LeLogger.Type' access=fileprivate @_fixed_layout)

   }

    ast = SwiftAST::Parser.new.parse(source)
    assert_equal ast.name, 'class_decl'
    assert_equal ast.children.count, 1
    assert_equal ast.parameters, ['ROLogger', 'interface', "type='ROLogger.Type'", 'access=internal', '@_fixed_layout', 'inherits:', 'Loggable']
    assert_equal ast.children.first.name, '#if_decl'
    assert_equal ast.children.first.children.first.name, '#if:'
  end
end
