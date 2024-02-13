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
// - [x] little killers
// - [x] given digits are black, user entered are blue
// - [x] corner marks
// - [x] middle marks
// - [x] mode selection
// - [x] constraint failure highlights
// - [x] victory screen
// - [ ] get rid of hard coding sizes i guess
// - [ ] make diagonal selecting beter (reduce hit box in corners)

struct ContentView: View {
	@StateObject private var grid: Game = killerCageIntro()
//	@StateObject private var grid: Game = xvIntro()

	var body: some View {
		GeometryReader { geo in
			VStack {
				GameView().frame(height: geo.size.height * 0.5)
					.padding(40)
				HStack {
					//                OptionsView()
					//                    .padding([.trailing])
					InputView().frame(height: geo.size.height * 0.4)
					ControlView(controlMode: $grid.controlMode)
				}
			}
			.sheet(isPresented: $grid.victory, onDismiss: {
				print("nice")
			}, content: {
				Text("you won!")
			})
			.environmentObject(grid)
		}
	}
}

struct ControlView: View {
	@Binding var controlMode: ControlMode

	var body: some View {
		VStack {
			Toggle("", isOn: toggleBinding(for: .BigNumber))
				.toggleStyle(ControlToggleStyle())
				.overlay(
					BigNumber(text: "9")
				)
			Toggle("", isOn: toggleBinding(for: .CornerNumber))
				.toggleStyle(ControlToggleStyle())
				.overlay(
					PencilMarks(marks: [1, 2, 3, 4, 5, 6, 7, 8, 9], size: 15)
				)
			Toggle("", isOn: toggleBinding(for: .MiddleNumber))
				.toggleStyle(ControlToggleStyle())
				.overlay(
					MiddleMarks(marks: [1, 2, 3, 4], size: 15)
				)
			Spacer()
		}
		.padding(.leading)
	}

	func toggleBinding(for mode: ControlMode) -> Binding<Bool> {
		Binding<Bool>(
			get: { mode == controlMode },
			set: { _ in controlMode = mode }
		)
	}
}

struct CellSizeView: View {
	var color: Color = .clear

	var body: some View {
		Rectangle()
			.aspectRatio(1, contentMode: .fit)
			.foregroundColor(color)
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

struct BigNumber: View {
	let text: String
	var style: Color = .black

	var body: some View {
		CellSizeView()
			.overlay(
				GeometryReader { geo in
					Text(text)
						.lineLimit(1)
						.foregroundStyle(style)
						.font(.system(size: fontSizeFrom(size: geo.size)))
						.frame(maxWidth: .infinity, maxHeight: .infinity)
				}
			).frame(alignment: /*@START_MENU_TOKEN@*/ .center/*@END_MENU_TOKEN@*/)
	}
}

struct DisplayView: View {
	@ObservedObject var cell: Cell

	init(cell: Cell?) {
		self.cell = cell ?? Cell(point: Point(-1, -1), region: -1)
	}

	var body: some View {
		CellSizeView()
			.overlay(
				BigNumber(text: cell.displayValue(), style: cell.color())
					.opacity(cell.displayValue() == "" ? 0 : 1)
			)
			.overlay(
				MiddleMarks(marks: Array(cell.middleMarks), size: 20)
					.opacity(cell.displayValue() == "" ? 1 : 0)
			)
			.overlay(
				PencilMarks(marks: Array(cell.cornerMarks), size: 20)
					.opacity(cell.displayValue() == "" ? 1 : 0)
			)
	}
}

func fontSizeFrom(size: CGSize) -> CGFloat {
	return size.height - 14
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

// TODO: make this less fragile.
struct LittleKillerView: View {
	var p: Point
	var lk: LittleKillerConstraint

	var body: some View {
		GeometryReader { geo in
			VStack(spacing: -7) {
				Text(lk.group[0] == p ? "8" : "")
					.font(.system(size: 40))
					.padding(.leading, 25)
				Image(systemName: "arrow.down.left")
					.font(.system(size: lk.group[0] == p ? 20 : 0, weight: .bold))
			}
			.position(x: geo.size.width + 15, y: -35)
		}
	}
}

struct ConstraintsView: View {
	var height: Int
	var width: Int
	var killerCages: [KillerCageConstraint]
	var xvs: [XVConstraint]
	var littleKillers: [LittleKillerConstraint]

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
							ForEach(littleKillers, id: \.self) { lk in
								CellSizeView().overlay(LittleKillerView(p: Point(row, col), lk: lk))
							}
						}
					}
				}
			}
		}
	}
}

let validationFailedColor = Color(red: 0.8, green: 0.2, blue: 0.2, opacity: 0.3)

struct FailedConstraintCellView: View {
	@ObservedObject var cell: Cell

	init(cell: Cell?) {
		self.cell = cell ?? Cell(point: Point(-1, -1), region: -1)
	}

	var body: some View {
		CellSizeView(color: cell.displayValidationError() ? validationFailedColor : .clear)
	}
}

struct FailedConstraintsView: View {
	@ObservedObject var board: Board

	var body: some View {
		VStack(spacing: 0) {
			ForEach(0 ..< board.height, id: \.self) { row in
				HStack(spacing: 0) {
					ForEach(0 ..< board.width, id: \.self) { col in
						FailedConstraintCellView(cell: board.cells[Point(row, col)])
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
				                killerCages: game.getBy(ofType: KillerCageConstraint.self, tag: .KillerCage),
				                xvs: game.getBy(ofType: XVConstraint.self, tag: .XV),
				                littleKillers: game.getBy(ofType: LittleKillerConstraint.self, tag: .LittleKiller))
				//                OuterBoardConstraintsView(geo: geo)
				SelectedCellsView(height: game.board.height,
				                  width: game.board.width,
				                  selected: $game.selected)
				FailedConstraintsView(board: game.board)
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

				InputButton(label: "", action: {
					grid.handleDelete()
				})
				.overlay(
					Image(systemName: "delete.left.fill")
						.font(.system(size: 50)).allowsHitTesting(/*@START_MENU_TOKEN@*/false/*@END_MENU_TOKEN@*/)
				)
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
						.stroke(Color.primary)
				)
				.overlay(
					BigNumber(text: label)
				)
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
