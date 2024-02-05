//
//  PencilMarks.swift
//  VariantSudoku
//
//  Created by chuck ha on 2/4/24.
//

import SwiftUI

enum ControlMode: String, Equatable, CaseIterable {
	case BigNumber
	case CornerNumber
	case MiddleNumber
}

struct ControlToggleStyle: ToggleStyle {
	func makeBody(configuration: Configuration) -> some View {
		Button {
			configuration.isOn.toggle()
		} label: {
			Rectangle()
				.frame(width: 60, height: 60)
				.foregroundColor(configuration.isOn ? Color(red: 0.8, green: 0.8, blue: 1) : .clear)
				.border(Color.accentColor, width: 2)
		}
	}
}

func splitArray<T>(_ array: [T]) -> ([T], [T]) {
	if array.count < 4 {
		return (array, [])
	} else {
		let firstHalf = Array(array.prefix(4))
		let secondHalf = Array(array.dropFirst(4))
		return (firstHalf, secondHalf)
	}
}

struct PencilMarks: View {
	let marks: [Int]
	var color: Color = .black
	var size: CGFloat = 10

	var body: some View {
		let (top, bottom) = splitArray(marks.sorted())
		VStack {
			HStack(spacing: 4) {
				ForEach(top, id: \.self) { num in
					Text(num.description)
						.font(.system(size: size))
						.foregroundStyle(color)
				}
			}
			Spacer()
			HStack(spacing: 1) {
				ForEach(bottom, id: \.self) { num in
					Text(num.description)
						.font(.system(size: size))
						.foregroundStyle(color)
				}
			}
		}
	}
}

struct MiddleMarks: View {
	let marks: [Int]
	var color: Color = .black
	var size: CGFloat = 7

	var body: some View {
		HStack(spacing: 0) {
			ForEach(marks.sorted(), id: \.self) { num in
				Text(num.description)
					.font(.system(size: size))
					.foregroundStyle(color)
			}
		}
	}
}
