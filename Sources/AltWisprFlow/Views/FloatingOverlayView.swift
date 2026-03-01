import SwiftUI

struct FloatingOverlayView: View {
    @ObservedObject var viewModel: FloatingOverlayViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: viewModel.isRecording ? "mic.fill" : "mic.slash")
                    .foregroundColor(viewModel.isRecording ? .red : .secondary)
                    .font(.system(size: 20))
                
                if viewModel.confidence > 0 {
                    Capsule()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: CGFloat(viewModel.confidence) * 100, height: 4)
                }
                
                Spacer()
                
                Button(action: { viewModel.toggleRecording() }) {
                    Image(systemName: viewModel.isRecording ? "stop.circle" : "record.circle")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.isRecording ? .red : .primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.7))
            
            if !viewModel.transcript.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.transcript)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .lineLimit(5)
                    
                    if viewModel.transcript.contains("API keys") {
                        Button(action: {
                            SettingsWindow.shared.show()
                        }) {
                            Text("Open Settings")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(12)
                .frame(maxWidth: 300, alignment: .leading)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 4)
        .background(Color.clear)
    }
}
