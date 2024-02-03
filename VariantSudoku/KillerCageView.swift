//
//  KillerCageView.swift
//  VariantSudoku
//
//  Created by chuck ha on 1/30/24.
//

import SwiftUI

struct KillerCageCellViewV2: View {
	var p: Point
	var constraint: KillerCageConstraint
	var body: some View {
		CellSizeView().overlay(
			ZStack {
				KillerCageBorder(width: 3, border: selectionBorder(p, group: constraint.group))
					.stroke(style: StrokeStyle(dash: [6]))
					.rotationEffect(borderDirToDegrees(bd: selectionBorder(p, group: constraint.group)))
				KillerCageCorner(width: 5, corners: corners(p, group: constraint.group))
					.stroke(style: StrokeStyle(dash: [3]))
				HStack {
					VStack {
						Text(topLeftCornerCell(p, group: constraint.group) ? "\(constraint.sumTo)" : "")
							.background(.white)
							.padding([.leading, .top], 6)
						Spacer()
					}
					Spacer()
				}
			}
		)
	}
}

struct KillerCageCorner: Shape {
	var width: CGFloat
	var corners: Set<Corner>
	var inset: CGFloat = 10

	func path(in rect: CGRect) -> Path {
		var path = Path()
		for corner in corners {
			switch corner {
			case .UpLeft:
				path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
				path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + inset))
				path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
				path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY))
			case .UpRight:
				path.move(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
				path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
				path.move(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
				path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + inset))
			case .DownRight:
				path.move(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset))
				path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - inset))
				path.move(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset))
				path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
			case .DownLeft:
				path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset))
				path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - inset))
				path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset))
				path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
			}
		}
		return path
	}
}

struct KillerCageBorder: Shape {
	var width: CGFloat
	var border: (BorderSet, BorderDirection)

	var inset: CGFloat = 10

	func path(in rect: CGRect) -> Path {
		var path = Path()
		switch border.0 {
		case .NoSides:
			break
		case .OneSide:
			path.move(to: CGPoint(x: rect.minX, y: rect.minY + inset))
			path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + inset))
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
			path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
			path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + inset))
			path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
			path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
		case .ThreeSides:
			path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
			path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
			path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
			path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
			path.move(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
			path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
		case .FourSides:
			break
			//            path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))
			//            path.addRect(CGRect(x: rect.minX, y: rect.minY+width, width: width, height: rect.height-width))
			//            path.addRect(CGRect(x: rect.maxX-width, y: rect.minY+width, width: width, height: rect.height-width))
			//            path.addRect(CGRect(x: rect.minX+width, y: rect.maxY-width, width: rect.height-width, height: width))
		}
		return path
	}
}
