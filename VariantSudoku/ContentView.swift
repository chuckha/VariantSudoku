//
//  ContentView.swift
//  VariantSudoku
//
//  Created by chuck ha on 1/28/24.
//

import SwiftUI

// - [x] region boundaries
// - [x] xv
// - [] actual gameplay lol

struct ContentView: View {
//	@StateObject private var grid: Game = killerCageIntro()
	@StateObject private var grid: Game = xvIntro()

	var body: some View {
		GeometryReader { geo in
			VStack {
				GridView()

				HStack {
					//                OptionsView()
					//                    .padding([.trailing])
					InputView().frame(height: geo.size.height * 0.4)
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
}

struct RegionView: View {
	var p: Point
	var region: Set<Point> = []

	var body: some View {
		Rectangle()
			.aspectRatio(1, contentMode: .fit)
			.foregroundColor(.clear)
			.overlay(
				ForEach(regionBorders(p: p, region: region)) { regionBorder in
					RegionBorderShape(edge: regionBorder.id)
						.stroke(style: StrokeStyle(lineWidth: regionBorder.width))
				}
			)
	}
}

struct RegionBorderShape: Shape {
	var edge: Edge

	func path(in rect: CGRect) -> Path {
		var path = Path()
		switch edge {
		case .top:
			path.move(to: CGPoint(x: rect.minX, y: rect.minY))
			path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
		case .leading:
			path.move(to: CGPoint(x: rect.minX, y: rect.minY))
			path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
		case .bottom:
			path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
			path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
		case .trailing:
			path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
			path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
		}
		return path
	}
}

struct VXView: View {
	var letter: String
	var region: [Point]
	var cw: CGFloat
	var ch: CGFloat

	var body: some View {
		Text(letter)
			.background(.white)
			.position(
				CGPoint(x: calcX(cw: cw, colA: region[0].col, colB: region[1].col),
				        y: calcY(ch: ch, rowA: region[0].row, rowB: region[1].row))
			)
	}
}

func calcX(cw: CGFloat, colA: Int, colB: Int) -> CGFloat {
	(CGFloat(colA) * cw + (cw / 2.0) + CGFloat(colB) * cw + (cw / 2.0)) / 2.0
}

func calcY(ch: CGFloat, rowA: Int, rowB: Int) -> CGFloat {
	(CGFloat(rowA) * ch + (ch / 2.0) + CGFloat(rowB) * ch + (ch / 2.0)) / 2.0
}

struct GridView: View {
	@EnvironmentObject var grid: Game

	var body: some View {
		GeometryReader { geo in
			VStack(spacing: 0) {
				ForEach(0 ..< grid.board.height, id: \.self) { row in
					HStack(spacing: 0) {
						ForEach(0 ..< grid.board.width, id: \.self) { col in
							ZStack {
								RegionView(p: Point(row: row, col: col), region: grid.board.regionForCell(p: Point(row: row, col: col)))
								CellView(cell: Binding($grid.board.cells[Point(row: row, col: col)], Cell(point: Point(row: 0, col: 0), region: 0)))
								ForEach(grid.getKillerCages(), id: \.self) { cg in
									KillerCageCellView(p: Point(row: row, col: col), constraint: cg)
								}
								SelectedCell(p: Point(row: row, col: col), selected: $grid.selected)
							}
						}
					}
				}
			}
			.overlay(
				ForEach(grid.getVs(), id: \.self) { v in
					// TODO: Fix this hack :(
					// bit of a hack here; assumes the width will always be the whole screen. This breaks on the ipad
					VXView(letter: "V", region: v.group, cw: geo.size.width / CGFloat(grid.board.width), ch: geo.size.width / CGFloat(grid.board.height))
				}
			)
			.overlay(
				ForEach(grid.getXs(), id: \.self) { v in
					// bit of a hack here; assumes the width will always be the whole screen.
					VXView(letter: "X", region: v.group, cw: geo.size.width / CGFloat(grid.board.width), ch: geo.size.width / CGFloat(grid.board.height))
				}
			)

			.contentShape(Rectangle())
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
						if value.startLocation == value.location {
							grid.selected = []
						}

						let cellSize = geo.size.width / CGFloat(grid.board.width)
						let row = Int(value.location.y / cellSize)
						let col = Int(value.location.x / cellSize)
						if row >= 0, row < grid.board.height, col >= 0, col < grid.board.width {
							grid.selected.insert(Point(row: row, col: col))
						}
					}
			)
		}
	}
}

struct InputView: View {
	@EnvironmentObject var grid: Game

	var body: some View {
		VStack {
			ForEach(0 ..< 3, id: \.self) { row in
				HStack {
					ForEach(0 ..< 3, id: \.self) { col in
						InputButton(label: (row * 3 + col + 1).description, action: {
							grid.handleInput(input: row * 3 + col + 1)
						})
						.aspectRatio(1, contentMode: .fit)
					}
				}
			}
			HStack {
				InputButton(label: "0", action: {
					grid.handleInput(input: 0)
				})
				.aspectRatio(1, contentMode: .fit)

				InputButton(label: "DELETE", action: {
					grid.handleDelete()
				})
				.aspectRatio(2.1, contentMode: .fit)
			}
		}
	}
}

struct InputButton: View {
	var label: String
	var action: () -> Void = {}

	var body: some View {
		Button(action: action) {
			Color.clear
				.overlay(
					RoundedRectangle(cornerRadius: 10)
						.stroke(Color.accentColor)
				)
				.overlay(Text(label))
		}
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
			.overlay(
				Text(cell.displayValue())
					.font(.system(size: 60))
			)
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
