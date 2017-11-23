module Tokens
  SINGLE_QUOTE = "'".freeze
  DOUBLE_QUOTE = '"'.freeze
  LT = "<".freeze
  GT = ">".freeze
  NEWLINE = "\n".freeze
  BRACKET_OPEN = "(".freeze
  BRACKET_CLOSE = ")".freeze
end
module SwiftAST
  autoload :StringScanner, 'strscan'
  class Parser 
    def parse(string)
      @scanner = StringScanner.new(string)
      node = scan_children.first
      node
    end 

    
    def parse_build_log_output(string)
      @scanner = StringScanner.new(string)
      return unless @scanner.scan_until(/^\(source_file/)
      unscan("(source_file")
      children = scan_children

      return if children.empty?
      Node.new("ast", [], children)
    end 


    private

    def scan_parameters
      parameters = []

      while true
        @scanner.skip(/\s*/)
        break unless parameter = scan_parameter?
        parameters << parameter
      end

      parameters
    end  

    def scan_children
      children = []
      while scan_opening_bracket

        children << Node.new(scan_name?, scan_parameters, scan_children)

        scan_closing_bracket
        @scanner.scan(/[\w\s]*/)

      end

      children
    end  

    def scan_opening_bracket
      @scanner.scan(/(\s|\\|\n|\r|\t)*\(/)
    end 

    def scan_closing_bracket
      @scanner.scan(/(\s|\\|\n|\r|\t)*\)/)
    end  

    def unscan(string)
      @scanner.pos = @scanner.pos - string.length
    end  

    def scan_name? 
      el_name = @scanner.scan(/#?[\w:]+/)
      el_name
    end  

    def next_parameter_if_any(is_parsing_rvalue = false)
      scan_parameter?(is_parsing_rvalue) || ""
    end  

    def scan_parameter?(is_parsing_rvalue = false)
      #white spaces are skipped

      # scan everything until space or opening sequence like ( < ' ". 
      # Since we can end up with closing bracket - we alos check for )

      prefix = @scanner.scan(/[^\s()'"\[\\]+/) if is_parsing_rvalue
      prefix = @scanner.scan(/[^\s()<'"\[\\=]+/) unless is_parsing_rvalue

      return nil unless next_char = @scanner.peek(1) 
      should_unwrap_strings = !is_parsing_rvalue && !prefix

      non_nil_prefix = prefix || ""

      case next_char
      when " "   # next parameter
        result = prefix
      when "\\"   # next parameter
        @scanner.scan(/./)
        result = prefix

      when Tokens::NEWLINE   # next parameter
        result = prefix

      when Tokens::BRACKET_CLOSE   # closing bracket == end of element
        result = prefix

      when Tokens::DOUBLE_QUOTE  # doube quoted string 
        result = scan_between(Tokens::DOUBLE_QUOTE, Tokens::DOUBLE_QUOTE, { :unwrap => should_unwrap_strings})

      when Tokens::SINGLE_QUOTE  # single quoted string 
        result = scan_between(Tokens::SINGLE_QUOTE, Tokens::SINGLE_QUOTE, { :unwrap => should_unwrap_strings})
        result += next_parameter_if_any(is_parsing_rvalue)

      when Tokens::LT  # kinda generic
        result = scan_between(Tokens::LT, Tokens::GT)

      when Tokens::BRACKET_OPEN
        #rare case for enums in type (EnumType).enumValue
        if !prefix
          enum_value = scan_enum_value?
          return enum_value unless enum_value.nil?
        end  

        #nil as parameter - it's probably start of next element
        return nil if !prefix && !is_parsing_rvalue

        result = non_nil_prefix + @scanner.scan_until(/\)/) + next_parameter_if_any(is_parsing_rvalue)
      when "["
        result = scan_range + next_parameter_if_any(is_parsing_rvalue)

        #rare case for tuple_shuffle_expr [with ([ProductDict], UserDict)]0: ([ProductDict], UserDict)
        if result.start_with?("[with") && result.end_with?("]0:")
          result +=  @scanner.scan_until(/\n/).chomp("\n")
        end  
      when "=" 
        result = prefix + @scanner.scan(/./) + next_parameter_if_any(true)

      end  

      result

    end

    def scan_between(left, right, options = {})
      s = @scanner.scan(/#{left}[^#{right}]*#{right}/)
      return s[1..-2] if options[:unwrap]
      return s
    end  

    def scan_enum_value?
      #rare case for parameters with enums in type (EnumType).enumValue
      @scanner.scan(/\([\w\s\(\)<>,:\]\[\.?]+\)\.\w+/)
    end  

    def scan_range
      return unless result = @scanner.scan(/\[/)

      while true
        inside = @scanner.scan(/[^\]\[]+/)  #everything but [ or ]
        result += inside || ""
        return result + "]" if @scanner.scan(/\]/) # we found the end
        result += scan_range  # Inner ranges are allowed as well, we'll use recursive call
      end
    end  

  end

  class Node

    def initialize(name, parameters = [], children = [])
      @name = name
      @parameters = parameters
      @children = children
    end    

    def name
      @name
    end

    def parameters
      @parameters
    end

    def children
      @children
    end    

    def dump(level = 0)
      @@line = 0 if level == 0
      puts "\n" if level == 0
      puts " " * level + "[#{@@line}][#{@name} #{@parameters}"
      @@line = @@line + 1
      @children.each { |child| child.dump(level + 1) }
    end  


  end      

end
