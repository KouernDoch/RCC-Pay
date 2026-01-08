//
//  ProfileView.swift
//  RCC Pay
//
//  Created by HRD on 1/8/26.
//

import SwiftUI

struct ProfileView: View {
    @State var choosingPhoto: Bool = false
    @State var selectedImage : UIImage?
    var body: some View {
        VStack{
                HStack{
                    UserProfile(choosingPhoto: $choosingPhoto, selectImage: $selectedImage)
                    VStack(alignment: .leading){
                        Text("Kouern Doch")
                            .font(.system(size: 16))
                        Text("Normal User")
                            .foregroundStyle(.gray)
                            .font(.system(size: 14))
                        
                    }
                    Spacer()
                    Text("")
                }

                Spacer()
            }
        .padding(.horizontal)
    }
}

#Preview {
    ProfileView()
}
