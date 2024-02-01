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
	case X
	case V
	case Digits
}

class Game: ObservableObject {
	@Published var board: Board
	var constraintGenerators: [any ConstraintGenerator]
	private let constraints: [Constraint]

	init(board: Board, cgs: [any ConstraintGenerator]) {
		self.board = board
		constraintGenerators = cgs
		constraints = cgs.map { $0.rawConstraints() }.flatMap { $0 }
	}

	func getKillerCages() -> [KillerCageConstraint] {
		constraintGenerators.filter { $0.tags.contains(.KillerCage) }.map { $0 as! KillerCageConstraint }
	}

	func getVs() -> [VConstraint] {
		constraintGenerators.filter { $0.tags.contains(.V) }.map { $0 as! VConstraint }
	}

	func getXs() -> [XConstraint] {
		constraintGenerators.filter { $0.tags.contains(.X) }.map { $0 as! XConstraint }
	}

	func handleInput(input: Int) {
		print("\(input)")
	}

	func handleDelete() {
		print("Delete!")
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

	func regionForCell(p: Point) -> Set<Point> {
		let c = cells[p]!
		return Set(cells.filter { $0.value.region == c.region }.map { $0.key })
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

	init(point: Point, region: Int, value: Int? = nil, given: Int? = nil) {
		self.point = point
		self.region = region
		self.value = value
		self.given = given
	}

	func displayValue() -> String {
		given?.description ?? value?.description ?? ""
	}
}

protocol Constraint {
	var name: String { get set }
	var group: Set<Point> { get set }

	func valid(board: [Point: Cell]) -> Set<Point>
}

class ValidDigit: Constraint {
	var name: String
	var group: Set<Point> = []
	let validDigits: Set<Int>

	init(name: String, validDigits: Set<Int>) {
		self.name = name
		self.validDigits = validDigits
		group = []
	}

	func valid(board: [Point: Cell]) -> Set<Point> {
		Set(board.filter { $0.value.value != nil && validDigits.contains($0.value.value!) }.map { $0.key })
	}
}

class Unique: Constraint {
	var name: String
	var group: Set<Point>

	init(name: String, group: Set<Point>) {
		self.name = name
		self.group = group
	}

	func valid(board: [Point: Cell]) -> Set<Point> {
		var out: Set<Point> = []
		var found: [Int: Point] = [:]
		for member in group {
			if board[member]!.value == nil {
				continue
			}
			let value = board[member]!.value!
			// if the value has already been seen, add both to the out set and continue
			if found[value] == nil {
				found[value] = member
				continue
			}

			out.insert(member)
			out.insert(found[value]!)
		}
		return out
	}
}

class Sum: Constraint {
	var name: String
	var group: Set<Point>
	var sum: Int

	init(name: String, group: Set<Point>, sum: Int) {
		self.name = name
		self.group = group
		self.sum = sum
	}

	// the whole region is returned if the sum fails at any point
	func valid(board: [Point: Cell]) -> Set<Point> {
		let realSum = group.reduce(into: 0) { partialResult, p in
			partialResult += board[p]?.value ?? 0
		}
		if sum == realSum {
			return []
		}
		return group
	}
}

class V: Constraint {
	var name: String
	var group: Set<Point>

	init(name: String, group: Set<Point>) {
		if group.count != 2 {
			print("V constraint requires exactly two points")
		}
		self.name = name
		self.group = group
	}

	func valid(board: [Point: Cell]) -> Set<Point> {
		let groupSum = group.reduce(into: 0) { partialResult, p in
			partialResult += board[p]?.value ?? 0
		}
		if groupSum == 5 {
			return []
		}
		return group
	}
}

class X: Constraint {
	var name: String
	var group: Set<Point>

	init(name: String, group: Set<Point>) {
		if group.count != 2 {
			print("X constraint requires exactly two points")
		}
		self.name = name
		self.group = group
	}

	func valid(board: [Point: Cell]) -> Set<Point> {
		let groupSum = group.reduce(into: 0) { partialResult, p in
			partialResult += board[p]?.value ?? 0
		}
		if groupSum == 10 {
			return []
		}
		return group
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

protocol ConstraintGenerator: Hashable {
	var tags: Set<Tag> { get }
	func rawConstraints() -> [Constraint]
}

struct VConstraint: ConstraintGenerator {
	var id: String
	var group: [Point]
	var tags: Set<Tag> = [.V, .Sum]

	func rawConstraints() -> [Constraint] {
		[V(name: "V Constraint (\(id))", group: Set(group))]
	}
}

struct XConstraint: ConstraintGenerator {
	var id: String
	var group: [Point]
	var tags: Set<Tag> = [.X, .Sum]

	func rawConstraints() -> [Constraint] {
		[X(name: "X Constraint (\(id))", group: Set(group))]
	}
}

struct KillerCageConstraint: ConstraintGenerator {
	var id: String
	var sumTo: Int
	var group: Set<Point>
	var tags: Set<Tag> = [.KillerCage, .Unique, .Sum]

	func rawConstraints() -> [Constraint] {
		[
			Unique(name: "Killer Cage (\(id)) uniqueness", group: group),
			Sum(name: "Killer Cage (\(id)) sums to \(sumTo)", group: group, sum: sumTo),
		]
	}
}

struct UniqueRows: ConstraintGenerator {
	var rows: Int
	var cols: Int
	let tags: Set<Tag> = [.Row, .Unique]

	func rawConstraints() -> [Constraint] {
		(0 ..< rows).map { row in Unique(name: "Unique in row \(row)", group: Set((0 ..< cols).map { col in Point(row: row, col: col) })) }
	}
}

struct UniqueColumns: ConstraintGenerator {
	var rows: Int
	var cols: Int
	let tags: Set<Tag> = [.Column, .Unique]

	func rawConstraints() -> [Constraint] {
		(0 ..< cols).map { col in Unique(name: "Unique in column \(col)", group: Set((0 ..< rows).map { row in Point(row: row, col: col) })) }
	}
}

struct UniqueRegions: ConstraintGenerator {
	var layout: [[String: Int]]
	var regions: Int
	let tags: Set<Tag> = [.Region, .Unique]

	func rawConstraints() -> [Constraint] {
		(0 ..< regions).map { region in
			Unique(
				name: "Unique in region \(region)",
				group: Set(
					layout.filter { entry in entry["region"]! == region }
						.map { entry in Point(row: entry["row"]!, col: entry["col"]!) }
				)
			)
		}
	}
}

struct ValidDigits: ConstraintGenerator {
	var validDigits: Set<Int>
	let tags: Set<Tag> = [.Digits]

	func rawConstraints() -> [Constraint] {
		[ValidDigit(name: "Valid digits in puzzle", validDigits: validDigits)]
	}
}
