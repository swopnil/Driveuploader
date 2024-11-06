import SwiftUI

struct PathCard: View {
    let currency: String
    let side: String
    let location: String
    
    var path: String {
        PathConstructor.getUploadPath(currency: currency, side: side, location: location)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upload Path")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(path)
                .font(.title3)
                .bold()
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5)
        )
    }
}
