import Collections

/// Structured data type representing xml
public struct XML {
    public typealias Prolog = OrderedDictionary<String, String>
    
    /// The attributes from the prolog of the xml data
    public var prolog: Prolog
    
    /// The root element of the xml data
    public var root: Element
    
    /// Creates an XML document
    /// - Parameters:
    ///   - prolog: the attributes contained in the prolog of the xml file
    ///   - root: the root element of the xml file
    public init(prolog: Prolog, root: Element) {
        self.prolog = prolog
        self.root = root
    }
    
    /// Type representing a single XML tag and it's contents
    public struct Element {
        /// the tag name
        public let name: String
        
        /// the attributes contained in the opening tag
        public let attributes: OrderedDictionary<String, String>
        
        /// the contents of the tag
        public let content: [Node]
        
        /// creates a ``XML.Element``
        /// - Parameters:
        ///   - name: the name of the xml tag
        ///   - attributes: the attributes of the xml tag
        ///   - content: the content of the xml tag
        public init(name: String, attributes: OrderedDictionary<String, String> = [:], content: [Node] = []) {
            self.name = name
            self.attributes = attributes
            self.content = content
        }
    }
    
    /// Type representing different kinds of XML tag content
    public enum Node {
        /// XML tags either with or without content
        case element(Element)
        /// plain text
        case text(String)
        /// XML comment
        case comment(String)
    }
}

extension XML: CustomStringConvertible {
    public var description: String {
        "prolog: \(prolog), root: \(root)"
    }
}

extension XML: Equatable { }

extension XML.Element: CustomStringConvertible {
    public var description: String {
        "\(Self.self)(name: \(name), attributes: \(attributes), content: \(content))"
    }
}

extension XML.Element: Equatable { }

extension XML.Node: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .element(element):
            return element.description
        case let .text(string):
            return string
        case let .comment(comment):
            return "<!--\(comment)-->"
        }
    }
}

extension XML.Node: Equatable {
    public static func == (lhs: XML.Node, rhs: XML.Node) -> Bool {
        switch (lhs, rhs) {
        case let (.element(lhs), .element(rhs)):
            return lhs == rhs
        case
            let (.comment(lhs), .comment(rhs)),
            let (.text(lhs), .text(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}
