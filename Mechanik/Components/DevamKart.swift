//
//  DevamKart.swift
//  Mechanik
//
//  Created by efe arslan on 12.07.2025.
//

import SwiftUI

struct devamKart: View {
    var logo: String
    var arac: String
    var plaka: String
    var bakimTuru: String
    var clicked: () -> Void

    var body: some View {
        VStack(alignment: .leading){
            Image(logo) // logo
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .padding(.top, 10)
            

            Text(arac)
                .font(.subheadline)
                .lineLimit(2) // örneğin en fazla 2 satıra izin verir
                .multilineTextAlignment(.leading)
                .foregroundColor(.white)
            
            Text(plaka) //plaka
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        
            
            HStack {
                Text(bakimTuru)
                    .font(.headline)
                    .foregroundColor(.myBlack)
//                    .padding(.trailing, 50)
                
                Spacer()
                
                Button(action: {
                    withAnimation{
                        clicked()
                    }
                }) {
                    Image(systemName: "arrow.up.right") // Ok simgesi
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 15)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.myBlack)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .frame(width: 150, height: 25)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .overlay(RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white, lineWidth: 1))

            
        }
        .padding()
        .background(Color.myRed).cornerRadius(15)
        .frame(height: 250)
        .padding(.bottom, 10)
//        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 10)


    }
}

