import SwiftUI

extension View {
    /// Keeps full-screen layouts intact when the viewport is tall enough
    /// (Spacer-driven centering still fills the screen) and turns the page
    /// scrollable when it isn't — e.g. iPhone-class layouts in iPad
    /// compatibility windows, where fixed-height VStacks clip off-screen.
    func fitsOrScrolls() -> some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                self
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            // Re-enable scrolling for this subtree: the onboarding TabView sets
            // scrollDisabled(true) to kill page-swiping, and that environment
            // value would otherwise disable this ScrollView too.
            .scrollDisabled(false)
        }
    }
}
