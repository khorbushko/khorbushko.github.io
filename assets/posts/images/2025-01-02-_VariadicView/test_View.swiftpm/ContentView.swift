import SwiftUI

struct ContentView: View {

  @ViewBuilder var parts: some View {
      Text("First")
      Text("Second")
      Text("Third")
  }

  var body: some View {
    VStack {

      VStack(spacing: 10.0) {

        VStack {
          Text("VStack").bold()
          parts
        }
        .border(.yellow)

        CustomVStack_UnaryViewRoot {
          Text("CustomVStack_UnaryViewRoot").bold()
          parts
        }
        .border(.blue)

        CustomVStack_MultiViewRoot {
          Text("CustomVStack_MultiViewRoot").bold()
          parts
        }
        .border(.red)

        Group {
          Text("Group").bold()
          parts
        }
        .border(.orange)

        List {
          Text("List").bold()
          parts
        }
        .border(.purple)

        CustomList {
          Text("CustomList").bold()
          parts
        }
        .bordered()

      }
    }
  }
}

struct VStackLayout_UnaryViewRoot: _VariadicView_UnaryViewRoot {
  func body(children: _VariadicView.Children) -> some View {
    return children
  }
}

struct VstackLayout_MultiViewRoot: _VariadicView_MultiViewRoot {
  func body(children: _VariadicView.Children) -> some View {
    return children
  }
}

struct CustomVStack_UnaryViewRoot<Content: View>: View {
  var content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    _VariadicView.Tree(VStackLayout_UnaryViewRoot()) {
      content
    }
  }
}

struct CustomVStack_MultiViewRoot<Content: View>: View {
  var content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    _VariadicView.Tree(VstackLayout_MultiViewRoot()) {
      content
    }
  }
}


struct CustomListRoot: _VariadicView_ViewRoot {
  func body(children: _VariadicView.Children) -> some View {
    ScrollView {
      ForEach(children) { child in
        child
          .padding(.vertical, 4)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.gray.opacity(0.1))
          .cornerRadius(4)
      }
    }
    .padding()
  }
}

struct CustomList<Content: View>: View {
  @ViewBuilder let content: Content

  var body: some View {
    _VariadicView.Tree(CustomListRoot()) {
      content
    }
  }
}

extension CustomList {
  func bordered() -> some View {
    self
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.blue, lineWidth: 1)
      )
  }
}
