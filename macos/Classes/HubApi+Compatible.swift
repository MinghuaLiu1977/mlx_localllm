import Foundation
import Hub

extension HubApi {
    func httpHeadCompatible(for url: URL) async throws -> HTTPURLResponse {
        let response = try await self.httpHead(for: url)
        
        let contentLength = response.value(forHTTPHeaderField: "Content-Length")
        let linkedSize = response.value(forHTTPHeaderField: "X-Linked-Size") ?? response.value(forHTTPHeaderField: "x-amz-meta-size")
        
        if (contentLength == nil || contentLength == "0") {
            var finalSize = linkedSize
            
            if finalSize == nil {
                finalSize = "1024"
            }
            
            if let finalSize = finalSize {
                var allFields = response.allHeaderFields
                allFields["Content-Length"] = finalSize
                
                if let compatResponse = HTTPURLResponse(
                    url: response.url!,
                    statusCode: response.statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: allFields as? [String: String]
                ) {
                    return compatResponse
                }
            }
        }
        return response
    }
}
