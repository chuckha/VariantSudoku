//
//  ContentView.swift
//  VariantSudoku
//
//  Created by chuck ha on 1/28/24.
//

import SwiftUI

struct ContentView: View {
	@StateObject private var grid: Game = killerCageIntro()

	var body: some View {
		VStack {
			GridView()
				.padding([.bottom])
			HStack {
				//                OptionsView()
				//                    .padding([.trailing])
				//                InputView()
				//                ControlView(controlMode: $grid.inputMode)
			}
		}
		//        .sheet(isPresented: $grid.victory, onDismiss: {
		//            grid.reset()
		//        }, content: {
		//            Text("you won!")
		//        })
		.environmentObject(grid)
	}
}

struct KillerCageCellView: View {
	var p: Point
	var constraint: KillerCageConstraint
	var body: some View {
		Rectangle()
			.aspectRatio(1, contentMode: .fit)
			.foregroundColor(.clear)
			.overlay(
				KillerCageBorder(width: 3, border: selectionBorder(p, group: constraint.group))
					.stroke(style: StrokeStyle(dash: [6]))
					.rotationEffect(borderDirToDegrees(bd: selectionBorder(p, group: constraint.group)))
			)
			.overlay(
				KillerCageCorner(width: 5, corners: corners(p, group: constraint.group))
					.stroke(style: StrokeStyle(dash: [3]))
			)
			.overlay(
				HStack {
					VStack {
						Text(topLeftCornerCell(p, group: constraint.group) ? "\(constraint.sumTo)" : "")
							.background(.white)
							.padding([.leading, .top], 6)
						Spacer()
					}
					Spacer()
				}
			)

		// get borders for a given point in the constraint list
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

struct GridView: View {
	@EnvironmentObject var grid: Game
	@State private var selected: Set<Point> = []

	var body: some View {
		GeometryReader { geo in
			VStack(spacing: 0) {
				ForEach(0 ..< grid.board.height, id: \.self) { row in
					HStack(spacing: 0) {
						ForEach(0 ..< grid.board.width, id: \.self) { col in
							ZStack {
								CellView(cell: Binding($grid.board.cells[Point(row: row, col: col)], Cell(point: Point(row: 0, col: 0), region: 0)))
								ForEach(grid.getKillerCages(), id: \.self) { cg in
									KillerCageCellView(p: Point(row: row, col: col), constraint: cg)
								}
								SelectedCell(p: Point(row: row, col: col), selected: $selected)
							}
						}
					}
				}
			}
			.contentShape(Rectangle())
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
						if value.startLocation == value.location {
							selected = []
						}
						let cellSize = geo.size.width / CGFloat(grid.board.width)
						let row = Int(value.location.y / cellSize)
						let col = Int(value.location.x / cellSize)
						print(row, col)
						if row >= 0, row < grid.board.height, col >= 0, col < grid.board.width {
							selected.insert(Point(row: row, col: col))
						}
					}
			)
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

func borderDirToDegrees(bd: (BorderSet, BorderDirection)) -> Angle {
	switch bd.1 {
	case .None, .Down:
		return Angle(degrees: 0)
	case .Left:
		return Angle(degrees: 90)
	case .Up:
		return Angle(degrees: 180)
	case .Right:
		return Angle(degrees: 270)
	case .Vertical:
		return Angle(degrees: 0)
	case .Horizontal:
		return Angle(degrees: 0)
	}
}

struct CellView: View {
	@Binding var cell: Cell

	var body: some View {
		Rectangle()
			.stroke(Color.primary, lineWidth: 1)
			.aspectRatio(1, contentMode: .fit)
			.foregroundColor(.clear)
	}
}

extension Binding {
	init(_ source: Binding<Value?>, _ defaultValue: Value) {
		// Ensure a non-nil value in `source`.
		if source.wrappedValue == nil {
			source.wrappedValue = defaultValue
		}
		// Unsafe unwrap because *we* know it's non-nil now.
		self.init(source)!
	}
}

#Preview {
	ContentView()
}
