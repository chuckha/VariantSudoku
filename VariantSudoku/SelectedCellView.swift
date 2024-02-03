//
//  SelectedCellView.swift
//  VariantSudoku
//
//  Created by chuck ha on 1/30/24.
//

import SwiftUI

// TODO: restructure this to call selectionBorder less...if it becomes laggy
struct SelectedCell: View {
	var p: Point
	@Binding var selected: Set<Point>
	var width: CGFloat = 10

	var body: some View {
		Rectangle()
			//            .stroke(Color.primary, lineWidth: 1)
			.foregroundStyle(.clear)
			.aspectRatio(1, contentMode: .fit)
			.overlay(
				SelectedBorder(width: width, border: selectionBorder(p, group: selected))
					.fill(Color(red: 0.3, green: 0.3, blue: 0.9, opacity: 0.3))
					.rotationEffect(borderDirToDegrees(bd: selectionBorder(p, group: selected)))
			)
			.overlay(
				SelectedCorners(width: width, corners: corners(p, group: selected))
					.fill(Color(red: 0.3, green: 0.3, blue: 0.9, opacity: 0.3))
			)
	}
}

struct SelectedCellV2: View {
	var p: Point
	@Binding var selected: Set<Point>
	var width: CGFloat = 10

	var body: some View {
		ZStack {
			Rectangle()
				.fill(selected.contains(p) ? Color(red: 0.3, green: 0.3, blue: 0.9, opacity: 0.01) : .clear)
			SelectedBorder(width: width, border: selectionBorder(p, group: selected))
				.fill(Color(red: 0.3, green: 0.3, blue: 0.9, opacity: 0.3))
				.rotationEffect(borderDirToDegrees(bd: selectionBorder(p, group: selected)))
			SelectedCorners(width: width, corners: corners(p, group: selected))
				.fill(Color(red: 0.3, green: 0.3, blue: 0.9, opacity: 0.3))
		}
	}
}

struct SelectedCorners: Shape {
	var width: CGFloat
	var corners: Set<Corner>

	func path(in rect: CGRect) -> Path {
		var path = Path()
		for corner in corners {
			switch corner {
			case .UpLeft:
				path.addRect(CGRect(x: rect.minX, y: rect.minY, width: width, height: width))
			case .UpRight:
				path.addRect(CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: width))
			case .DownRight:
				path.addRect(CGRect(x: rect.maxX - width, y: rect.maxY - width, width: width, height: width))
			case .DownLeft:
				path.addRect(CGRect(x: rect.minX, y: rect.maxY - width, width: width, height: width))
			}
		}
		return path
	}
}

struct SelectedBorder: Shape {
	var width: CGFloat
	var border: (BorderSet, BorderDirection)

	func path(in rect: CGRect) -> Path {
		var path = Path()
		switch border.0 {
		case .NoSides:
			break
		case .OneSide:
			path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))
		case .TwoSides:
			if border.1 == .Vertical {
				path.addRect(CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))
				path.addRect(CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
				break
			}
			if border.1 == .Horizontal {
				path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))
				path.addRect(CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
				break
			}
			path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))
			path.addRect(CGRect(x: rect.minX, y: rect.minY + width, width: width, height: rect.height - width))
		case .ThreeSides:
			path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))
			path.addRect(CGRect(x: rect.minX, y: rect.minY + width, width: width, height: rect.height - width))
			path.addRect(CGRect(x: rect.maxX - width, y: rect.minY + width, width: width, height: rect.height - width))
		case .FourSides:
			path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))
			path.addRect(CGRect(x: rect.minX, y: rect.minY + width, width: width, height: rect.height - width))
			path.addRect(CGRect(x: rect.maxX - width, y: rect.minY + width, width: width, height: rect.height - width))
			path.addRect(CGRect(x: rect.minX + width, y: rect.maxY - width, width: rect.height - width, height: width))
		}
		return path
	}
}
