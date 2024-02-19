//
//  Game.swift
//  VariantSudoku
//
//  Created by chuck ha on 1/28/24.
//

import SwiftUI

enum Tag {
	case Unique
	case Sum
	case Row
	case Column
	case Region
	case KillerCage
	case LittleKiller
	case Digits
	case SumPair
	case XV
	case Normal
	case Kropki
	case WhiteKropki
	case BlackKropki
	case Consecutive
	case TwoToOneRatio
}

class Game: ObservableObject {
	@Published var board: Board
	var constraintGenerators: [any ConstraintGenerator]
	private let constraints: [Constraint]
	@Published var selected: Set<Point> = []
	@Published var victory: Bool = false
	@Published var controlMode: ControlMode = .BigNumber

	init(board: Board, cgs: [any ConstraintGenerator]) {
		self.board = board
		constraintGenerators = cgs
		constraints = cgs.map { $0.rawConstraints() }.flatMap { $0 }
	}

	// getBy(type:) gets a list of constraint generators and returns them as the proper type
	func getBy<T: ConstraintGenerator>(ofType _: T.Type, tag: Tag) -> [T] {
		constraintGenerators.filter { $0.tags.contains(tag) }.map { $0 as! T }
	}

	func handleInput(input: Int) {
		switch controlMode {
		case .BigNumber:
			handleValue(input: input)
		case .CornerNumber:
			handleCorner(input: input)
		case .MiddleNumber:
			handleMiddleNumber(input: input)
		}
	}

	func handleValue(input: Int) {
		board.setCellValues(points: selected, value: input)
		checkConstraints()
		checkVictory()
	}

	func handleCorner(input: Int) {
		board.setCellCornerMark(points: selected, value: input)
	}

	func handleMiddleNumber(input: Int) {
		board.setCellMiddleMark(points: selected, value: input)
	}

	func checkVictory() {
		let allFilled = board.cells.reduce(into: true) { $0 = $0 && $1.value.effectiveValue() != nil }
		let noFailedConstraints = board.cells.reduce(into: 0) { $0 += $1.value.fails.count } == 0
		victory = allFilled && noFailedConstraints
	}

	func checkConstraints() {
		board.clearFailed()
		for constraint in constraints {
			let failed = constraint.valid(board: board.cells)
			if failed.count > 0 {
				print(constraint.name)
			}
			failed.forEach { board.cells[$0]?.fails.formUnion(constraint.tags) }
		}
	}

	/// handleDelete runs some complex logic on the order of what to delete and when.
	/// First, it will always try to delete the marks in the selected cells for the given control mode
	/// If it deletes nothing it will try to delete the middle marks, and then the corner marks and then the values.
	func handleDelete() {
		switch controlMode {
		case .BigNumber:
			if board.deleteValue(points: selected) {
				checkConstraints()
				return
			}
		case .CornerNumber:
			if board.deleteCornerMarks(points: selected) {
				return
			}
		case .MiddleNumber:
			if board.deleteMiddleMarks(points: selected) {
				return
			}
		}
		if board.deleteCornerMarks(points: selected) {
			return
		}
		if board.deleteMiddleMarks(points: selected) {
			return
		}
		if board.deleteValue(points: selected) {
			checkConstraints()
			return
		}
	}
}

class Board: ObservableObject {
	@Published var cells: [Point: Cell]
	let height: Int
	let width: Int

	init(cells: [Point: Cell], height: Int, width: Int) {
		self.cells = cells
		self.height = height
		self.width = width
	}

	@available(*, deprecated, message: "use regionForCell(at:) instead")
	func regionForCell(p: Point) -> Set<Point> {
		let c = cells[p]!
		return Set(cells.filter { $0.value.region == c.region }.map { $0.key })
	}

	func regionForCell(at: Point) -> Set<Point> {
		let c = cells[at]!
		return Set(cells.filter { $0.value.region == c.region }.map { $0.key })
	}

	func setCellValues(points: Set<Point>, value: Int) {
		cells.filter { points.contains($0.key) }.forEach { $0.value.set(value: value) }
	}

	func deleteValue(points: Set<Point>) -> Bool {
		let cellsWithValues = cells.filter { points.contains($0.key) }.filter { $0.value.value != nil }
		if cellsWithValues.isEmpty { return false }
		cellsWithValues.forEach { $0.value.clearValue() }
		return true
	}

	func setCellCornerMark(points: Set<Point>, value: Int) {
		cells.filter { points.contains($0.key) }.forEach { $0.value.setCorner(mark: value) }
	}

	func deleteCornerMarks(points: Set<Point>) -> Bool {
		let cellsWithCornerMarks = cells.filter { points.contains($0.key) }.filter { $0.value.cornerMarks.count > 0 }
		if cellsWithCornerMarks.isEmpty { return false }
		cellsWithCornerMarks.forEach { $0.value.clearCornerMarks() }
		return true
	}

	func setCellMiddleMark(points: Set<Point>, value: Int) {
		cells.filter { points.contains($0.key) }.forEach { $0.value.setMiddle(mark: value) }
	}

	func deleteMiddleMarks(points: Set<Point>) -> Bool {
		let cellsWithMiddleMarks = cells.filter { points.contains($0.key) }.filter { $0.value.middleMarks.count > 0 }
		if cellsWithMiddleMarks.isEmpty { return false }
		cellsWithMiddleMarks.forEach { $0.value.clearMiddleMarks() }
		return true
	}

	func setFailed(constraint: Constraint, on: Set<Point>) {
		cells.filter { on.contains($0.key) }.forEach { $0.value.fails.formUnion(constraint.tags) }
	}

	func clearFailed() {
		cells.forEach { $0.value.fails = [] }
	}

	func getCell(at: Point) -> Cell {
		if let c = cells[at] {
			return c
		}
		print("this is really bad")
		return Cell(point: Point(row: -1, col: -1), region: -1)
	}

	func reset() {
		cells.forEach { $0.value.clear() }
	}
}

struct Point: Hashable {
	let row: Int
	let col: Int

	init(row: Int, col: Int) {
		self.row = row
		self.col = col
	}

	init(_ row: Int, _ col: Int) {
		self.row = row
		self.col = col
	}

	func up() -> Point {
		Point(row: row - 1, col: col)
	}

	func upRight() -> Point {
		Point(row: row - 1, col: col + 1)
	}

	func right() -> Point {
		Point(row: row, col: col + 1)
	}

	func downRight() -> Point {
		Point(row: row + 1, col: col + 1)
	}

	func down() -> Point {
		Point(row: row + 1, col: col)
	}

	func downLeft() -> Point {
		Point(row: row + 1, col: col - 1)
	}

	func left() -> Point {
		Point(row: row, col: col - 1)
	}

	func upLeft() -> Point {
		Point(row: row - 1, col: col - 1)
	}
}

class Cell: ObservableObject {
	let point: Point
	let region: Int
	@Published var value: Int?
	var given: Int?
	@Published var fails: Set<Tag> = []
	@Published var cornerMarks: Set<Int> = []
	@Published var middleMarks: Set<Int> = []

	init(point: Point, region: Int, value: Int? = nil, given: Int? = nil) {
		self.point = point
		self.region = region
		self.value = value
		self.given = given
	}

	func color() -> Color {
		if given != nil {
			return Color.primary
		}
		return Color(red: 0.1, green: 0.1, blue: 1)
	}

	func displayValidationError() -> Bool {
		fails.contains(.Normal)
	}

	func displayValue() -> String {
		given?.description ?? value?.description ?? ""
	}

	func effectiveValue() -> Int? {
		given ?? value
	}

	func set(value: Int) { self.value = value }
	func clearValue() { value = nil }
	func setCorner(mark: Int) { cornerMarks.insert(mark) }
	func clearCornerMarks() { cornerMarks = [] }
	func setMiddle(mark: Int) { middleMarks.insert(mark) }
	func clearMiddleMarks() { middleMarks = [] }

	func clear() {
		value = nil
		fails = []
	}
}

enum BorderSet {
	case NoSides
	case OneSide
	case TwoSides
	case ThreeSides
	case FourSides
}

enum BorderDirection {
	case None
	case Up
	case Right
	case Down
	case Left
	case Vertical
	case Horizontal
}

enum Corner {
	case UpLeft
	case UpRight
	case DownRight
	case DownLeft
}

func topLeftCornerCell(_ p: Point, group: Set<Point>) -> Bool {
	// first find the highest points

	let miny = group.min { $0.row < $1.row }!.row // then find the left most point
	let minx = group.filter { $0.row == miny }.min { $0.col < $1.col }!.col
	return p.row == miny && p.col == minx
}

func corners(_ p: Point, group: Set<Point>) -> (Set<Corner>) {
	var corners: Set<Corner> = []
	let c = [group.contains(p.upLeft()), group.contains(p.up()), group.contains(p.upRight()),
	         group.contains(p.left()), group.contains(p.right()),
	         group.contains(p.downLeft()), group.contains(p.down()), group.contains(p.downRight()), group.contains(p)]
	if c[8], c[1], c[4], !c[2] {
		corners.insert(.UpRight)
	}
	if c[8], c[4], c[6], !c[7] {
		corners.insert(.DownRight)
	}
	if c[8], c[3], c[6], !c[5] {
		corners.insert(.DownLeft)
	}
	if c[8], c[1], c[3], !c[0] {
		corners.insert(.UpLeft)
	}
	return corners
}

func selectionBorder(_ p: Point, group: Set<Point>) -> (BorderSet, BorderDirection) {
	if !group.contains(p) {
		return (.NoSides, .None)
	}
	let c = [group.contains(p.up()), group.contains(p.right()), group.contains(p.down()), group.contains(p.left())]
	if !c[0], !c[1], !c[2], !c[3] {
		return (.FourSides, .None)
	}
	if c[0], !c[1], !c[2], !c[3] {
		return (.ThreeSides, .Up)
	}
	if !c[0], c[1], !c[2], !c[3] {
		return (.ThreeSides, .Right)
	}
	if !c[0], !c[1], c[2], !c[3] {
		return (.ThreeSides, .Down)
	}
	if !c[0], !c[1], !c[2], c[3] {
		return (.ThreeSides, .Left)
	}
	if c[0], !c[1], c[2], !c[3] {
		return (.TwoSides, .Vertical)
	}
	if !c[0], c[1], !c[2], c[3] {
		return (.TwoSides, .Horizontal)
	}
	// |_ left
	if c[0], c[1], !c[2], !c[3] {
		return (.TwoSides, .Right)
	}
	if !c[0], c[1], c[2], !c[3] {
		return (.TwoSides, .Down)
	}
	if !c[0], !c[1], c[2], c[3] {
		return (.TwoSides, .Left)
	}
	if c[0], !c[1], !c[2], c[3] {
		return (.TwoSides, .Up)
	}
	if !c[0], c[1], c[2], c[3] {
		return (.OneSide, .Down)
	}
	if c[0], !c[1], c[2], c[3] {
		return (.OneSide, .Left)
	}
	if c[0], c[1], !c[2], c[3] {
		return (.OneSide, .Up)
	}
	if c[0], c[1], c[2], !c[3] {
		return (.OneSide, .Right)
	}
	return (.NoSides, .None)
}

struct RegionBorder: Identifiable {
	let id: Edge
	var width: CGFloat
}

func regionBorders(p: Point, region: Set<Point>, width: CGFloat = 4) -> [RegionBorder] {
	var out: [RegionBorder] = [
		RegionBorder(id: .top, width: width),
		RegionBorder(id: .trailing, width: width),
		RegionBorder(id: .bottom, width: width),
		RegionBorder(id: .leading, width: width),
	]
	if region.contains(p.up()) {
		out[0].width = 0
	}
	if region.contains(p.right()) {
		out[1].width = 0
	}
	if region.contains(p.down()) {
		out[2].width = 0
	}
	if region.contains(p.left()) {
		out[3].width = 0
	}
	return out
}
