func fmtFixedLen(_ name: String, length: Int = 12) -> String {
  if name.count <= length {
    return name.padding(toLength: length, withPad: " ", startingAt: 0)
  } else {
    let index = name.index(name.startIndex, offsetBy: length - 2)
    return String(name[..<index]) + ".."
  }
}
