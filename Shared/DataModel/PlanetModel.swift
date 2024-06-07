//
//  PlanetModel.swift
//  Chinendar
//
//  Created by Leo Liu on 10/7/21.
//

import Foundation

struct SolarSystem {
    private static let earthRadiiInAU: Double = 1 / 23455
    static let aeroAdj = 29 / 60 / 180 * Double.pi

    struct SphericalLoc {
        let ra: Double
        let decl: Double
        let r: Double
    }

    struct Planet {
        let loc: SphericalLoc
        let diameter: Double
    }

    struct Planets {
        let sun: Planet
        let moon: Planet
        let mercury: Planet
        let venus: Planet
        let mars: Planet
        let jupiter: Planet
        let saturn: Planet
    }

    enum Targets {
        case sun, sunMoon, all
        var list: [Int] {
            switch self {
            case .sun: [0]
            case .sunMoon: [0, 1]
            case .all: [0, 1, 2, 3, 4, 5, 6]
            }
        }
    }

    let time: Date
    let loc: GeoLocation?
    let planets: Planets
    let localSiderialTime: Double? // in radian

    init(time: Date, loc: GeoLocation?, targets: Targets) {
        self.time = time
        self.loc = loc

        let (lst, ra, dec, r, d) = Self.planetPos(T: Self.fromJD2000(date: time), Loc: loc, selection: targets.list)
        localSiderialTime = lst
        planets = .init(sun: .init(loc: .init(ra: ra[0], decl: dec[0], r: r[0]), diameter: d[0]),
                        moon: .init(loc: .init(ra: ra[1], decl: dec[1], r: r[1]), diameter: d[1]),
                         mercury: .init(loc: .init(ra: ra[2], decl: dec[2], r: r[2]), diameter: d[2]),
                         venus: .init(loc: .init(ra: ra[3], decl: dec[3], r: r[3]), diameter: d[3]),
                         mars: .init(loc: .init(ra: ra[4], decl: dec[4], r: r[4]), diameter: d[4]),
                         jupiter: .init(loc: .init(ra: ra[5], decl: dec[5], r: r[5]), diameter: d[5]),
                         saturn: .init(loc: .init(ra: ra[6], decl: dec[6], r: r[6]), diameter: d[6]))
    }

    static func normalize(radian: Double) -> Double {
        let arcLength = radian / Double.pi
        let normalized = (arcLength + 1) %% 2 - 1
        return normalized * Double.pi
    }
}

private extension SolarSystem {
    private static func planetPos(T: Double, Loc: GeoLocation?, selection: [Int]) -> (lst: Double?, ra: [Double], dec: [Double], r: [Double], d: [Double]) {
        // https://www.stjarnhimlen.se/comp/ppcomp.html

        // [Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn]
        let N0 = [0, 125.1228, 48.3313, 76.6799, 49.5574, 100.4542, 113.6634]
        let Ndot = [0, -0.0529538083, 3.24587e-5, 2.46590e-5, 2.11081e-5, 2.76854e-5, 2.38980e-5]
        let i0 = [0, 5.1454, 7.0047, 3.3946, 1.8497, 1.3030, 2.4886]
        let idot = [0, 0, 5.00e-8, 2.75e-8, -1.78e-8, -1.557e-7, -1.081e-7]
        let w0 = [282.9404, 318.0634, 29.1241, 54.8910, 286.5016, 273.8777, 339.3939]
        let wdot = [4.70935e-5, 0.1643573223, 1.01444e-5, 1.38374e-5, 2.92961e-5, 1.64505e-5, 2.97661e-5]
        let a = [1, 60.2666, 0.387098, 0.723330, 1.523688, 5.20256, 9.55475]
        let e0 = [0.016709, 0.054900, 0.205635, 0.006773, 0.093405, 0.048498, 0.055546]
        let edot = [-1.151e-9, 0, 5.59e-10, -1.302e-9, 2.516e-9, 4.469e-9, -9.499e-9]
        let M0 = [356.0470, 115.3654, 168.6562, 48.0052, 18.6021, 19.8950, 316.9670]
        let Mdot = [0.9856002585, 13.0649929509, 4.0923344368, 1.6021302244, 0.5240207766, 0.0830853001, 0.0334442282]
        let d0 = [0.533128, 32.228, 0.00187, 0.004700, 0.00259, 0.05306, 0.0439]

        var N: [Double] = .init(repeating: 0, count: 7) // longitude of the ascending node
        var I: [Double] = .init(repeating: 0, count: 7) // inclination to the ecliptic (plane of the Earth's orbit)
        var w: [Double] = .init(repeating: 0, count: 7) // argument of perihelion
        var e: [Double] = .init(repeating: 0, count: 7) // eccentricity (0=circle, 0-1=ellipse, 1=parabola)
        var M: [Double] = .init(repeating: 0, count: 7) // mean anomaly (0 at perihelion; increases uniformly with time)
        var E: [Double] = .init(repeating: 0, count: 7) // eccentric anomaly
        var xv: [Double] = .init(repeating: 0, count: 7)
        var yv: [Double] = .init(repeating: 0, count: 7)
        var v: [Double] = .init(repeating: 0, count: 7)
        var r: [Double] = .init(repeating: 0, count: 7)

        let ecl = (23.4393 - 3.563e-7 * T) * Double.pi / 180

        for i in selection {
            N[i] = (N0[i] + T * Ndot[i]) * Double.pi / 180 // radian
            I[i] = (i0[i] + T * idot[i]) * Double.pi / 180 // radian
            w[i] = (w0[i] + T * wdot[i]) * Double.pi / 180 // radian
            e[i] = e0[i] + T * edot[i]
            M[i] = (M0[i] + T * Mdot[i]) * Double.pi / 180 // radian

            // First, compute the eccentric anomaly E from the mean anomaly M and from the eccentricity e
            E[i] = M[i] + e[i] * sin(M[i]) * (1 + e[i] * cos(M[i])) // radian
            var iterE = E[i] - (E[i] - e[i] * sin(E[i]) - M[i]) / (1 - e[i] * cos(E[i]))
            while abs(E[i] - iterE) > 1e-5 {
                E[i] = iterE
                iterE = E[i] - (E[i] - e[i] * sin(E[i]) - M[i]) / (1 - e[i] * cos(E[i]))
            }

            // Then compute the Sun's distance r and its true anomaly v from:
            xv[i] = a[i] * (cos(E[i]) - e[i])
            yv[i] = a[i] * sqrt(1 - e[i] * e[i]) * sin(E[i])
            v[i] = atan2(yv[i], xv[i])
            r[i] = sqrt(xv[i] * xv[i] + yv[i] * yv[i])
        }

        var xh: [Double] = .init(repeating: 0, count: 7)
        var yh: [Double] = .init(repeating: 0, count: 7)
        var zh: [Double] = .init(repeating: 0, count: 7)
        var lonecl: [Double] = .init(repeating: 0, count: 7)
        var latecl: [Double] = .init(repeating: 0, count: 7)

        for i in selection {
            // Compute the planet's position in 3-dimensional space:
            xh[i] = r[i] * (cos(N[i]) * cos(v[i] + w[i]) - sin(N[i]) * sin(v[i] + w[i]) * cos(I[i]))
            yh[i] = r[i] * (sin(N[i]) * cos(v[i] + w[i]) + cos(N[i]) * sin(v[i] + w[i]) * cos(I[i]))
            zh[i] = r[i] * (sin(v[i] + w[i]) * sin(I[i]))

            // For the Moon, this is the geocentric (Earth-centered) position in the ecliptic coordinate system. For the planets, this is the heliocentric (Sun-centered) position, also in the ecliptic coordinate system.
            lonecl[i] = atan2(yh[i], xh[i])
            latecl[i] = atan2(zh[i], sqrt(xh[i] * xh[i] + yh[i] * yh[i]))
        }

        // Moon perturbations
        let Ls = M[0] + w[0] // Mean Longitude of the Sun  (Ns=0)
        if selection.contains(1) {
            let Lm = M[1] + w[1] + N[1] // Mean longitude of the Moon
            let D = Lm - Ls // Mean elongation of the Moon
            let F = Lm - N[1] // Argument of latitude for the Moon
            var lonAdj = 1.274 * sin(M[1] - 2 * D) // the Evection
            lonAdj -= 1.274 * sin(M[1] - 2 * D) // the Evection
            lonAdj += 0.658 * sin(2 * D) // the Variation
            lonAdj -= 0.186 * sin(M[0]) // the Yearly Equation
            lonAdj -= 0.059 * sin(2 * M[1] - 2 * D)
            lonAdj -= 0.057 * sin(M[1] - 2 * D + M[0])
            lonAdj += 0.053 * sin(M[1] + 2 * D)
            lonAdj += 0.046 * sin(2 * D - M[0])
            lonAdj += 0.041 * sin(M[1] - M[0])
            lonAdj -= 0.035 * sin(D) // the Parallactic Equation
            lonAdj -= 0.031 * sin(M[1] + M[0])
            lonAdj -= 0.015 * sin(2 * F - 2 * D)
            lonAdj += 0.011 * sin(M[1] - 4 * D)
            var latAdj = -0.173 * sin(F - 2 * D)
            latAdj -= 0.055 * sin(M[1] - F - 2 * D)
            latAdj -= 0.046 * sin(M[1] + F - 2 * D)
            latAdj += 0.033 * sin(F + 2 * D)
            latAdj += 0.017 * sin(2 * M[1] + F)
            lonecl[1] += lonAdj * Double.pi / 180
            latecl[1] += latAdj * Double.pi / 180
            r[1] -= 0.58 * cos(M[1] - 2 * D)
            r[1] -= 0.46 * cos(2 * D)
        }

        // Jupiter perterbations
        if selection.contains([5, 6]) {
            var lonAdjJ = -0.332 * sin(2 * M[5] - 5 * M[6] - 67.6 / 180 * Double.pi)
            lonAdjJ -= 0.056 * sin(2 * M[5] - 2 * M[6] + 21 / 180 * Double.pi)
            lonAdjJ += 0.042 * sin(3 * M[5] - 5 * M[6] + 21 / 180 * Double.pi)
            lonAdjJ -= 0.036 * sin(M[5] - 2 * M[6])
            lonAdjJ += 0.022 * cos(M[5] - M[6])
            lonAdjJ += 0.023 * sin(2 * M[5] - 3 * M[6] + 52 / 180 * Double.pi)
            lonAdjJ -= 0.016 * sin(M[5] - 5 * M[6] - 69 / 180 * Double.pi)
            var lonAdjS = 0.812 * sin(2 * M[5] - 5 * M[6] - 67.6 / 180 * Double.pi)
            lonAdjS -= 0.229 * cos(2 * M[5] - 4 * M[6] - 2 / 180 * Double.pi)
            lonAdjS += 0.119 * sin(M[5] - 2 * M[6] - 3 / 180 * Double.pi)
            lonAdjS += 0.046 * sin(2 * M[5] - 6 * M[6] - 69 / 180 * Double.pi)
            lonAdjS += 0.014 * sin(M[5] - 3 * M[6] + 32 / 180 * Double.pi)
            var latAdjS = -0.020 * cos(2 * M[5] - 4 * M[6] - 2 / 180 * Double.pi)
            latAdjS += 0.018 * sin(2 * M[5] - 6 * M[6] - 49 / 180 * Double.pi)
            lonecl[5] += lonAdjJ * Double.pi / 180
            lonecl[6] += lonAdjS * Double.pi / 180
            latecl[6] += latAdjS * Double.pi / 180
        }

        var xg: [Double] = .init(repeating: 0, count: 7)
        var yg: [Double] = .init(repeating: 0, count: 7)
        var zg: [Double] = .init(repeating: 0, count: 7)
        var xe: [Double] = .init(repeating: 0, count: 7)
        var ye: [Double] = .init(repeating: 0, count: 7)
        var ze: [Double] = .init(repeating: 0, count: 7)
        var ra: [Double] = .init(repeating: 0, count: 7)
        var dec: [Double] = .init(repeating: 0, count: 7)
        var rho: [Double] = .init(repeating: 0, count: 7)

        for i in selection {
            xh[i] = r[i] * cos(lonecl[i]) * cos(latecl[i])
            yh[i] = r[i] * sin(lonecl[i]) * cos(latecl[i])
            zh[i] = r[i] * sin(latecl[i])

            // Earth centered
            if i > 1 {
                xg[i] = xh[i] + xh[0]
                yg[i] = yh[i] + yh[0]
                zg[i] = zh[i] + zh[0]
            } else {
                xg[i] = xh[i]
                yg[i] = yh[i]
                zg[i] = zh[i]
            }

            // Equatorial
            xe[i] = xg[i]
            ye[i] = yg[i] * cos(ecl) - zg[i] * sin(ecl)
            ze[i] = yg[i] * sin(ecl) + zg[i] * cos(ecl)

            ra[i] = atan2(ye[i], xe[i])
            dec[i] = atan2(ze[i], sqrt(xe[i] * xe[i] + ye[i] * ye[i]))
            rho[i] = sqrt(xe[i] * xe[i] + ye[i] * ye[i] + ze[i] * ze[i])
        }

        var lst: Double?
        if let location = Loc {
            let gclat = (location.lat - 0.1924 * sin(2 * location.lat * Double.pi / 180)) * Double.pi / 180
            let rEarth = 0.99883 + 0.00167 * cos(2 * location.lat * Double.pi / 180)
            let gmst0 = Ls + Double.pi
            lst = gmst0 + (T - floor(T)) * 2 * Double.pi + location.lon * Double.pi / 180

            // Topocentric correction for moon
            if selection.contains(1) {
                let ha = lst! - ra[1]
                let mpar = asin(1 / (rho[1]))
                let g = atan(tan(gclat) / cos(ha))
                let topRa = ra[1] - mpar * rEarth * cos(gclat) * sin(ha) / cos(dec[1])
                let topDec = if abs(g) > 1e-5 {
                    dec[1] - mpar * rEarth * sin(gclat) * sin(g - dec[1]) / sin(g)
                } else {
                    dec[1] - mpar * rEarth * sin(-dec[1]) * cos(ha)
                }
                ra[1] = topRa
                dec[1] = topDec
            }
        }

        var d: [Double] = .init(repeating: 0, count: 7)
        for i in selection {
            ra[i] = normalize(radian: ra[i])
            dec[i] = normalize(radian: dec[i])
            d[i] = (d0[i] * Double.pi / 180) / rho[i]
        }
        rho[1] *= earthRadiiInAU

        return (lst: lst, ra: ra, dec: dec, r: rho, d: d)
    }

    private static func fromJD2000(date: Date) -> Double {
        let dateComponents = Calendar.utcCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)
        let (year, month, day, hour, minute, second, nanosecond) = (dateComponents.year!, dateComponents.month!, dateComponents.day!, dateComponents.hour!, dateComponents.minute!, dateComponents.second!, dateComponents.nanosecond!)
        let dayNumber = 367 * year - 7 * (year + (month + 9) / 12) / 4 - 3 * ((year + (month - 9) / 7) / 100 + 1) / 4 + 275 * month / 9 + day - 730515
        let timeComponent = Double(hour) + Double(minute) / 60 + (Double(second) + Double(nanosecond) / 1e9) / 3600
        return Double(dayNumber) + timeComponent / 24
    }
}

enum RiseSetType {
    case sunrise, sunset, moonrise, moonset
}
enum MeridianType {
    case noon, midnight, highMoon, lowMoon
}

func riseSetTime(around time: Date, at loc: GeoLocation, type: RiseSetType, iteration: Int = 0) -> Date? {
    let solarSystem: SolarSystem
    let planet: SolarSystem.Planet
    switch type {
    case .sunrise, .sunset:
        solarSystem = SolarSystem(time: time, loc: loc, targets: .sun)
        planet = solarSystem.planets.sun
    case .moonrise, .moonset:
        solarSystem = SolarSystem(time: time, loc: loc, targets: .sunMoon)
        planet = solarSystem.planets.moon
    }
    let timeUntilNoon = SolarSystem.normalize(radian: planet.loc.ra - solarSystem.localSiderialTime!)
    let solarHeight = -planet.diameter / 2 - SolarSystem.aeroAdj
    let localHourAngle = (sin(solarHeight) - sin(loc.lat / 180 * Double.pi) * sin(planet.loc.decl)) / (cos(loc.lat / 180 * Double.pi) * cos(planet.loc.decl))

    if abs(localHourAngle) < 1 || iteration < 3 {
        let netTime = switch type {
        case .sunrise, .moonrise:
            timeUntilNoon - acos(min(1, max(-1, localHourAngle)))
        case .sunset, .moonset:
            timeUntilNoon + acos(min(1, max(-1, localHourAngle)))
        }
        let dTime = netTime / Double.pi * 43082.04
        if abs(dTime) < 14.4 && abs(localHourAngle) < 1 {
            return time
        } else {
            return riseSetTime(around: time + dTime, at: loc, type: type, iteration: iteration + 1)
        }
    } else {
        return nil
    }
}

func meridianTime(around time: Date, at loc: GeoLocation, type: MeridianType, iteration: Int = 0) -> Date? {
    let solarSystem: SolarSystem
    let planet: SolarSystem.Planet
    switch type {
    case .noon, .midnight:
        solarSystem = SolarSystem(time: time, loc: loc, targets: .sun)
        planet = solarSystem.planets.sun
    case .highMoon, .lowMoon:
        solarSystem = SolarSystem(time: time, loc: loc, targets: .sunMoon)
        planet = solarSystem.planets.moon
    }
    let offset = switch type {
    case .noon, .highMoon:
        0.0
    case .midnight, .lowMoon:
        Double.pi
    }
    let timeUntilNoon = SolarSystem.normalize(radian: planet.loc.ra - solarSystem.localSiderialTime! + offset)

    let dTime = timeUntilNoon / Double.pi * 43082.04
    if abs(dTime) < 14.4 {
        let latInRadian = loc.lat * Double.pi / 180
        let localHourAngle = solarSystem.localSiderialTime! - planet.loc.ra
        let solarHeightSin = sin(latInRadian) * sin(planet.loc.decl) + cos(latInRadian) * cos(planet.loc.decl) * cos(localHourAngle)
        let solarHeight = asin(solarHeightSin)
        let solarHeightMin = -planet.diameter / 2 - SolarSystem.aeroAdj
        switch type {
        case .noon, .highMoon:
            if solarHeight >= solarHeightMin {
                return time
            } else {
                return nil
            }
        case .midnight, .lowMoon:
            if solarHeight < solarHeightMin {
                return time
            } else {
                return nil
            }
        }
    } else {
        return meridianTime(around: time + dTime, at: loc, type: type, iteration: iteration + 1)
    }
}

func dayStart(around time: Date, at loc: GeoLocation, iteration: Int = 0) -> Date {
    let solarSystem = SolarSystem(time: time, loc: loc, targets: .sun)
    let planet = solarSystem.planets.sun
    let offset = Double.pi
    let timeUntilMidnight = SolarSystem.normalize(radian: planet.loc.ra - solarSystem.localSiderialTime! + offset)

    let dTime = timeUntilMidnight / Double.pi * 43082.04
    if abs(dTime) < 1 {
        return time
    } else {
        return dayStart(around: time + dTime, at: loc, iteration: iteration + 1)
    }
}
