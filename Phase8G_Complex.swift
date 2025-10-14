import Foundation

// Minimal Complex type for Phase8GDemo target isolation.
// This avoids pulling the broader Phase6 environment to prevent type name collisions.
public struct Complex: Sendable, Codable, Equatable {
    public let real: Double
    public let imaginary: Double

    public init(real: Double, imaginary: Double) {
        self.real = real
        self.imaginary = imaginary
    }

    public static func + (lhs: Complex, rhs: Complex) -> Complex {
        Complex(real: lhs.real + rhs.real, imaginary: lhs.imaginary + rhs.imaginary)
    }

    public static func * (lhs: Complex, rhs: Complex) -> Complex {
        Complex(
            real: lhs.real * rhs.real - lhs.imaginary * rhs.imaginary,
            imaginary: lhs.real * rhs.imaginary + lhs.imaginary * rhs.real
        )
    }

    public var magnitude: Double { sqrt(real * real + imaginary * imaginary) }
    public var phase: Double { atan2(imaginary, real) }
}

// For this demo target, use Complex directly; other files may refer to ComplexNumber via a local alias.
