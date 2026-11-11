import Foundation

/// Port of the Dart VM's `Random(seed)` (multiply-with-carry generator with a
/// Thomas Wang seed mix), so seeded plate layouts and answer orders follow the
/// same sequence as the Flutter app.
struct DartRandom: RandomNumberGenerator {
    private var lo: UInt64
    private var hi: UInt64

    init(seed: Int) {
        var s = UInt64(bitPattern: Int64(seed))
        s = (~s) &+ (s << 21)
        s = s ^ (s >> 24)
        s = (s &+ (s << 3)) &+ (s << 8)
        s = s ^ (s >> 14)
        s = (s &+ (s << 2)) &+ (s << 4)
        s = s ^ (s >> 28)
        s = s &+ (s << 31)
        if s == 0 { s = 0x5A17 }
        lo = s & 0xFFFF_FFFF
        hi = s >> 32
        // "Crank a couple of times to distribute the seed bits a bit further."
        for _ in 0..<4 { nextState() }
    }

    private mutating func nextState() {
        let a: UInt64 = 0xFFFF_DA61
        let state = a &* lo &+ hi
        lo = state & 0xFFFF_FFFF
        hi = (state >> 32) & 0xFFFF_FFFF
    }

    /// Dart `nextInt(max)`.
    mutating func nextInt(_ max: Int) -> Int {
        precondition(max > 0 && max <= 1 << 32)
        let m = UInt64(max)
        if m & (~m &+ 1) == m { // power of two
            nextState()
            return Int(lo & (m - 1))
        }
        var rnd32: UInt64
        var result: UInt64
        repeat {
            nextState()
            rnd32 = lo
            result = rnd32 % m
        } while rnd32 - result + m > (1 << 32)
        return Int(result)
    }

    /// Dart `nextDouble()`.
    mutating func nextDouble() -> Double {
        let high = Double(nextInt(1 << 26))
        let low = Double(nextInt(1 << 27))
        return (high * Double(1 << 27) + low) / Double(UInt64(1) << 53)
    }

    // RandomNumberGenerator conformance (not used for Dart-compatible paths).
    mutating func next() -> UInt64 {
        nextState()
        let a = lo
        nextState()
        return (a << 32) | lo
    }
}

extension Array {
    /// Dart `List.shuffle(random)`.
    mutating func dartShuffle(using random: inout DartRandom) {
        var length = count
        while length > 1 {
            let pos = random.nextInt(length)
            length -= 1
            swapAt(length, pos)
        }
    }
}
