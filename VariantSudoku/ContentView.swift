//
//  ContentView.swift
//  VariantSudoku
//
//  Created by chuck ha on 1/28/24.
//

import SwiftUI

// - [x] region boundaries
// - [x] xv
// - [x] actual gameplay lol
// - [ ] given digits are black, user entered are blue
// - [ ] corner marks
// - [ ] middle marks
// - [ ] mode selection
// - [ ] constraint failure highlights

struct ContentView: View {
//	@StateObject private var grid: Game = killerCageIntro()
	@StateObject private var grid: Game = xvIntro()

	var body: some View {
		GeometryReader { geo in
			VStack {
				GameView()
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

struct CellSizeView: View {
	var body: some View {
		Rectangle()
			.aspectRatio(1, contentMode: .fit)
			.foregroundColor(.clear)
	}
}

struct DividerView: View {
	var body: some View {
		Rectangle()
			.stroke(Color.primary, lineWidth: 1)
			.aspectRatio(1, contentMode: .fit)
			.foregroundColor(.clear)
	}
}

struct RegionViewV2: View {
	var p: Point
	var region: Set<Point> = []

	var body: some View {
		CellSizeView()
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

struct DisplayView: View {
	@ObservedObject var cell: Cell

	init(cell: Cell?) {
		self.cell = cell ?? Cell(point: Point(-1, -1), region: -1)
	}

	var body: some View {
		Text(cell.displayValue())
			.font(.system(size: 50.0))
	}
}

struct XVView: View {
	var xv: XVConstraint
	var body: some View {
		GeometryReader { geo in
			Text(xv.name())
				.padding(2)
				.background(.white)
				.position(
					xv.leftRight() ? CGPoint(x: geo.size.width, y: geo.size.height / 2) : CGPoint(x: geo.size.width / 2, y: geo.size.height))
		}
	}
}

struct BoardView: View {
	@ObservedObject var board: Board

	var body: some View {
		VStack(spacing: 0) {
			ForEach(0 ..< board.height, id: \.self) { row in
				HStack(spacing: 0) {
					ForEach(0 ..< board.width, id: \.self) { col in
						ZStack {
							DividerView()
							DisplayView(cell: board.cells[Point(row, col)])
							RegionViewV2(p: Point(row, col), region: board.regionForCell(at: Point(row, col)))
						}
					}
				}
			}
		}
	}
}

struct SelectedCellsView: View {
	var height: Int
	var width: Int
	@Binding var selected: Set<Point>

	var body: some View {
		VStack(spacing: 0) {
			ForEach(0 ..< height, id: \.self) { row in
				HStack(spacing: 0) {
					ForEach(0 ..< width, id: \.self) { col in
						SelectedCell(p: Point(row, col), selected: $selected)
					}
				}
			}
		}
	}
}

struct ConstraintsView: View {
	var height: Int
	var width: Int
	var killerCages: [KillerCageConstraint]
	var xvs: [XVConstraint]

	var body: some View {
		VStack(spacing: 0) {
			ForEach(0 ..< height, id: \.self) { row in
				HStack(spacing: 0) {
					ForEach(0 ..< width, id: \.self) { col in
						ZStack {
							ForEach(killerCages, id: \.self) { cg in
								KillerCageCellViewV2(p: Point(row: row, col: col), constraint: cg)
							}
							CellSizeView().overlay(
								ForEach(xvs.filter { $0.group[0] == Point(row, col) }, id: \.self) { xv in
									XVView(xv: xv)
								}
							)
						}
					}
				}
			}
		}
	}
}

struct GameView: View {
	@EnvironmentObject var game: Game

	var body: some View {
		GeometryReader { geo in
			ZStack {
				BoardView(board: game.board)
				ConstraintsView(height: game.board.height,
				                width: game.board.width,
				                killerCages: game.getKillerCages(),
				                xvs: game.getXVs())
				SelectedCellsView(height: game.board.height,
				                  width: game.board.width,
				                  selected: $game.selected)
			}
			.contentShape(Rectangle())
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
						if value.startLocation == value.location {
							game.selected = []
						}

						let cellSize = geo.size.width / CGFloat(game.board.width)
						let row = Int(value.location.y / cellSize)
						let col = Int(value.location.x / cellSize)
						if row >= 0, row < game.board.height, col >= 0, col < game.board.width {
							game.selected.insert(Point(row: row, col: col))
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

func borderDirToDegrees(bd: (BorderSet, BorderDirection)) -> Angle { switch bd.1 {
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

#Preview {
	ContentView()
}
