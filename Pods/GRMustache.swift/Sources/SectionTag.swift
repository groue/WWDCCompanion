// The MIT License
//
// Copyright (c) 2015 Gwendal Roué
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import Foundation

/// A SectionTag represents a regular or inverted section tag such as
/// {{#section}}...{{/section}} or {{^section}}...{{/section}}.
final class SectionTag: LocatedTag {
    let openingToken: TemplateToken
    let innerTemplateAST: TemplateAST
    
    init(innerTemplateAST: TemplateAST, openingToken: TemplateToken, innerTemplateString: String) {
        self.innerTemplateAST = innerTemplateAST
        self.openingToken = openingToken
        self.innerTemplateString = innerTemplateString
    }
    
    // Mark: - Tag protocol
    
    let type: TagType = .section
    let innerTemplateString: String
    var tagDelimiterPair: TagDelimiterPair { return openingToken.tagDelimiterPair! }
    
    var description: String {
        return "\(openingToken.templateSubstring) at \(openingToken.locationDescription)"
    }
    
    func render(_ context: Context) throws -> Rendering {
        let renderingEngine = RenderingEngine(templateAST: innerTemplateAST, context: context)
        return try renderingEngine.render()
    }
    
    // Mark: - LocatedTag
    
    var templateID: TemplateID? { return openingToken.templateID }
    var lineNumber: Int { return openingToken.lineNumber }
}
