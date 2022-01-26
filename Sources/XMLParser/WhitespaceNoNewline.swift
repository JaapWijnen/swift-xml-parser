import Parsing

/// A parser that consumes all ASCII whitespace from the beginning of the input.
internal struct WhitespaceNoNewline<Input>: Parser
where
  Input: Collection,
  Input.SubSequence == Input,
  Input.Element == UTF8.CodeUnit
{
  @inlinable
  public init() {}

  @inlinable
  public func parse(_ input: inout Input) -> Input? {
    let output = input.prefix(while: { (byte: UTF8.CodeUnit) in
      byte == .init(ascii: " ")
        || byte == .init(ascii: "\r")
        || byte == .init(ascii: "\t")
    })
    input.removeFirst(output.count)
    return output
  }
}

extension Parsers {
    internal typealias WhitespaceNoNewline = XMLParser.WhitespaceNoNewline  // NB: Convenience type alias for discovery
}

