//
//  RealGames.swift
//  VariantSudoku
//
//  Created by chuck ha on 1/28/24.
//

/// introduction to Kropki Dots: https://sudokupad.app/z58l737mye
func kropkiIntro() -> Game {
	let layout: [[String: Int]] = [
		c(0, 0, 0), c(0, 1, 0), c(0, 2, 1), c(0, 3, 1),
		c(1, 0, 0), c(1, 1, 0), c(1, 2, 1), c(1, 3, 1),
		c(2, 0, 2), c(2, 1, 2), c(2, 2, 3), c(2, 3, 3),
		c(3, 0, 2), c(3, 1, 2), c(3, 2, 3), c(3, 3, 3),
	]
	let (height, width, regions) = dims(layout)
	let constraintGenerators: [any ConstraintGenerator] = [
		ValidDigits(validDigits: Set(1 ... 4)),
		UniqueRows(rows: height, cols: width),
		UniqueColumns(rows: height, cols: width),
		UniqueRegions(layout: layout, regions: regions),
		WhiteKropkiDot(id: "1", group: [Point(0, 1), Point(1, 1)]),
		WhiteKropkiDot(id: "2", group: [Point(2, 1), Point(2, 2)]),
		WhiteKropkiDot(id: "3", group: [Point(3, 2), Point(3, 3)]),
		BlackKropkiDot(id: "1", group: [Point(1, 2), Point(1, 3)]),
		BlackKropkiDot(id: "2", group: [Point(2, 0), Point(3, 0)]),
	]
	let b = Board(cells: layoutToSudoku(layout), height: height, width: width)
	return Game(board: b, cgs: constraintGenerators)
}

/// intro to XV: https://sudokupad.app/vzzyz8knam
func xvIntro() -> Game {
	let layout: [[String: Int]] = [
		c(0, 0, 0), c(0, 1, 0), c(0, 2, 0), c(0, 3, 1), c(0, 4, 1), c(0, 5, 1, 3),
		c(1, 0, 0), c(1, 1, 0), c(1, 2, 0), c(1, 3, 1), c(1, 4, 1), c(1, 5, 1),
		c(2, 0, 2), c(2, 1, 2), c(2, 2, 2), c(2, 3, 3), c(2, 4, 3), c(2, 5, 3),
		c(3, 0, 2), c(3, 1, 2), c(3, 2, 2), c(3, 3, 3), c(3, 4, 3), c(3, 5, 3),
		c(4, 0, 4), c(4, 1, 4), c(4, 2, 4), c(4, 3, 5), c(4, 4, 5), c(4, 5, 5),
		c(5, 0, 4), c(5, 1, 4), c(5, 2, 4), c(5, 3, 5), c(5, 4, 5), c(5, 5, 5),
	]
	let (height, width, regions) = dims(layout)
	let constraintGenerators: [any ConstraintGenerator] = [
		ValidDigits(validDigits: Set(1 ... 6)),
		UniqueRows(rows: height, cols: width),
		UniqueColumns(rows: height, cols: width),
		UniqueRegions(layout: layout, regions: regions),
		XVConstraint(id: "1", group: [Point(0, 0), Point(1, 0)], type: .V),
		XVConstraint(id: "2", group: [Point(1, 3), Point(2, 3)], type: .V),
		XVConstraint(id: "3", group: [Point(3, 0), Point(3, 1)], type: .V),
		XVConstraint(id: "4", group: [Point(3, 2), Point(4, 2)], type: .V),
		XVConstraint(id: "5", group: [Point(5, 0), Point(5, 1)], type: .V),
		XVConstraint(id: "1", group: [Point(2, 0), Point(3, 0)], type: .X),
		XVConstraint(id: "2", group: [Point(1, 5), Point(2, 5)], type: .X),
		XVConstraint(id: "3", group: [Point(3, 3), Point(4, 3)], type: .X),
	]
	let b = Board(cells: layoutToSudoku(layout), height: height, width: width)
	return Game(board: b, cgs: constraintGenerators)
}

/// intro to killer cages: https://sudokupad.app/u1gswfvw2x
func killerCageIntro() -> Game {
	let layout: [[String: Int]] = [
		c(0, 0, 0), c(0, 1, 0), c(0, 2, 1), c(0, 3, 1),
		c(1, 0, 0), c(1, 1, 0), c(1, 2, 1), c(1, 3, 1),
		c(2, 0, 2), c(2, 1, 2), c(2, 2, 3), c(2, 3, 3),
		c(3, 0, 2), c(3, 1, 2), c(3, 2, 3), c(3, 3, 3),
	]
	let (height, width, regions) = dims(layout)
	let killerCageGroup1 = Set([Point(row: 0, col: 0), Point(row: 0, col: 1)])
	let killerCageGroup2 = Set([Point(row: 1, col: 0), Point(row: 1, col: 1), Point(row: 2, col: 1)])
	let killerCageGroup3 = Set([Point(row: 1, col: 3), Point(row: 2, col: 3)])
	let littleKillerCage = [Point(1, 3), Point(2, 2), Point(3, 1)]
	let constraintGenerators: [any ConstraintGenerator] = [
		ValidDigits(validDigits: Set(1 ... 4)),
		UniqueRows(rows: height, cols: width),
		UniqueColumns(rows: height, cols: width),
		UniqueRegions(layout: layout, regions: regions),
		KillerCageConstraint(id: "1", sumTo: 5, group: killerCageGroup1),
		KillerCageConstraint(id: "2", sumTo: 8, group: killerCageGroup2),
		KillerCageConstraint(id: "3", sumTo: 4, group: killerCageGroup3),
		LittleKillerConstraint(id: "1", group: littleKillerCage, sum: 8),
	]
	let b = Board(cells: layoutToSudoku(layout), height: height, width: width)
	return Game(board: b, cgs: constraintGenerators)
}

func c(_ row: Int, _ col: Int, _ region: Int, _ given: Int? = nil) -> [String: Int] {
	var basic = ["row": row, "col": col, "region": region]
	if let g = given {
		basic["given"] = g
	}
	return basic
}

// dims returns the height, width and number of regions
// note: because this is a count of objects, it's indexed at 1 hence the +1
// these values are suitable for 0..<x ranges
func dims(_ dic: [[String: Int]]) -> (Int, Int, Int) {
	var height: Int = -9999
	var width: Int = -9999
	var region: Int = -999
	for entry in dic {
		for (k, v) in entry {
			if k == "col" {
				if v > width {
					width = v
				}
			}
			if k == "row" {
				if v > height {
					height = v
				}
			}
			if k == "region" {
				if v > region {
					region = v
				}
			}
		}
	}
	return (height + 1, width + 1, region + 1)
}

func layoutToSudoku(_ dic: [[String: Int]]) -> [Point: Cell] {
	let cells = dic.map { entry -> Cell in
		Cell(point: Point(row: entry["row"]!, col: entry["col"]!), region: entry["region"]!, given: entry["given"])
	}
	let (height, width, _) = dims(dic)
	var sudokuCells: [Point: Cell] = [:]
	for row in 0 ..< height {
		for col in 0 ..< width {
			let p = Point(row: row, col: col)
			sudokuCells[p] = Cell(point: p, region: 0)
		}
	}
	for cell in cells {
		sudokuCells[cell.point] = cell
	}
	return sudokuCells
}
