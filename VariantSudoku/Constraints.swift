//
//  Constraints.swift
//  VariantSudoku
//
//  Created by chuck ha on 2/4/24.
//

protocol ConstraintGenerator: Hashable {
	var tags: Set<Tag> { get }
	func rawConstraints() -> [Constraint]
}

enum XVType {
	case X
	case V
}

struct XVConstraint: ConstraintGenerator {
	var id: String
	var group: [Point]
	var tags: Set<Tag> = [.SumPair, .XV]
	var type: XVType

	func rawConstraints() -> [Constraint] {
		[Sum(name: "\(name()) Constraint \(id)", group: Set(group), tags: tags, sum: sumTo())]
	}

	func sumTo() -> Int {
		switch type {
		case .X: 10
		case .V: 5
		}
	}

	func name() -> String {
		switch type {
		case .V: return "V"
		case .X: return "X"
		}
	}

	func leftRight() -> Bool {
		return group[0].row == group[1].row
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
			Sum(name: "Killer Cage (\(id)) sums to \(sumTo)", group: group, tags: tags, sum: sumTo),
		]
	}
}

struct UniqueRows: ConstraintGenerator {
	var rows: Int
	var cols: Int
	let tags: Set<Tag> = [.Row, .Unique, .Normal]

	func rawConstraints() -> [Constraint] {
		(0 ..< rows).map { row in Unique(name: "Unique in row \(row)", group: Set((0 ..< cols).map { col in Point(row: row, col: col) }), tags: tags) }
	}
}

struct UniqueColumns: ConstraintGenerator {
	var rows: Int
	var cols: Int
	let tags: Set<Tag> = [.Column, .Unique, .Normal]

	func rawConstraints() -> [Constraint] {
		(0 ..< cols).map { col in Unique(name: "Unique in column \(col)", group: Set((0 ..< rows).map { row in Point(row: row, col: col) }), tags: tags) }
	}
}

struct UniqueRegions: ConstraintGenerator {
	var layout: [[String: Int]]
	var regions: Int
	let tags: Set<Tag> = [.Region, .Unique, .Normal]

	func rawConstraints() -> [Constraint] {
		(0 ..< regions).map { region in
			Unique(
				name: "Unique in region \(region)",
				group: Set(
					layout.filter { entry in entry["region"]! == region }
						.map { entry in Point(row: entry["row"]!, col: entry["col"]!) }
				),
				tags: tags
			)
		}
	}
}

struct ValidDigits: ConstraintGenerator {
	var validDigits: Set<Int>
	let tags: Set<Tag> = [.Digits]

	func rawConstraints() -> [Constraint] {
		[ValidDigit(name: "Valid digits in puzzle", validDigits: validDigits, tags: tags)]
	}
}

protocol Constraint {
	var name: String { get set }
	var group: Set<Point> { get set }
	var tags: Set<Tag> { get set }

	func valid(board: [Point: Cell]) -> Set<Point>
}

class ValidDigit: Constraint {
	var name: String
	var group: Set<Point> = []
	var tags: Set<Tag>
	let validDigits: Set<Int>

	init(name: String, validDigits: Set<Int>, tags: Set<Tag> = []) {
		self.name = name
		self.validDigits = validDigits
		group = []
		self.tags = tags
	}

	func valid(board: [Point: Cell]) -> Set<Point> {
		Set(board.filter { $0.value.effectiveValue() != nil }.filter { !validDigits.contains($0.value.effectiveValue()!) }.map { $0.key })
	}
}

class Unique: Constraint {
	var name: String
	var group: Set<Point>
	var tags: Set<Tag>

	init(name: String, group: Set<Point>, tags: Set<Tag> = []) {
		self.name = name
		self.group = group
		self.tags = tags
	}

	func valid(board: [Point: Cell]) -> Set<Point> {
		var out: Set<Point> = []
		var found: [Int: Point] = [:]
		for member in group {
			if board[member]!.effectiveValue() == nil {
				continue
			}
			let value = board[member]!.effectiveValue()!
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
	var tags: Set<Tag>
	var sum: Int

	init(name: String, group: Set<Point>, tags: Set<Tag> = [], sum: Int) {
		self.name = name
		self.group = group
		self.sum = sum
		self.tags = tags
	}

	// the whole region is returned if the sum fails at any point
	func valid(board: [Point: Cell]) -> Set<Point> {
		if group.filter({ board[$0]?.effectiveValue() == nil }).count != 0 {
			return []
		}

		let realSum = group.reduce(into: 0) { partialResult, p in
			partialResult += board[p]?.effectiveValue() ?? 0
		}
		if sum == realSum {
			return []
		}
		return group
	}
}
