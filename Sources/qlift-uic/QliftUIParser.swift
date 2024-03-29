import Foundation
import OrderedCollections
#if canImport(FoundationXML)
import FoundationXML
#endif

fileprivate class Node {
    unowned var parent: Node?
    var text: String
    var children = [Node]()
    var value: String = ""
    var attributes = [String: String]()
    init(parent: Node?, text: String) {
        self.parent = parent
        self.text = text
    }
}

extension Node: CustomStringConvertible {
    var description: String {
        return text + ": " + (value.isEmpty ? children.description : value)
    }
}


public class QliftUIParser: NSObject {
    private let rootNode = Node(parent: nil, text: "root")
    private var currentNode: Node?
    private var namesOfQMenusForAddAction = [String]()
    private var widgetCount = 1
    private var tabTitle = ""
    private var localizable = false
    private var lstrings: OrderedDictionary<String, (value: String, comment: String)> = [:]
    private var fileName: String = ""
    
    public func parseUI(data: Data, fileName: String, localizable: Bool) -> (String?, OrderedDictionary<String, (value: String, comment: String)>) {
        self.localizable = localizable
        self.fileName = fileName
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        guard parser.parse() else { return (nil, [:]) }
        let swiftCode = node2Swift(node: rootNode)
        return (swiftCode, lstrings)
    }
    
    private func node2Swift(node: Node) -> String {
        var swiftUI = "import Qlift\n"
        if localizable {
            swiftUI += "import class Foundation.Bundle\nimport func Foundation.NSLocalizedString\n"
        }
        swiftUI += "\n\n"
        
        let ui = node.children[0].children
        let rootWidgetNode: Node = ui.first(where: { $0.text == "widget"})!
        
        let baseClass = rootWidgetNode.attributes["class"]!
        let className = rootWidgetNode.attributes["name"]!
        swiftUI += "class " + className + ": " + baseClass + " {\n"
        rootWidgetNode.attributes["name"] = "self"
        let properties = getInstancePropertyNodes(root: rootWidgetNode)
        for property in properties {
            var className = ""
            if property.attributes["class"] != nil {
                className = property.attributes["class"]!
            }
            else if property.text == "spacer" {
                className = "QSpacerItem"
            }
            else if property.text == "action" {
                className = "QAction"
            }
            if property.attributes["name"]!.isEmpty {
                property.attributes["name"] = "widget\(widgetCount)"
                widgetCount += 1
            }
            if property.attributes["name"]! == "layoutWidget" {
                property.attributes["name"] = "layoutWidget\(widgetCount)"
                widgetCount += 1
            }
            if className == "Line" {
                continue
            }
            if className == "QStatusBar" {
                continue
            }
            
            swiftUI += "    var " + property.attributes["name"]! + ": " + className + "!\n"
        }
        
        if let buttonGroupsNode = ui.first(where: { $0.text == "buttongroups" }) {
            for group in buttonGroupsNode.children {
                let name = group.attributes["name"]!
                swiftUI += "    var \(name): QButtonGroup!\n"
            }
        }
        
        if let slotsNode = ui.first(where: { $0.text == "slots" }) {
            swiftUI += "\n"
            for slot in slotsNode.children {
                var signature = slot.value
                if signature.hasSuffix("(bool)") {
                    signature = signature.prefix { $0 != "(" }.appending("(_ state: Bool)")
                }
                swiftUI += "    open func \(signature) {}\n"
            }
        }
        
        swiftUI += """
        
            override init(parent: QWidget? = nil, flags: Qt.WindowFlags = .Widget) {
                super.init(parent: parent, flags: flags)
        
        """
        
        if let buttonGroupsNode = ui.first(where: { $0.text == "buttongroups" }) {
            for group in buttonGroupsNode.children {
                let name = group.attributes["name"]!
                swiftUI += "        \(name) = QButtonGroup(parent: self)\n"
            }
        }
        
        // 1. Actions
        for node in rootWidgetNode.children.filter({ $0.text == "action" }) {
            swiftUI += subNode2Swift(node: node)
        }
        
        // 2. Everything except actions
        for node in rootWidgetNode.children.filter({ $0.text != "action" }) {
            swiftUI += subNode2Swift(node: node)
        }
        
        if let contentsMargins = preextractContentsMargins(node: rootWidgetNode) {
            swiftUI += contentsMargins
        }
        
        // 3. Connections
        let connectionsNodes = ui.filter({ $0.text == "connections" })
        if !connectionsNodes.isEmpty {
            for connection in connectionsNodes[0].children {
                let sender = connection.children[0].value
                let signalWithBraces = connection.children[1].value.capitalized
                let signal = signalWithBraces.prefix { $0 != "(" }
                let receiver = connection.children[2].value
                let receiverObject = receiver == className ? "self" : receiver
                let slotWithBraces = connection.children[3].value
                let slot = slotWithBraces.prefix { $0 != "(" }
                swiftUI += "        \(sender).connect\(signal)(target: \(receiverObject), to: \(receiver).\(slot))\n"
            }
        }
        
        swiftUI += "    }\n"
        swiftUI += "}\n"
        return swiftUI
    }
    
    private func preextractContentsMargins(node: Node) -> String? {
        var left = -1
        var top = -1
        var right = -1
        var bottom = -1
        var foundOneMargin = false
        
        for subNode in node.children where subNode.text == "property" {
            switch subNode.attributes["name"]! {
            case "leftMargin":
                left = Int(subNode.children[0].value)!
                foundOneMargin = true
            case "topMargin":
                top = Int(subNode.children[0].value)!
                foundOneMargin = true
            case "rightMargin":
                right = Int(subNode.children[0].value)!
                foundOneMargin = true
            case "bottomMargin":
                bottom = Int(subNode.children[0].value)!
                foundOneMargin = true
            default:
                continue
            }
        }
        
        guard foundOneMargin else {
            return nil
        }
        
        return "        \(node.attributes["name"]!).contentsMargins = QMargins(left: \(left), top: \(top), right: \(right), bottom: \(bottom))\n"
    }
    
    private func subNode2Swift(node: Node) -> String {
        var ui = ""
        
        switch node.text {
        case "property":
            switch node.attributes["name"]! {
            case "palette", "icon":
                // TODO: Pallette make
                break
            case "sizePolicy":
                let hSizeType = node.children[0].attributes["hsizetype"]!
                let vSizeType = node.children[0].attributes["vsizetype"]!
                ui += "        \(node.parent!.attributes["name"]!).sizePolicy = QSizePolicy(horizontal: .\(hSizeType), vertical: .\(vSizeType))\n"
            case "leftMargin", "topMargin", "rightMargin", "bottomMargin":
                break
            case "pixmap":
                ui += "        \(node.parent!.attributes["name"]!).setPixmap(QPixmap(fileName: \(propertyNode2Swift(node: node.children[0], for: node.parent!.attributes["name"]!))))\n"
            case "iconSize":
                ui += "        \(node.parent!.attributes["name"]!).setIconSize(\(propertyNode2Swift(node: node.children[0], for: node.parent!.attributes["name"]!)))\n"
            case "autoFillBackground":
                ui += "        \(node.parent!.attributes["name"]!).autoFillBackground = \(propertyNode2Swift(node: node.children[0], for: node.parent!.attributes["name"]!))\n"
            case "flat":
                ui += "        \(node.parent!.attributes["name"]!).isFlat = \(propertyNode2Swift(node: node.children[0], for: node.parent!.attributes["name"]!))\n"
            default:
                if node.parent!.text == "item" {
                    ui += "        \(node.parent!.parent!.attributes["name"]!).add(item: \(propertyNode2Swift(node: node.children[0], for: node.parent!.parent!.attributes["name"]!)))\n"
                } else {
                    ui += "        \(node.parent!.attributes["name"]!).\(node.attributes["name"]!) = \(propertyNode2Swift(node: node.children[0], for: node.parent!.attributes["name"]!))\n"
                }
            }
        case "addaction":
            var actionName = node.attributes["name"]!
            if actionName == "separator" {
                ui += "        \(node.parent!.attributes["name"]!).addSeparator()\n"
            } else if namesOfQMenusForAddAction.contains(actionName) {
                actionName = actionName + ".menuAction()"
                ui += "        \(node.parent!.attributes["name"]!).add(action: \(actionName))\n"
            } else {
                ui += "        \(node.parent!.attributes["name"]!).add(action: \(actionName))\n"
            }
        case "action":
            ui += "        \(node.attributes["name"]!) = QAction(parent: \(node.parent!.attributes["name"]!))\n"
            for subNode in node.children {
                ui += subNode2Swift(node: subNode)
            }
        case "widget":
            // 1. Determine if constructor should be passed a parent variable.
            guard node.attributes["class"]! != "Line" else { break }
            let parentName = getParentWidget(node: node)?.attributes["name"] ?? "nil"
            // 2. Construct widget itself.
            if node.parent?.attributes["class"] == "QScrollArea" {
                ui += "        \(node.attributes["name"]!) = \(node.attributes["class"]!)()\n"
            } else if node.parent?.attributes["class"] == "QTabWidget" {
                ui += "        \(node.attributes["name"]!) = \(node.attributes["class"]!)()\n"
            } else if node.attributes["class"]! == "QStatusBar" {
                ui += "        let \(node.attributes["name"]!) = \(node.attributes["class"]!)(parent: \(parentName))\n"
            } else {
                ui += "        \(node.attributes["name"]!) = \(node.attributes["class"]!)(parent: \(parentName))\n"
            }
            ui += "        \(node.attributes["name"]!).objectName = \"\(node.attributes["name"]!)\"\n"
            
            // 3. Handle special cases: QMenuBar, QMenu, QToolBar, QStatusBar, QDockWidget
            switch node.attributes["class"]! {
                
            case "":
                for subNode in node.children where subNode.attributes["name"] != "currentIndex" {
                    ui += subNode2Swift(node: subNode)
                }
                for subNode in node.children where subNode.attributes["name"] == "currentIndex" {
                    ui += subNode2Swift(node: subNode)
                }
                
            case "QMenuBar":
                for subNode in node.children {
                    ui += subNode2Swift(node: subNode)
                }
                ui += "        \(node.parent!.attributes["name"]!).menuBar = \(node.attributes["name"]!)\n"
                
            case "QStatusBar":
                for subNode in node.children {
                    ui += subNode2Swift(node: subNode)
                }
                ui += "        \(node.parent!.attributes["name"]!).statusBar = \(node.attributes["name"]!)\n"
                
            case "QMenu":
                namesOfQMenusForAddAction.append(node.attributes["name"]!)
                for subNode in node.children {
                    ui += subNode2Swift(node: subNode)
                }
                
            case "QToolBar":
                var area = ""
                for subNode in node.children.filter({ $0.text == "attribute" }) {
                    if subNode.attributes["name"]! == "toolBarArea" {
                        let val = subNode.children[0].value
                        area = "." + String(val[..<val.index(val.endIndex, offsetBy: -"ToolBarArea".count)])
                    }
                }
                for subNode in node.children.filter({ $0.text != "attribute" }) {
                    ui += subNode2Swift(node: subNode)
                }
                ui += "        \(node.parent!.attributes["name"]!).add(toolBar: \(node.attributes["name"]!), area: \(area))\n"
                
            case "QDockWidget":
                var areaNumberString = ""
                for subNode in node.children.filter({ $0.text == "attribute" }) {
                    if subNode.attributes["name"]! == "dockWidgetArea" {
                        areaNumberString = subNode.children[0].value
                    }
                }
                for subNode in node.children.filter({ $0.text != "attribute" }) {
                    ui += subNode2Swift(node: subNode)
                }
                let area: String
                switch Int(areaNumberString) {
                case 0?: area = ".No"
                case 1?: area = ".Left"
                case 2?: area = ".Right"
                case 4?: area = ".Top"
                case 8?: area = ".Botom"
                case 15?: area = ".All"
                default:
                    area = ""
                    print("Unknown dock area", to: &stderror)
                }
                ui += "        \(node.parent!.attributes["name"]!).add(dockWidget: \(node.attributes["name"]!), area: \(area))\n"
                
                // 4. Handle generic QWidget
            default:
                // Recurse children
                for subNode in node.children {
                    ui += subNode2Swift(node: subNode)
                }
                
                // Determine if parent is item (in layout) -> needs to add the widget to the layout via add(item:)
                if node.parent!.text == "item" {
                    ui += "        \(node.parent!.parent!.attributes["name"]!).add(widget: \(node.attributes["name"]!)" + itemNodeTail(node: node.parent!) + "\n"
                }
                
                // Determine if parent is a QDockWidget or QMainWindow -> needs to set widget / centralWidget
                else {
                    switch node.parent!.attributes["class"] {
                    case "QDockWidget"?:
                        ui += "        \(node.parent!.attributes["name"]!).widget = \(node.attributes["name"]!)\n"
                    case "QMainWindow"?:
                        ui += "        \(node.parent!.attributes["name"]!).centralWidget = \(node.attributes["name"]!)\n"
                    case "QScrollArea"?:
                        ui += "        \(node.parent!.attributes["name"]!).setWidget(\(node.attributes["name"]!))\n"
                    case "QTabWidget"?:
                        ui += "        \(node.parent!.attributes["name"]!).addTab(\(node.attributes["name"]!), label: \(tabTitle))\n"
                    default:
                        break
                    }
                }
            }
        case "layout":
            let parent = node.parent!.text == "widget" ? node.parent!.attributes["name"]! : "nil"
            ui += "        \(node.attributes["name"]!) = \(node.attributes["class"]!)(parent: \(parent))\n"
            ui += "        \(node.attributes["name"]!).objectName = \"\(node.attributes["name"]!)\"\n"
            if let contentMargins =  preextractContentsMargins(node: node) {
                ui += contentMargins
            } else {
                ui += "        \(node.attributes["name"]!).contentsMargins = QMargins(left: 0, top: 0, right: 0, bottom: 0)\n"
            }
            
            for subNode in node.children {
                ui += subNode2Swift(node: subNode)
            }
            
            if let stretch = node.attributes["stretch"]?.split(separator: ",").map({ Int($0)! }) {
                for index in stretch.indices where stretch[index] != 0 {
                    ui += "        \(node.attributes["name"]!).setStretch(index: \(index), stretch: \(stretch[index]))\n"
                }
            }
            if let minSize = node.attributes["rowminimumheight"]?.split(separator: ",").map({ Int($0)! }) {
                for row in minSize.indices where minSize[row] != 0 {
                    ui += "        \(node.attributes["name"]!).setRowMinimumHeight(row: \(row), minSize: \(minSize[row]))\n"
                }
            }
            if let minSize = node.attributes["columnminimumwidth"]?.split(separator: ",").map({ Int($0)! }) {
                for column in minSize.indices where minSize[column] != 0 {
                    ui += "        \(node.attributes["name"]!).setColumnMinimumWidth(column: \(column), minSize: \(minSize[column]))\n"
                }
            }
            if let stretch = node.attributes["rowstretch"]?.split(separator: ",").map({ Int($0)! }) {
                for index in stretch.indices where stretch[index] != 0 {
                    ui += "        \(node.attributes["name"]!).setRowStretch(row: \(index), stretch: \(stretch[index]))\n"
                }
            }
            if let stretch = node.attributes["columnstretch"]?.split(separator: ",").map({ Int($0)! }) {
                for index in stretch.indices where stretch[index] != 0 {
                    ui += "        \(node.attributes["name"]!).setColumnStretch(column: \(index), stretch: \(stretch[index]))\n"
                }
            }
            if node.parent!.text == "item" {
                ui += "        \(node.parent!.parent!.attributes["name"]!).add(layout: \(node.attributes["name"]!)" + itemNodeTail(node: node.parent!) + "\n"
            }
            return ui
            
        case "item":
            for subNode in node.children {
                ui += subNode2Swift(node: subNode)
            }
        case "spacer":
            ui += spacerNode2Swift(node: node)
        case "zorder":
            let name: String
            if node.value == "layoutWidget" {
                name = node.parent?.children.first(where: { $0.attributes["name"]!.hasPrefix("layoutWidget") })?.attributes["name"] ?? ""
            } else {
                name = node.value
            }
            ui += "        \(name).raise()\n"
        case "attribute":
            if node.attributes["name"] == "buttonGroup", let group = node.children.first?.value {
                ui += "        \(group).addButton(\(node.parent!.attributes["name"]!))\n"
            } else if node.attributes["name"] == "title" {
                tabTitle = "\"" + node.children.first!.value + "\""
            } else {
                fallthrough
            }
        default:
            ui += "        \(node.description)\n"
        }
        
        ui += preextractContentsMargins(node: node) ?? ""
        
        return ui
    }
    
    private func getParentWidget(node: Node) -> Node? {
        guard let parent = node.parent else {
            return nil
        }
        if parent.attributes["class"] != nil {
            if parent.attributes["class"]! == "QDockWidget" {
                return nil
            }
        }
        var current = parent
        while current.text != "widget" {
            guard let parent = current.parent else {
                return nil
            }
            current = parent
        }
        return current
    }
    
    private func itemNodeTail(node: Node) -> String {
        if let row = node.attributes["row"],
           let column = node.attributes["column"] {
            let colSpan = node.attributes["colspan"]
            let rowSpan = node.attributes["rowspan"]
            if colSpan != nil || rowSpan != nil {
                // add(widget: QWidget, fromRow: Int32, fromColumn: Int32, rowSpan: Int32, columnSpan: Int32, alignment: Qt.Alignment = [])
                return ", fromRow: \(row), fromColumn: \(column), rowSpan: \(rowSpan ?? "1"), columnSpan: \(colSpan ?? "1"))"
            } else {
                // add(widget: QWidget, row: Int32, column: Int32, alignment: Qt.Alignment? = nil)
                return ", row: \(row), column: \(column))"
            }
        }
        else {
            return ")\n"
        }
    }
    
    private func propertyNode2Swift(node: Node, for name: String) -> String {
        switch node.text {
        case "string":
            guard
                localizable,
                node.attributes["notr"] != "true",
                !node.value.isEmpty
            else { fallthrough }
            var comment = node.attributes["comment"] ?? ""
            if let extra = node.attributes["extracomment"] {
                comment += ", " + extra
            }
            var key = name
            if lstrings[name] != nil {
                var number = 1
                while lstrings["\(key)_\(number)"] != nil {
                    number += 1
                }
                key = "\(key)_\(number)"
            }
            lstrings[key] = (value: node.value, comment: comment)
            if node.value.contains("\n") ||
                node.value.contains("\"")
            {
                return #"NSLocalizedString("\#(key)", tableName: "\#(fileName)", bundle: Bundle.lang, value: \#n"""\#n\#(node.value)\#n""", comment: "\#(comment)")"#
            } else {
                return #"NSLocalizedString("\#(key)", tableName: "\#(fileName)", bundle: Bundle.lang, value: "\#(node.value)", comment: "\#(comment)")"#
            }
        case "pixmap":
            if node.value.contains("\n") ||
                node.value.contains("\"")
            {
                return "\"\"\"\n" + node.value + "\n\"\"\""
            } else {
                return "\"" + node.value + "\""
            }
            
        case "enum":
            return "." + node.value.components(separatedBy: "::").last!
            
        case "set":
            var separated = node.value.components(separatedBy: "|")
            for (index, element) in separated.enumerated() {
                let enumCase = element.components(separatedBy: "::").last!
                separated[index] = "." + enumCase
            }
            if separated.count > 1 {
                return "[\(separated.joined(separator: ", "))]"
            } else {
                return separated[0]
            }
            
        case "bool", "number":
            return node.value
            
        case "rect":
            var x = 0
            var y = 0
            var width = 0
            var height = 0
            for child in node.children {
                switch child.text {
                case "x":
                    x = Int(child.value)!
                case "y":
                    y = Int(child.value)!
                case "width":
                    width = Int(child.value)!
                case "height":
                    height = Int(child.value)!
                default:
                    print("unknown rect:", child.text, to: &stderror)
                }
            }
            return "QRect(x: \(x), y: \(y), width: \(width), height: \(height))"
            
        case "size":
            var width = 0
            var height = 0
            for child in node.children {
                switch child.text {
                case "width":
                    width = Int(child.value)!
                case "height":
                    height = Int(child.value)!
                default:
                    print("unknown size:", child.text, to: &stderror)
                }
            }
            return "QSize(width: \(width), height: \(height))"
            
        default:
            return node.text
        }
        
    }
    
    private func spacerNode2Swift(node: Node) -> String {
        var ui = ""
        var width: Int = 0
        var height: Int = 0
        var horizontalPolicy: String = ""
        var verticalPolicy: String = ""
        var orientation = ""
        
        for subNode in node.children {
            switch subNode.attributes["name"]! {
            case "orientation":
                orientation = subNode.children[0].value
                switch orientation {
                case "Qt::Horizontal":
                    horizontalPolicy = ".Expanding"
                    verticalPolicy = ".Minimum"
                case "Qt::Vertical":
                    horizontalPolicy = ".Minimum"
                    verticalPolicy = ".Expanding"
                default:
                    break
                }
            case "sizeType":
                let sizeType = subNode.children[0].value.replacingOccurrences(of: "QSizePolicy::", with: ".")
                switch orientation {
                case "Qt::Horizontal":
                    horizontalPolicy = sizeType
                case "Qt::Vertical":
                    verticalPolicy = sizeType
                default:
                    break
                }
            case "sizeHint":
                let sizeNode = subNode.children[0]
                for sizeSubNode in sizeNode.children {
                    if sizeSubNode.text == "width" {
                        width = Int(sizeSubNode.value)!
                    } else if sizeSubNode.text == "height" {
                        height = Int(sizeSubNode.value)!
                    }
                }
            default:
                break
            }
        }
        
        ui += "        \(node.attributes["name"]!) = QSpacerItem(width: \(width), height: \(height), horizontalPolicy: \(horizontalPolicy), verticalPolicy: \(verticalPolicy))\n"
        ui += "        \(node.parent!.parent!.attributes["name"]!).add(item: \(node.attributes["name"]!)" + itemNodeTail(node: node.parent!) + "\n"
        
        return ui
    }
    
    private func getInstancePropertyNodes(root node: Node) -> [Node] {
        var propertyNodes: [Node] = []
        func traverse(node: Node) {
            for subNode in node.children {
                if subNode.text == "widget" || subNode.text == "layout" || subNode.text == "spacer" || subNode.text == "action" {
                    propertyNodes.append(subNode)
                }
                traverse(node: subNode)
            }
        }
        
        traverse(node: node)
        return propertyNodes
    }
}

extension QliftUIParser: XMLParserDelegate {
    public func parserDidStartDocument(_ parser: XMLParser) {
        currentNode = rootNode
    }
    
    public func parser(_ parser: XMLParser, didStartElement element: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        let node = Node(parent: currentNode!, text: element)
        node.attributes = attributes
        currentNode!.children.append(node)
        currentNode = node
    }
    
    public func parser(_ parser: XMLParser, didEndElement element: String, namespaceURI: String?, qualifiedName: String?) {
        guard let hasParent = currentNode!.parent else {
            currentNode = rootNode
            return
        }
        currentNode = hasParent
    }
    
    public func parser(_ parser: XMLParser, foundCharacters: String) {
        currentNode!.value += foundCharacters
    }
}
