import Foundation

/// A node in the block-style YAML subset that FluidNC configuration files use.
///
/// Only nested mappings and scalar values are represented. Sequences and flow collections are not
/// part of FluidNC's configuration syntax; a flow value such as `{a: 1}` is kept as a raw scalar.
final class YAMLNode {
    var scalar: String?
    private(set) var children: [String: YAMLNode] = [:]

    init(scalar: String? = nil) { self.scalar = scalar }

    /// Case-insensitive child lookup, as FluidNC matches keys.
    subscript(key: String) -> YAMLNode? { children[key.lowercased()] }

    var keys: [String] { Array(children.keys) }

    func add(_ key: String, _ node: YAMLNode) { children[key.lowercased()] = node }

    func has(_ key: String) -> Bool { children[key.lowercased()] != nil }
}

/// An error found while reading a configuration file.
public struct FluidNCConfigError: Error, Equatable, CustomStringConvertible {
    /// 1-based line number the problem was found on.
    public let line: Int
    /// What is wrong.
    public let message: String

    public var description: String { "line \(line): \(message)" }
}

enum YAMLSubset {
    /// Parse `text` into a tree of mappings and scalars.
    static func parse(_ text: String) throws -> YAMLNode {
        let root = YAMLNode()
        // The top of the stack is the mapping new keys attach to. `childIndent` is the indentation
        // its first key established; every later key of that mapping must match it.
        struct Frame {
            let indent: Int
            let node: YAMLNode
            var childIndent: Int?
        }
        var stack = [Frame(indent: -1, node: root, childIndent: nil)]
        // Lines deeper than this belong to an ignored sequence item.
        var skipAbove: Int?

        let lines = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")

        for (index, raw) in lines.enumerated() {
            let number = index + 1
            let body = stripComment(raw)
            if body.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            if body == "---" || body == "..." { continue }

            let indentText = body.prefix { $0 == " " || $0 == "\t" }
            if indentText.contains("\t") {
                throw FluidNCConfigError(line: number, message: "tab in indentation")
            }
            let indent = indentText.count
            let content = String(body.dropFirst(indent)).trimmingCharacters(in: .whitespaces)

            if let limit = skipAbove {
                if indent > limit { continue }
                skipAbove = nil
            }
            if content == "-" || content.hasPrefix("- ") {
                skipAbove = indent
                continue
            }

            while stack.count > 1, stack[stack.count - 1].indent >= indent {
                stack.removeLast()
            }
            let top = stack.count - 1
            if let established = stack[top].childIndent, established != indent {
                throw FluidNCConfigError(line: number, message: "inconsistent indentation")
            }
            if stack[top].childIndent == nil {
                guard indent > stack[top].indent else {
                    throw FluidNCConfigError(line: number, message: "inconsistent indentation")
                }
                stack[top].childIndent = indent
            }
            let parent = stack[top].node

            guard let (key, value) = splitKeyValue(content) else {
                throw FluidNCConfigError(line: number, message: "expected `key: value`")
            }
            if parent.has(key) {
                throw FluidNCConfigError(line: number, message: "duplicate key `\(key)`")
            }
            let node = YAMLNode(scalar: value.isEmpty ? nil : unquote(value))
            parent.add(key, node)
            if value.isEmpty { stack.append(Frame(indent: indent, node: node, childIndent: nil)) }
        }
        return root
    }

    /// Remove a trailing `# comment`, ignoring `#` inside quotes or glued to a word.
    static func stripComment(_ line: String) -> String {
        var quote: Character?
        var previous: Character = " "
        var result = ""
        for character in line {
            if let open = quote {
                if character == open { quote = nil }
            } else if character == "\"" || character == "'" {
                quote = character
            } else if character == "#" && (previous == " " || previous == "\t" || result.isEmpty) {
                break
            }
            result.append(character)
            previous = character
        }
        while result.last == " " || result.last == "\t" { result.removeLast() }
        return result
    }

    /// Split at the first `:` that ends the line or is followed by a space.
    ///
    /// A colon inside a value such as `gpio.34:low` is not a separator.
    static func splitKeyValue(_ content: String) -> (String, String)? {
        let characters = Array(content)
        for index in characters.indices where characters[index] == ":" {
            let isLast = index == characters.count - 1
            if isLast || characters[index + 1] == " " {
                let key = String(characters[..<index]).trimmingCharacters(in: .whitespaces)
                let value = String(characters[(index + 1)...]).trimmingCharacters(in: .whitespaces)
                return key.isEmpty ? nil : (key, value)
            }
        }
        return nil
    }

    static func unquote(_ value: String) -> String {
        guard value.count >= 2, let first = value.first, first == value.last,
            first == "\"" || first == "'"
        else { return value }
        return String(value.dropFirst().dropLast())
    }
}
