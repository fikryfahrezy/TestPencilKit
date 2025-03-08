import SwiftUI
import PencilKit

struct ContentView: View {
    private let canvasView = PKCanvasView()
    var body: some View {
        MyCanvasView(canvasView: canvasView)
    }
}

struct MyCanvasView: UIViewRepresentable {
    var canvasView: PKCanvasView
    private let drawing = PKDrawing()
    private let toolPicker = PKToolPicker()
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        canvasView.alwaysBounceVertical = true
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.addObserver(context.coordinator)
        context.coordinator.updateLayout(for: toolPicker)
        canvasView.becomeFirstResponder()
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate, PKToolPickerObserver {
        let parent: MyCanvasView
        
        /// Standard amount of overscroll allowed in the canvas.
        static let canvasOverscrollHeight: CGFloat = 500
        
        /// Private drawing state.
        var hasModifiedDrawing = false
        
        init(_ parent: MyCanvasView) {
            self.parent = parent
        }
        
        // MARK: Canvas View Delegate
        
        /// Delegate method: Note that the drawing has changed.
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            hasModifiedDrawing = true
            updateContentSizeForDrawing()
        }
        
        /// Helper method to set a suitable content size for the canvas view.
        func updateContentSizeForDrawing() {
            // Update the content size to match the drawing.
            let drawing = self.parent.canvasView.drawing
            let contentHeight: CGFloat
            
            // Adjust the content size to always be bigger than the drawing height.
            if drawing.bounds.isNull {
                return
            }
            
            contentHeight = max(
                self.parent.canvasView.bounds.height,
                (drawing.bounds.maxY + Coordinator.canvasOverscrollHeight) * self.parent.canvasView.zoomScale
            )
            
            self.parent.canvasView.contentSize = CGSize(
                width: DataModel.canvasWidth * self.parent.canvasView.zoomScale,
                height: contentHeight
            )
        }
        
        // MARK: Tool Picker Observer
        
        /// Delegate method: Note that the tool picker has changed which part of the canvas view
        /// it obscures, if any.
        func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
            updateLayout(for: toolPicker)
        }
        
        /// Delegate method: Note that the tool picker has become visible or hidden.
        func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
            updateLayout(for: toolPicker)
        }
        
        /// Helper method to adjust the canvas view size when the tool picker changes which part
        /// of the canvas view it obscures, if any.
        ///
        /// Note that the tool picker floats over the canvas in regular size classes, but docks to
        /// the canvas in compact size classes, occupying a part of the screen that the canvas
        /// could otherwise use.
        func updateLayout(for toolPicker: PKToolPicker) {
            let obscuredFrame = toolPicker.frameObscured(
                in: self.parent.canvasView
            )
            
            // If the tool picker is floating over the canvas, it also contains
            // undo and redo buttons.
            if obscuredFrame.isNull {
                self.parent.canvasView.contentInset = .zero
            }
            
            // Otherwise, the bottom of the canvas should be inset to the top of the
            // tool picker, and the tool picker no longer displays its own undo and
            // redo buttons.
            else {
                self.parent.canvasView.contentInset = UIEdgeInsets(
                    top: 0,
                    left: 0,
                    bottom: self.parent.canvasView.bounds.maxY - obscuredFrame.minY,
                    right: 0
                )
            }
            self.parent.canvasView.scrollIndicatorInsets = self.parent.canvasView.contentInset
        }
    }
}

/// `DataModel` contains the drawings that make up the data model, including multiple image drawings and a signature drawing.
struct DataModel: Codable {
    
    /// The width used for drawing canvases.
    static let canvasWidth: CGFloat = 768
}

#Preview {
    ContentView()
}
