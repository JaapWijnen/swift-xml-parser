# swift-xml-parser

A XML parser using the excellent [swift-parsing][swift-parsing] package by [pointfree.co][pointfree]

## Getting Started

```swift
var input = """
<?xml version=\"1.0\" encoding=\"utf-8\"?>
<root>
  <content attribute1="value" />
</root>
"""

let xml = try xmlParser.parse(input)
//[
//  .doctype([
//    "version": "1.0", 
//    "encoding": "utf-8"
//  ]), 
//  .element("root", [:], [
//    .element("content", ["attribute1": "value"], [])
//  ])
//]
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-parsing]: https://github.com/pointfreeco/swift-parsing
[pointfree]: https://pointfree.co
