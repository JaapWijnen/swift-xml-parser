import Collections

public struct XML {
    public typealias Prolog = OrderedDictionary<String, String>
    
    var prolog: Prolog
    var root: Element
    
    public init(prolog: Prolog, root: Element) {
        self.prolog = prolog
        self.root = root
    }
    
    public struct Element {
        let name: String
        let attributes: OrderedDictionary<String, String>
        let content: [Node]
        
        public init(name: String, attributes: OrderedDictionary<String, String> = [:], content: [Node] = []) {
            self.name = name
            self.attributes = attributes
            self.content = content
        }
    }
    
    public enum Node {
        case element(Element)
        //indirect case element(String, Attributes, [Node])
        case text(String)
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
