import Collections

public enum XML {
    public typealias Parameters = OrderedDictionary<String, String>
    
    case doctype(Parameters)
    indirect case element(String, Parameters, [XML])
    case text(String)
    case comment(String)
}

extension XML: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .doctype(parameters):
            return ".doctype(\(parameters))"
        case let .element(type, parameters, content):
            return ".element(\(type), \(parameters), [\(content)])"
        case let .text(string):
            return string
        case let .comment(comment):
            return "<!--\(comment)-->"
        }
    }
}

extension XML: Equatable {
    public static func == (lhs: XML, rhs: XML) -> Bool {
        switch (lhs, rhs) {
        case
            let (.doctype(lhsAttributes), .doctype(rhsAttributes)):
            return lhsAttributes == rhsAttributes
        case
            let (.comment(lhs), .comment(rhs)),
            let (.text(lhs), .text(rhs)):
            return lhs == rhs
        case let (
            .element(lhsTag, lhsParameters, lhsChildren),
            .element(rhsTag, rhsParameters, rhsChildren)):
            return lhsTag == rhsTag
                && lhsParameters == rhsParameters
                && lhsChildren == rhsChildren
        default:
            return false
        }
    }
}
