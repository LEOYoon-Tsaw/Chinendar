//
//  PlanetModel.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 10/7/21.
//

import Foundation

let planetNames = ["辰", "太白", "熒惑", "歲", "填"]

func %<T: BinaryFloatingPoint>(lhs: T, rhs: T) -> T {
    lhs - rhs * floor(lhs / rhs)
}

private struct Matrix {
    var p11 = 0.0, p12 = 0.0, p13 = 0.0, p21 = 0.0, p22 = 0.0, p23 = 0.0, p31 = 0.0, p32 = 0.0, p33 = 0.0
}

private func precessionMatrixVondrak(T: Double) -> Matrix {
    let omega = [0.01559490024120026, 0.0244719973015758, 0.02151775790129995, 0.01169573974755144, 0.02602271819084525, 0.01674533688817117, 0.0397997422384214, 0.02291460724719032, 0.03095165175950535, 0.01427996660722633, 0.03680403764749055, 0.008807750966790847, 0.02007407446383254, 0.0489420883874403, 0.03110487775831478, 0.01994662002279234, 0.04609144151393476, 0.01282282715750936]
    let cPsiA = [-0.1076593062579846, 0.05932495062847037, -0.007703729840835942, 0.01203357586861691, 0.000728786082003343, -6.609012098588148e-05, 0.001888045891520004, 0.009848668946298234, 0.001763501537747769, -0.004347554865592219, -0.004494201976897112, 0.000179723665294558, -0.002897646374457124, 0.0003213481408001133, 0, 0, 0, 0]
    let sPsiA = [-0.01572365411244583, -0.01924576393436911, 0.03441793111567203, -0.009229382101760265, 0.0007099369818066644, 0.00630563269451746, 0.008375146833970948, 0.001453733482001713, -0.005900793277074788, -0.002285254065278213, -0.002141335465978059, -0.0004177599299066708, -0.001494779621447613, -0.002049868015261339, 0, 0, 0, 0]
    let cOmgA = [0.00614611792998422, 0.008253100851149026, -0.01440165141619654, 0.003363590350788535, -7.138615291626988e-05, -0.002504786979418468, -0.00172978832643207, -0.0006280861013429611, 0.001241749955604002, 0.0009224361511874661, 0.0004610771596491818, -0.001613979006196489, 0.0006367428132294327, 0.0004010956619564596, 0, 0, 0, 0]
    let sOmgA = [-0.04155568953790275, 0.0257426196723017, -0.002959273392809311, 0.004475809265755418, 1.822441292043207e-05, -0.0001972760876678778, 0.000389971927172294, 0.003913904086152674, 0.0004058488092230152, -0.001787289168266385, -0.0009302656497305446, -2.067134029104406e-05, -0.0013107116813526, 5.625225752812272e-05, 0, 0, 0, 0]
    let cChiA = [-0.06673908312554792, 0.06550733801292973, -0.007055149797375992, 0.005111848628877972, 0, -0.0005444464620177098, 0.0009830562551572195, 0.009386235733694169, 0, -0.003177877146985308, -0.004324046613805478, 0, 0, -0.001615990759958801, 0.001587849478343136, -0.002398762740975183, 0.002838548328494804, 0.0005357813386138708]
    let sChiA = [-0.01069967856443793, -0.02029794993715239, 0.03266650186037179, -0.0041544791939612, 0, 0.004640389727239152, 0.008287602553739408, 0.0007486759753624905, 0, -0.00118062300801947, -0.001970956729830991, 0, 0, -0.002165451504436122, -0.005086043543188153, -0.001461733557390353, 0.0002004643484864111, 0.000690981600754813]
    
    var psiA = 0.04107992866630529 + T*(0.02444817476355586 + T*(-3.592047589119096e-08 + 1.401111538406559e-12*T))
    var omgA = 0.4086163677095374 + T*(-2.150908863572772e-06 + T*(7.078279744199225e-12 + 7.320686584753994e-13*T))
    var chiA = -9.530113429264049e-05 + T*(3.830798934518299e-07 + T*(7.13645738593237e-11 - 2.957363454768169e-13*T))
    for i in 0..<18 {
        let ang = omega[i]*T
        let cosAng = cos(ang), sinAng = sin(ang)
        psiA += cPsiA[i]*cosAng + sPsiA[i]*sinAng
        omgA += cOmgA[i]*cosAng + sOmgA[i]*sinAng
        chiA += cChiA[i]*cosAng + sChiA[i]*sinAng
    }
    let cEps = 0.9174821430652418, sEps = 0.397776969112606
    let sPsi = sin(psiA), cPsi = cos(psiA)
    let sOmg = sin(omgA), cOmg = cos(omgA)
    let sChi = sin(chiA), cChi = cos(chiA)
    
    var p = Matrix()
    p.p11 = cChi*cPsi + sChi*cOmg*sPsi
    p.p12 = (-cChi*sPsi + sChi*cOmg*cPsi)*cEps + sChi*sOmg*sEps
    p.p13 = (-cChi*sPsi + sChi*cOmg*cPsi)*sEps - sChi*sOmg*cEps
    p.p21 = -sChi*cPsi + cChi*cOmg*sPsi
    p.p22 = (sChi*sPsi + cChi*cOmg*cPsi)*cEps + cChi*sOmg*sEps
    p.p23 = (sChi*sPsi + cChi*cOmg*cPsi)*sEps - cChi*sOmg*cEps
    p.p31 = sOmg*sPsi
    p.p32 = sOmg*cPsi*cEps - cOmg*sEps
    p.p33 = sOmg*cPsi*sEps + cOmg*cEps
    
    return p
}

private func precession_matrix(T0: Double, T: Double) -> Matrix {
    if (T0==0) {
        return precessionMatrixVondrak(T: T)
    } else {
        let p0 = precessionMatrixVondrak(T: T0)
        let p1 = precessionMatrixVondrak(T: T0+T)
        var p = Matrix()
        // Inverse of p0 is the transpose of p0
        p.p11 = p1.p11*p0.p11 + p1.p12*p0.p12 + p1.p13*p0.p13
        p.p12 = p1.p11*p0.p21 + p1.p12*p0.p22 + p1.p13*p0.p23
        p.p13 = p1.p11*p0.p31 + p1.p12*p0.p32 + p1.p13*p0.p33
        p.p21 = p1.p21*p0.p11 + p1.p22*p0.p12 + p1.p23*p0.p13
        p.p22 = p1.p21*p0.p21 + p1.p22*p0.p22 + p1.p23*p0.p23
        p.p23 = p1.p21*p0.p31 + p1.p22*p0.p32 + p1.p23*p0.p33
        p.p31 = p1.p31*p0.p11 + p1.p32*p0.p12 + p1.p33*p0.p13
        p.p32 = p1.p31*p0.p21 + p1.p32*p0.p22 + p1.p33*p0.p23
        p.p33 = p1.p31*p0.p31 + p1.p32*p0.p32 + p1.p33*p0.p33
        return p
    }
}

// Solve the Kepler's equation M =  - e sin E
private func kepler(M: Double, e: Double) -> Double {
    // mean anomaly -> [-pi, pi)
    let n2pi = floor(M / (2.0*Double.pi) + 0.5) * (2.0*Double.pi)
    let Mp = M - n2pi

    // Solve Kepler's equation E - e sin E = M using Newton's iteration method
    var E = Mp // initial guess
    if (e > 0.8) {
        E = Double.pi
    } // need another initial guess for very eccentric orbit
    var E0 = E*1.01
    let tol = 1e-15
    var iter = 0, maxit = 100
    while (abs(E-E0) > tol && iter < maxit) {
        E0 = E
        E = E0 - (E0 - e * sin(E0) - Mp)/(1.0 - e * cos(E0))
        iter += 1
    }
    if (iter==maxit) {
        // Newton's iteration doesn't converge after 100 iterations, use bisection instead.
        iter = 0
        maxit = 60
        if (Mp > 0.0) {
            E0 = 0.0
            E = Double.pi
        } else {
            E = 0.0
            E0 = -Double.pi
        }
        while (E-E0 > tol && iter < maxit) {
            let E1 = 0.5*(E+E0)
            let z = E1 - e * sin(E1) - Mp
            if (z > 0.0) {
                E = E1
            } else {
                E0 = E1
            }
            iter += 1
        }
    }

  return E
}

// Planet positions at T
// The planet data are stored in an array in this order:
// Mercury, Venus, Mars, Jupiter, Saturn
// The second argument, calculate, is a logical
//  vector of length 8, true if the planet position
//  is to be calculated. For example, to calculate
//  the position of Mars only, set calculate to
//  [false,false,false,true,false,false,false,false]
//
// output: Ra's amd Dec's in radians
// For planets whose positions are not calculated, as indicated
// in the variable 'calculate', ra and dec are not defined.
func planetPos(T: Double) -> [Double] {
    let pi2 = 2 * Double.pi;
    // 1/light speed in century/AU
    let f1oc = 1.58125073358306e-07
    let cosEps = cos(eps)
    let sinEps = sin(eps)
        
    // Angles have been converted to radians
    let a0: [Double], adot: [Double], e0: [Double],edot: [Double], I0: [Double], Idot: [Double], L0: [Double], Ldot: [Double], pom0: [Double], pomdot: [Double], Omg0: [Double], Omgdot: [Double]
    let b: [Double], c: [Double], s: [Double], f: [Double]
    if (T > -2 && T < 0.5) {
        // use the parameters for 1800 AD - 2050 AD
        a0 = [1.00000261, 0.38709927, 0.72333566, 1.52371034, 5.202887, 9.53667594]
        adot = [0.00000562, 0.00000037, 0.0000039, 0.00001847, -0.00011607, -0.0012506]
        e0 = [0.01671123, 0.20563593, 0.00677672, 0.09339410, 0.04838624, 0.05386179]
        edot = [-0.00004392, 0.00001906, -0.00004107, 0.00007882, -0.00013253, -0.00050991]
        I0 = [-2.67209908480332e-07, 0.122259947932126, 0.0592482741110957, 0.0322832054248893, 0.0227660215304719, 0.0433887433093108]
        Idot = [-0.000225962193202099, -0.000103803282729438, -1.37689024689833e-05, -0.00014191813200034, -3.20641418200886e-05, 3.3791145114937e-05]
        L0 = [1.75343755707279, 4.40259868429583, 3.17613445608937, -0.0794723815383351, 0.600331137865858, 0.87186603715888]
        Ldot = [628.307577900922, 2608.79030501053, 1021.32854958241, 334.061301681387, 52.966311891386, 21.3365387887055]
        pom0 = [1.79660147404917, 1.35189357642502, 2.29689635603878, -0.41789517122344, 0.257060466847075, 1.61615531016306]
        pomdot = [0.00564218940290684, 0.00280085010386076, 4.68322452858386e-05, 0.00775643308768542, 0.00370929031433238, -0.00731244366619248]
        Omg0 = [0, 0.843530995489199, 1.33831572240834, 0.864977129749742, 1.75360052596996, 1.9837835429754]
        Omgdot = [0, -0.00218760982161663, -0.00484667775462579, -0.00510636965735315, 0.00357253294639726, -0.00503838053087464]
        b = [0, 0, 0, 0, 0, 0]
        c = [0, 0, 0, 0, 0, 0]
        s = [0, 0, 0, 0, 0, 0]
        f = [0, 0, 0, 0, 0, 0]
    } else {
        // use the parameters for 3000 BC - 3000 AD
        a0 = [1.00000018, 0.38709843, 0.72332102, 1.52371243, 5.20248019, 9.54149883]
        adot = [-0.00000003, 0, -0.00000026, 0.00000097, -0.00002864, -0.00003065]
        e0 = [0.01673163, 0.20563661, 0.00676399, 0.09336511, 0.0485359, 0.05550825]
        edot = [-0.00003661, 0.00002123, -0.00005107, 0.00009149, 0.00018026, -0.00032044]
        I0 = [-9.48516635288838e-06, 0.122270686943013, 0.059302368845932, 0.0323203332904682, 0.0226650928050204, 0.0435327181373017]
        Idot =  [-0.000233381587852327, -0.000103002002069847, 7.59113504862414e-06, -0.000126493959268765, -5.63216004289318e-05, 7.88834716694625e-05]
        L0 = [1.75347846863765, 4.40262213698312, 3.17614508514451, -0.0797289377825283, 0.599255160009829, 0.873986072195182]
        Ldot = [628.307588608167, 2608.79031817869, 1021.32855334028, 334.061243342709, 52.9690623526126, 21.3299296671748]
        pom0 = [1.79646842620403, 1.35189222676191, 2.29977771922823, -0.417438213482006, 0.249144920643598, 1.62073649087534]
        pomdot = [0.00554931973527652, 0.00278205709660699, 0.000991285579543109, 0.00789301155937221, 0.00317635891415782, 0.00945610278111832]
        Omg0 = [-0.08923177123077, 0.843685496572442, 1.33818957716586, 0.867659193442843, 1.75044003925455, 1.98339193542262]
        Omgdot = [-0.00421040715476989, -0.00213177691337826, -0.00476024137061832, -0.00468663333114593, 0.00227322485367811, -0.00436594147292966]
        b = [0, 0, 0, 0, -2.17328398458334e-06, 4.52022822974011e-06]
        c = [0, 0, 0, 0, 0.00105837813038487, -0.0023447571730711]
        s = [0, 0, 0, 0, -0.00621955723490303, 0.0152402406847545]
        f = [0, 0, 0, 0, 0.669355584755475, 0.669355584755475]
    }
    
    var xp: Double, yp: Double, zp: Double
    var x: [Double] = [0, 0, 0, 0, 0, 0]
    var y: [Double] = [0, 0, 0, 0, 0, 0]
    var z: [Double] = [0, 0, 0, 0, 0, 0]
    var rGeo: [Double] = [0, 0, 0, 0, 0, 0]
    var vx: [Double] = [0, 0, 0, 0, 0, 0]
    var vy: [Double] = [0, 0, 0, 0, 0, 0]
    var vz: [Double] = [0, 0, 0, 0, 0, 0]

    for i in 0..<6 {
        let a = a0[i] + adot[i]*T
        let e = e0[i] + edot[i]*T
        let I = I0[i] + Idot[i]*T
        let L = L0[i] + (Ldot[i]*T % pi2)
        let pom = pom0[i] + pomdot[i]*T
        let Omg = Omg0[i] + Omgdot[i]*T
        let omg = pom - Omg
        var M = L - pom
        M += b[i] * T*T + c[i] * cos(f[i]*T) + s[i] * sin(f[i]*T)
        let E = kepler(M: M, e: e)
        let bb = a * sqrt(1-e*e)
        let Edot = Ldot[i] / (1-e*cos(E))
        xp = a * (cos(E)-e)
        yp = bb * sin(E)
        let vxp = -a*sin(E)*Edot
        let vyp = bb*cos(E)*Edot
        let m11 = cos(omg)*cos(Omg) - sin(omg)*sin(Omg)*cos(I)
        let m12 = -sin(omg)*cos(Omg) - cos(omg)*sin(Omg)*cos(I)
        x[i] = m11*xp + m12*yp
        vx[i] = m11*vxp + m12*vyp
        let m21 = cos(omg)*sin(Omg) + sin(omg)*cos(Omg)*cos(I)
        let m22 = cos(omg)*cos(Omg)*cos(I) - sin(omg)*sin(Omg)
        y[i] = m21*xp + m22*yp
        vy[i] = m21*vxp + m22*vyp
        let m31 = sin(omg)*sin(I)
        let m32 = cos(omg)*sin(I)
        z[i] = m31*xp + m32*yp
        vz[i] = m31*vxp + m32*vyp
    }
    
    // heliocentric position -> geocentric position
    // index 2 becomes Sun's geocentric position
    x[0] = -x[0]; y[0] = -y[0]; z[0] = -z[0]
    //let dT;
    for i in 1..<6 {
        x[i] = x[i] + x[0]
        y[i] = y[i] + y[0]
        z[i] = z[i] + z[0]
        rGeo[i] = sqrt(x[i]*x[i] + y[i]*y[i] + z[i]*z[i])
        // correct for light time
        let dT = rGeo[i]*f1oc
        x[i] -= vx[i]*dT
        y[i] -= vy[i]*dT
        z[i] -= vz[i]*dT
    }

    // RA and Dec with respect to J2000
    let p = precession_matrix(T0: 0,T: T)
    
    var output = [Double]()
    for i in 1..<6 {
        // equatorial coordinates
        let xeq = x[i]
        let yeq = cosEps*y[i] - sinEps*z[i]
        let zeq = sinEps*y[i] + cosEps*z[i]

        // precessed to the mean equator and equinox of the date
        xp = p.p11*xeq + p.p12*yeq + p.p13*zeq
        yp = p.p21*xeq + p.p22*yeq + p.p23*zeq
        zp = p.p31*xeq + p.p32*yeq + p.p33*zeq
        
        //to eliptic coordinates
        let xel = xp
        let yel = cosEps*yp + sinEps*zp
        //let zel = - sinEps*yp + cosEps*zp
        output.append(atan2(yel,xel))
    }
    return output
}

func moonCoordinate(D: Double) -> (Double, Double, Double) {
    var l = 0.606434 + 0.03660110129 * D
    var m = 0.374897 + 0.03629164709 * D
    var f = 0.259091 + 0.03674819520 * D
    var d = 0.827362 + 0.03386319198 * D
    var n = 0.347343 - 0.00014709391 * D
    var g = 0.993126 + 0.00273777850 * D

    l = 2 * Double.pi * (l - floor(l))
    m = 2 * Double.pi * (m - floor(m))
    f = 2 * Double.pi * (f - floor(f))
    d = 2 * Double.pi * (d - floor(d))
    n = 2 * Double.pi * (n - floor(n))
    g = 2 * Double.pi * (g - floor(g))

    var v: Double, u: Double, w: Double
    v = 0.39558 * sin(f + n)
      + 0.08200 * sin(f)
      + 0.03257 * sin(m - f - n)
      + 0.01092 * sin(m + f + n)
      + 0.00666 * sin(m - f)
      - 0.00644 * sin(m + f - 2*d + n)
      - 0.00331 * sin(f - 2*d + n)
      - 0.00304 * sin(f - 2*d)
      - 0.00240 * sin(m - f - 2*d - n)
      + 0.00226 * sin(m + f)
      - 0.00108 * sin(m + f - 2*d)
      - 0.00079 * sin(f - n)
      + 0.00078 * sin(f + 2*d + n)
      
    u = 1
      - 0.10828 * cos(m)
      - 0.01880 * cos(m - 2*d)
      - 0.01479 * cos(2*d)
      + 0.00181 * cos(2*m - 2*d)
      - 0.00147 * cos(2*m)
      - 0.00105 * cos(2*d - g)
      - 0.00075 * cos(m - 2*d + g)
      
    w = 0.10478 * sin(m)
      - 0.04105 * sin(2*f + 2*n)
      - 0.02130 * sin(m - 2*d)
      - 0.01779 * sin(2*f + n)
      + 0.01774 * sin(n)
      + 0.00987 * sin(2*d)
      - 0.00338 * sin(m - 2*f - 2*n)
      - 0.00309 * sin(g)
      - 0.00190 * sin(2*f)
      - 0.00144 * sin(m + n)
      - 0.00144 * sin(m - 2*f - n)
      - 0.00113 * sin(m + 2*f + 2*n)
      - 0.00094 * sin(m - 2*d + g)
      - 0.00092 * sin(2*m - 2*d)

    var s: Double
    s = w / sqrt(u - v*v)
    let rightAscension = l + atan(s / sqrt(1 - s*s))

    s = v / sqrt(u)
    let declination = atan(s / sqrt(1 - s*s))

    let distance = 60.40974 * sqrt(u)

    let x = cos(rightAscension) * cos(declination) * distance
    let y = sin(rightAscension) * cos(declination) * distance
    let z = sin(declination) * distance
    
    // RA and Dec with respect to J2000
    let p = precession_matrix(T0: 0,T: D/36525)
    // precessed to the mean equator and equinox of the date
    let x_new = p.p11*x + p.p12*y + p.p13*z
    let y_new = p.p21*x + p.p22*y + p.p23*z
    let z_new = p.p31*x + p.p32*y + p.p33*z
    
    return (x: x_new, y: y_new, z: z_new)
}

func moonElipticPosition(D: Double) -> Double {
    let (x, y, z) = moonCoordinate(D: D)
    // Back to eliptic
    let yel = cos(eps) * y + sin(eps) * z
    return atan2(yel, x)
}

func moonEquatorPosition(D: Double) -> (Double, Double, Double) {
    let (x, y, z) = moonCoordinate(D: D)
    return (ra: atan2(y, x), dec: atan2(z, sqrt(x*x+y*y)), sqrt(x*x+y*y+z*z))
}

func equationOfTime(D: Double) -> Double {
    let d = D / 36525
    let epsilon = (23.4393 - 0.013 * d - 2e-7 * pow(d, 2) + 5e-7 * pow(d, 3)) / 180 * Double.pi
    let e = 1.6709e-2 - 4.193e-5 * d - 1.26e-7 * pow(d, 2)
    let lambdaP = (282.93807 + 1.7195 * d + 3.025e-4 * pow(d, 2)) / 180 * Double.pi
    let y = pow(tan(epsilon / 2), 2)
    let m = 6.24004077 + 0.01720197 * D
    var deltaT = -2 * e * sin(m) + y * sin(2 * (m + lambdaP))
    deltaT += -1.25 * pow(e, 2) * sin(2 * m) + 4 * e * y * sin(m) * cos(2 * (m + lambdaP)) - 0.5 * pow(y, 2) * sin(4 * (m + lambdaP))
    return deltaT
}

func daytimeOffset(latitude: Double, progressInYear: Double) -> Double {
    let denominator = sqrt(pow(cos(eps), 2) + pow(sin(eps) * sin(progressInYear), 2)) * cos(latitude)
    let numerator = sin(latitude) * sin(eps) * cos(progressInYear) - sin(aeroAdj)
    let cosValue = numerator / denominator
    if cosValue >= 1 {
        return -Double.infinity
    } else if cosValue <= -1 {
        return Double.infinity
    } else {
        return acos(cosValue)
    }
}

func lunarTimeOffset(latitude: Double, jdTime: Double, light: Bool) -> Double {
    let (_, dec, dist) = moonEquatorPosition(D: jdTime)
    let parallaxAdj = asin((1-0.273) / dist)
    let cosValue = (sin(latitude) * sin(dec) - sin(aeroAdj - parallaxAdj)) / (cos(dec) * cos(latitude)) * (light ? 1 : -1)
    if cosValue >= 1 {
        return Double.infinity
    } else if cosValue <= -1 {
        return -Double.infinity
    } else {
        return Double.pi - acos(cosValue)
    }
}
