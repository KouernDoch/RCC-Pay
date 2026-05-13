//
//  UserProfile.swift
//  RCC Pay
//
//  Created by HRD on 1/8/26.
//

import SwiftUI
import PhotosUI

struct UserProfile: View {
    @Binding var choosingPhoto : Bool
    @Binding var selectImage : UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State var showPhotoPicker = true
    var body: some View {
        ZStack{
            if let selectImage {
                Image(uiImage: selectImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    }
            }else{
                Image("Profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    }
            }
            
            VStack{
                Image(systemName: "camera")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.black)
                    .onTapGesture {
                        choosingPhoto = true
                    }
            }
            .padding(5)
            .background(Color.white)
            .clipShape(Circle())
            .offset(x: 20, y: 20)
        }
        
        
        
        .sheet(isPresented: $choosingPhoto){
            PhotosPicker(selection: $selectedItem,
                         matching: .images){
                Text("Select Photo")
                    .bold()
                       .foregroundColor(.white)
                       .padding(.horizontal, 20)
                       .padding(.vertical, 10)
                       .background(Color.blue)
                       .clipShape(RoundedRectangle(cornerRadius: 8))
                   
            }
            .presentationDetents([.height(100)])
                        
        }
//        .actionSheet(isPresented: $choosingPhoto, content: {
//            ActionSheet(title: Text("koko"),
//                        buttons: [.default(
//                            Text("Choose image")
//                        ){
//                            PhotosPicker(selection: $selectedItem,
//                                         matching: .images){}
//                        }
//                        ,.cancel()])
//        })
        .onChange(of: selectedItem) { _, newValue in
            if let newValue {
                loadImage(from: newValue)
            }
            choosingPhoto = false
        }
    }
    
    private func loadImage(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                selectImage = uiImage
            }
        }
    }
    
}
#Preview {
    ProfileView()
}
