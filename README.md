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

// xml parser takes a single `Bool` parameter which determines the printing mode (with or without newlines/indentation)
let xml = try xmlParser(true).parse(input)
//XML(
//  prolog: [
//    "version": "1.0", 
//    "encoding": "utf-8"
//  ], 
//  root: .element("root", [:], [
//    .element("content", ["attribute1": "value"], [])
//  ])
//]

let indentedPrintedXML = xmlParser(true).print(xml)
//<?xml version=\"1.0\" encoding=\"utf-8\"?>
//<root>
//  <content attribute1="value"/>
//</root>

let flatPrintedXML = xmlParser(false).print(xml)
//<?xml version=\"1.0\" encoding=\"utf-8\"?><root><content attribute1="value"/></root>
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-parsing]: https://github.com/pointfreeco/swift-parsing
[pointfree]: https://pointfree.co
