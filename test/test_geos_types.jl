
@testset "open_issue_if_conversion_makes_sense" begin
    polygon = readgeom("POLYGON EMPTY")
    GC.@preserve polygon begin
        res = @test_throws Exception Point(polygon.ptr, polygon.context)
        msg = res.value.msg
        @test occursin("GEOS_POLYGON", msg)
        @test occursin("Point", msg)
    end
end

# Function to test if a geomerty is valid and if its type matches the geometry ID and has the correct dimensions
function testValidTypeDims(
    geom::LibGEOS.Geometry,
    typeid::LibGEOS.GEOSGeomTypes,
    dims::Integer,
)
    @test LibGEOS.isValid(geom)
    @test LibGEOS.geomTypeId(geom) == typeid
    @test LibGEOS.getGeomDimensions(geom) == dims
end
testValidTypeDims(point::LibGEOS.Point) = testValidTypeDims(point, LibGEOS.GEOS_POINT, 0)
testValidTypeDims(multipoint::LibGEOS.MultiPoint) =
    testValidTypeDims(multipoint, LibGEOS.GEOS_MULTIPOINT, 0)
testValidTypeDims(linestring::LibGEOS.LineString) =
    testValidTypeDims(linestring, LibGEOS.GEOS_LINESTRING, 1)
testValidTypeDims(multilinestring::LibGEOS.MultiLineString) =
    testValidTypeDims(multilinestring, LibGEOS.GEOS_MULTILINESTRING, 1)
testValidTypeDims(ring::LibGEOS.LinearRing) =
    testValidTypeDims(ring, LibGEOS.GEOS_LINEARRING, 1)
testValidTypeDims(poly::LibGEOS.Polygon) = testValidTypeDims(poly, LibGEOS.GEOS_POLYGON, 2)
testValidTypeDims(multipoly::LibGEOS.MultiPolygon) =
    testValidTypeDims(multipoly, LibGEOS.GEOS_MULTIPOLYGON, 2)

@testset "GEOS types" begin
    @testset "Point" begin
        # Test 2D point made from real x and y
        point2D = LibGEOS.Point(0.0, 0.0)
        testValidTypeDims(point2D)
        @test LibGEOS.area(point2D) == 0.0
        @test LibGEOS.GeoInterface.coordinates(point2D) == [0.0, 0.0]

        # Test 3D point made from real x, y, and z
        point3D = LibGEOS.Point(0.0, 0.0, 2.0)
        testValidTypeDims(point3D)
        @test LibGEOS.area(point3D) == 0.0
        @test LibGEOS.GeoInterface.coordinates(point3D) == [0.0, 0.0, 2.0]

        # Test point made from vector
        point_coord = LibGEOS.Point([0.0, 0.0, 0.2])
        testValidTypeDims(point_coord, LibGEOS.GEOS_POINT, 0)
        @test LibGEOS.equals(point_coord, point3D)

        # Test point made from point pointer
        point_ptr = LibGEOS.Point(point2D)
        testValidTypeDims(point_ptr)
        @test LibGEOS.equals(point_ptr, point2D)

        # Test point made from polygon pointer --> should not work
        @test_throws MethodError LibGEOS.Point(
            LibGEOS.Polygon([[[-2.0, -2.0], [2.0, 2.0], [-2.0, 2.0], [-2.0, -2.0]]]),
        )

        # Test point made with local context
        ctx = LibGEOS.GEOSContext()
        point_ctx = LibGEOS.Point(point2D, ctx)
        @test LibGEOS.equals(point_ctx, point2D)

        LibGEOS.destroyGeom(point2D)
        LibGEOS.destroyGeom(point3D)
        LibGEOS.destroyGeom(point_coord)
        LibGEOS.destroyGeom(point_ptr)
        LibGEOS.destroyGeom(point_ctx)
    end

    @testset "MultiPoint" begin
        # Test MultiPoint made from vector of coordinates
        mpoint_coord = LibGEOS.MultiPoint([[0.0, 0.0], [1.0, 1.0]])
        point1 = Point(0.0, 0.0)
        point2 = Point(1.0, 1.0)
        testValidTypeDims(mpoint_coord)
        @test GeoInterface.coordinates(mpoint_coord) == [[0.0, 0.0], [1.0, 1.0]]
        @test LibGEOS.numGeometries(mpoint_coord) == 2
        @test LibGEOS.equals(LibGEOS.getGeometry(mpoint_coord, 1), point1)
        @test LibGEOS.equals(LibGEOS.getGeometry(mpoint_coord, 2), point2)

        # Test MultiPoint made from MultiPoint pointer
        multipoint_ptr = LibGEOS.MultiPoint(mpoint_coord)
        testValidTypeDims(multipoint_ptr)
        @test LibGEOS.equals(multipoint_ptr, mpoint_coord)
        @test LibGEOS.equals(
            LibGEOS.getGeometry(mpoint_coord, 1),
            LibGEOS.getGeometry(multipoint_ptr, 1),
        )
        @test LibGEOS.equals(
            LibGEOS.getGeometry(mpoint_coord, 2),
            LibGEOS.getGeometry(multipoint_ptr, 2),
        )

        # Test MultiPoint made from Point pointer
        mpoint_ptr = LibGEOS.MultiPoint(LibGEOS.getGeometry(mpoint_coord, 1))
        testValidTypeDims(mpoint_ptr)
        @test LibGEOS.equals(LibGEOS.getGeometry(mpoint_ptr, 1), Point(0.0, 0.0))

        # Test MultiPoint made from Polygon pointer
        @test_throws MethodError LibGEOS.MultiPoint(
            LibGEOS.Polygon([[[-2.0, -2.0], [2.0, 2.0], [-2.0, 2.0], [-2.0, -2.0]]]),
        )

        # Test MultiPoint made from vector of 1 point and 2 points
        point_coord1 = LibGEOS.MultiPoint([point1])
        point_coord2 = LibGEOS.MultiPoint([point1, point2])
        testValidTypeDims(point_coord1)
        testValidTypeDims(point_coord2)
        @test LibGEOS.numGeometries(point_coord1) == 1
        @test LibGEOS.equals(point_coord2, mpoint_coord)

        # Test MultiPoint made with local context
        ctx = LibGEOS.GEOSContext()
        mpoint_ctx = LibGEOS.MultiPoint(mpoint_coord, ctx)
        @test LibGEOS.equals(mpoint_ctx, mpoint_coord)

        LibGEOS.destroyGeom(mpoint_coord)
        LibGEOS.destroyGeom(point1)
        LibGEOS.destroyGeom(point2)
        LibGEOS.destroyGeom(multipoint_ptr)
        LibGEOS.destroyGeom(mpoint_ptr)
        LibGEOS.destroyGeom(point_coord1)
        LibGEOS.destroyGeom(point_coord2)
        LibGEOS.destroyGeom(mpoint_ctx)
    end

    @testset "LineString" begin
        # Test LineString made from vectors
        ls_coord = LibGEOS.LineString([[0.0, 0.0], [1.0, 1.0], [1.0, 0.0]])
        testValidTypeDims(ls_coord)
        @test LibGEOS.numCoordinates(ls_coord) == 3

        # Test LineString made from linestring pointer
        ls_ptr = LibGEOS.LineString(ls_coord)
        testValidTypeDims(ls_ptr)
        @test LibGEOS.equals(ls_coord, ls_ptr)

        # Test LineString made from polygon pointer
        @test_throws MethodError LibGEOS.LineString(
            LibGEOS.Polygon([[[-2.0, -2.0], [2.0, 2.0], [-2.0, 2.0], [-2.0, -2.0]]]),
        )

        # Test LineString made with local context
        ctx = LibGEOS.GEOSContext()
        linestring_ctx = LibGEOS.LineString(ls_coord, ctx)
        @test LibGEOS.equals(linestring_ctx, ls_coord)

        LibGEOS.destroyGeom(ls_coord)
        LibGEOS.destroyGeom(ls_ptr)
        LibGEOS.destroyGeom(linestring_ctx)
    end

    @testset "MultiLineString" begin
        # Test MultiLineString made from vectors
        mls_coord = LibGEOS.MultiLineString([
            [[0.0, 0.0], [1.0, 1.0], [1.0, 0.0]],
            [[-2.0, -2.0], [2.0, 2.0], [-2.0, 2.0]],
        ])
        testValidTypeDims(mls_coord)
        @test LibGEOS.numGeometries(mls_coord) == 2

        # Test MultiLineString made from MultiLineString pointer
        mls_ptr = LibGEOS.MultiLineString(mls_coord)
        testValidTypeDims(mls_ptr)
        @test LibGEOS.equals(mls_coord, mls_ptr)

        # Test MultiLineString made from polygon pointer
        @test_throws MethodError LibGEOS.MultiLineString(
            LibGEOS.Polygon([[[-2.0, -2.0], [2.0, 2.0], [-2.0, 2.0], [-2.0, -2.0]]]),
        )

        # Test MultiLineString made with local context
        ctx = LibGEOS.GEOSContext()
        multilinestring_ctx = LibGEOS.MultiLineString(mls_coord, ctx)
        @test LibGEOS.equals(multilinestring_ctx, mls_coord)

        LibGEOS.destroyGeom(mls_coord)
        LibGEOS.destroyGeom(mls_ptr)
        LibGEOS.destroyGeom(multilinestring_ctx)
    end

    @testset "LinearRing" begin
        # Test LinearRing made from vectors
        lr_coord = LibGEOS.LinearRing([
            [-2.0, -2.0],
            [2.0, -2.0],
            [2.0, 2.0],
            [-2.0, 2.0],
            [-2.0, -2.0],
        ])
        testValidTypeDims(lr_coord)
        @test LibGEOS.numCoordinates(lr_coord) == 5

        # Test LinearRing made from LinearRing pointer
        lr_ptr = LibGEOS.LinearRing(lr_coord)
        testValidTypeDims(lr_ptr)
        @test LibGEOS.equals(lr_ptr, lr_coord)

        # Test LinearRing made from polygon pointer
        @test_throws MethodError LibGEOS.LinearRing(
            LibGEOS.Polygon([[[-2.0, -2.0], [2.0, 2.0], [-2.0, 2.0], [-2.0, -2.0]]]),
        )

        # Test LinearRing made with local context
        ctx = LibGEOS.GEOSContext()
        linearring_ctx = LibGEOS.LinearRing(lr_coord, ctx)
        @test LibGEOS.equals(linearring_ctx, lr_coord)

        LibGEOS.destroyGeom(lr_coord)
        LibGEOS.destroyGeom(lr_ptr)
        LibGEOS.destroyGeom(linearring_ctx)
    end


    @testset "Polygon" begin
        # Test polygon made from vectors
        poly_vec = LibGEOS.Polygon([
            [[-2.0, -2.0], [2.0, -2.0], [2.0, 2.0], [-2.0, 2.0], [-2.0, -2.0]],
            [[0.0, 0.0], [1.0, 1.0], [1.0, 0.0], [0.0, 0.0]],
        ])
        testValidTypeDims(poly_vec)
        @test LibGEOS.area(poly_vec) == 15.5
        @test !LibGEOS.isEmpty(poly_vec)
        @test LibGEOS.GeoInterface.coordinates(poly_vec) == [
            [[-2.0, -2.0], [2.0, -2.0], [2.0, 2.0], [-2.0, 2.0], [-2.0, -2.0]],
            [[0.0, 0.0], [1.0, 1.0], [1.0, 0.0], [0.0, 0.0]],
        ]
        @test length(LibGEOS.interiorRings(poly_vec)) == 1

        # Test polygon made from  polygon pointer
        poly_ptr = LibGEOS.Polygon(poly_vec)
        testValidTypeDims(poly_ptr)
        @test LibGEOS.equals(poly_vec, poly_ptr) # same area and coordinates
        @test length(LibGEOS.interiorRings(poly_vec)) == 1

        # Test polygon made from linear ring pointer
        ring_ext = LibGEOS.LinearRing([
            [-2.0, -2.0],
            [2.0, -2.0],
            [2.0, 2.0],
            [-2.0, 2.0],
            [-2.0, -2.0],
        ])
        poly_ringptr = LibGEOS.Polygon(ring_ext)

        # tests that ring's geomTypeID is linear ring and dimensions is 1
        testValidTypeDims(ring_ext)

        # tests that the geomTypeID is polygon and dimensions is 2
        testValidTypeDims(poly_ringptr)
        @test LibGEOS.area(poly_ringptr) == 16
        @test !LibGEOS.isEmpty(poly_ringptr)

        # Test polygon made from point pointer
        point = LibGEOS.Point(1.0, 2.0)
        @test_throws MethodError LibGEOS.Polygon(point)

        # Test polygon made from 1 linear ring
        poly_ring = LibGEOS.Polygon(ring_ext)
        testValidTypeDims(poly_ring)
        @test LibGEOS.area(poly_ring) == 16
        @test !LibGEOS.isEmpty(poly_ring)
        @test LibGEOS.GeoInterface.coordinates(poly_ring) ==
              [[[-2.0, -2.0], [2.0, -2.0], [2.0, 2.0], [-2.0, 2.0], [-2.0, -2.0]]]
        @test length(LibGEOS.interiorRings(poly_ring)) == 0

        # Test polygon made from multiple linear rings (exterior and interior)
        ring_int1 = LibGEOS.LinearRing([[0.0, 0.0], [1.0, 1.0], [1.0, 0.0], [0.0, 0.0]])
        ring_int2 = LibGEOS.LinearRing([
            [0.0, 0.0],
            [0.0, -1.0],
            [-1.0, -1.0],
            [-1.0, 0.0],
            [0.0, 0.0],
        ])

        #1 ring
        poly_rings1 = LibGEOS.Polygon(ring_ext, [ring_int1])
        testValidTypeDims(poly_rings1)
        @test length(LibGEOS.interiorRings(poly_rings1)) == 1
        @test LibGEOS.equals(poly_rings1, poly_vec)

        #2 rings
        poly_rings2 = LibGEOS.Polygon(ring_ext, [ring_int1, ring_int2])
        testValidTypeDims(poly_rings2)
        @test LibGEOS.area(poly_rings2) == 14.5
        @test !LibGEOS.isEmpty(poly_rings2)
        @test LibGEOS.GeoInterface.coordinates(poly_rings2) == [
            [[-2.0, -2.0], [2.0, -2.0], [2.0, 2.0], [-2.0, 2.0], [-2.0, -2.0]],
            [[0.0, 0.0], [1.0, 1.0], [1.0, 0.0], [0.0, 0.0]],
            [[0.0, 0.0], [0.0, -1.0], [-1.0, -1.0], [-1.0, 0.0], [0.0, 0.0]],
        ]
        @test length(LibGEOS.interiorRings(poly_rings2)) == 2

        # Test Polygon made with local context
        ctx = LibGEOS.GEOSContext()
        poly_ctx = LibGEOS.Polygon(poly_vec, ctx)
        @test LibGEOS.equals(poly_ctx, poly_vec)

        LibGEOS.destroyGeom(poly_vec)
        LibGEOS.destroyGeom(poly_ptr)
        LibGEOS.destroyGeom(ring_ext)
        LibGEOS.destroyGeom(poly_ringptr)
        LibGEOS.destroyGeom(point)
        LibGEOS.destroyGeom(poly_ring)
        LibGEOS.destroyGeom(ring_int1)
        LibGEOS.destroyGeom(ring_int2)
        LibGEOS.destroyGeom(poly_rings1)
        LibGEOS.destroyGeom(poly_rings2)
        LibGEOS.destroyGeom(poly_ctx)
    end

    @testset "MultiPolygon" begin
        poly1 = LibGEOS.Polygon([[[-2.0, -2.0], [2.0, 2.0], [-2.0, 2.0], [-2.0, -2.0]]])
        poly2 = LibGEOS.Polygon([[[0.0, 0.0], [1.0, -1.0], [1.0, 0.0], [0.0, 0.0]]])
        # Test multipolygon made from vectors
        mpoly_coord = LibGEOS.MultiPolygon([
            [[[-2.0, -2.0], [2.0, 2.0], [-2.0, 2.0], [-2.0, -2.0]]],
            [[[0.0, 0.0], [1.0, -1.0], [1.0, 0.0], [0.0, 0.0]]],
        ])
        testValidTypeDims(mpoly_coord)
        @test LibGEOS.numGeometries(mpoly_coord) == 2
        @test LibGEOS.equals(LibGEOS.getGeometry(mpoly_coord, 1), poly1)

        # Test multipolygon made from multipolygon pointer
        mpoly_ptr = LibGEOS.MultiPolygon(mpoly_coord)
        testValidTypeDims(mpoly_coord)
        @test LibGEOS.equals(mpoly_ptr, mpoly_coord)

        # Test multipolygon made from polygon pointer
        mpoly_poly_ptr = LibGEOS.MultiPolygon(poly1)
        testValidTypeDims(mpoly_poly_ptr)
        @test LibGEOS.equals(LibGEOS.getGeometry(mpoly_poly_ptr, 1), poly1)

        # Test multipolygon made from point pointer --> should finalizer
        @test_throws MethodError LibGEOS.MultiPolygon(LibGEOS.Point(1.0, 2.0))

        # Test multipolygon made from list of polygons
        mpoly_polylist = LibGEOS.MultiPolygon([poly1, poly2])
        testValidTypeDims(mpoly_polylist)
        @test LibGEOS.equals(mpoly_polylist, mpoly_coord)

        # Test MultiPolygon made with local context
        ctx = LibGEOS.GEOSContext()
        mpoly_ctx = LibGEOS.MultiPolygon(mpoly_coord, ctx)
        @test LibGEOS.equals(mpoly_ctx, mpoly_coord)

        LibGEOS.destroyGeom(poly1)
        LibGEOS.destroyGeom(poly2)
        LibGEOS.destroyGeom(mpoly_coord)
        LibGEOS.destroyGeom(mpoly_ptr)
        LibGEOS.destroyGeom(mpoly_poly_ptr)
        LibGEOS.destroyGeom(mpoly_polylist)
        LibGEOS.destroyGeom(mpoly_ctx)
    end

    @testset "GeometryCollections" begin
        point = LibGEOS.Point(0.0, 0.0)
        poly = LibGEOS.Polygon([[[-2.0, -2.0], [2.0, 2.0], [-2.0, 2.0], [-2.0, -2.0]]])
        # Test GeometryCollection from list of geometry pointers
        geomcol_ptr_list = LibGEOS.GeometryCollection([point, poly])
        @test LibGEOS.isValid(geomcol_ptr_list)
        @test LibGEOS.geomTypeId(geomcol_ptr_list) == LibGEOS.GEOS_GEOMETRYCOLLECTION
        #test GeometryCollection from GeometryCollection pointer
        geomcollection_ptr = LibGEOS.GeometryCollection(geomcol_ptr_list)
        @test LibGEOS.isValid(geomcollection_ptr)
        @test LibGEOS.geomTypeId(geomcollection_ptr) == LibGEOS.GEOS_GEOMETRYCOLLECTION
        @test LibGEOS.equals(geomcol_ptr_list, geomcollection_ptr)

        # Test GeomertyCollections made with local context
        ctx = LibGEOS.GEOSContext()
        geomcollect_ctx = LibGEOS.GeometryCollection(geomcol_ptr_list, ctx)
        @test LibGEOS.equals(geomcollect_ctx, geomcol_ptr_list)

        LibGEOS.destroyGeom(point)
        LibGEOS.destroyGeom(poly)
        LibGEOS.destroyGeom(geomcol_ptr_list)
        LibGEOS.destroyGeom(geomcollection_ptr)
        LibGEOS.destroyGeom(geomcollect_ctx)
    end

end

@testset "Multi threading" begin
    function f91(n)
        # adapted from https://github.com/JuliaGeo/LibGEOS.jl/issues/91#issuecomment-1267732709
        contexts = [LibGEOS.GEOSContext() for i = 1:Threads.nthreads()]
        p = [[[-1.0, -1], [+1, -1], [+1, +1], [-1, +1], [-1, -1]]]
        Threads.@threads :static for i = 1:n
            ctx = contexts[Threads.threadid()]
            g1 = LibGEOS.Polygon(p, ctx)
            g2 = LibGEOS.Polygon(p, ctx)
            for j = 1:n
                @test LibGEOS.intersects(g1, g2, ctx)
            end
        end
        GC.gc(true)
        return nothing
    end
    @test f91(91) === nothing
    @testset "clone" begin
        function f(n)
            # adapted from https://github.com/JuliaGeo/LibGEOS.jl/issues/91#issuecomment-1267732709
            contexts = [LibGEOS.GEOSContext() for i = 1:Threads.nthreads()]
            p = LibGEOS.Polygon([[[-1.0, -1], [+1, -1], [+1, +1], [-1, +1], [-1, -1]]])
            Threads.@threads :static for i = 1:n
                ctx = contexts[Threads.threadid()]
                g1 = LibGEOS.clone(p, ctx)
                g2 = LibGEOS.clone(p, ctx)
                for j = 1:n
                    @test intersects(g1, g2)
                end
            end
            GC.gc(true)
            return nothing
        end
        @test f(91) === nothing
    end
end

@testset "clone" begin
    geos = [
        readgeom("POINT(0 0)")
        readgeom("MULTIPOINT(0 0, 5 0, 10 0)")
        readgeom("LINESTRING (130 240, 650 240)")
        readgeom("POLYGON EMPTY")
        readgeom("POLYGON ((10 10, 20 40, 90 90, 90 10, 10 10))")
        readgeom("MULTILINESTRING ((5 0, 10 0), (0 0, 5 0))")
        readgeom(
            "GEOMETRYCOLLECTION (LINESTRING (1 2, 2 2), LINESTRING (2 1, 1 1), POLYGON ((0.5 1, 1 2, 1 1, 0.5 1)), POLYGON ((9 2, 9.5 1, 2 1, 2 2, 9 2)))",
        )
    ]
    for g1 in geos
        g2 = LibGEOS.clone(g1)
        @test g1 !== g2
        @test LibGEOS.equals(g1, g2)
    end
end

@testset "Curved geometry types" begin
    wkt = [
        "CIRCULARSTRING(0 0,1 1,2 0)"
        "CIRCULARSTRING (0 0, 1 1, 2 0, 3 -1, 4 0, 2 2, 0 0)"
        "CURVEPOLYGON ((0 0, 2 0, 0 2, 0 0))"
        "CURVEPOLYGON (CIRCULARSTRING (0 0, 1 1, 2 0, 3 -1, 4 0, 2 2, 0 0))"
        "COMPOUNDCURVE (CIRCULARSTRING (0 0, 1 1, 2 0), (2 0, 2 -1, 0 -1, 0 0))"
        "CURVEPOLYGON (COMPOUNDCURVE (CIRCULARSTRING (0 0, 1 1, 2 0), (2 0, 2 -1, 0 -1, 0 0)))"
        "MULTISURFACE (CURVEPOLYGON (CIRCULARSTRING (0 0, 1 1, 2 0, 3 -1, 4 0, 2 2, 0 0)))"
        "MULTICURVE((1 0, 2 0))"
        "CURVEPOLYGON (COMPOUNDCURVE (CIRCULARSTRING (0 0, 2 2, 4 0), (4 0, 4 -1, 0 -1, 0 0)), LINEARRING (1 0, 3 0, 3 1, 1 1, 1 0))"
    ]

    geom = readgeom.(wkt)
    @test all(geomLength.(geom) .≈ [pi, 4pi, 4 + 2 * sqrt(2), 4pi, pi + 4, pi + 4, 4pi, 1, 2pi + 12])
    @test all(area.(geom) .≈ [0, 0, 2, 2pi, 0, pi / 2 + 2, 2pi, 0, 2pi + 2])

    cp = geom[5]
    @test_broken ngeom(cp) # not defined, not supported in GEOS 3.13.0

    cp = geom[6]
    @test_broken isequal(cp, CurvePolygon(cp)) # needs ngeom for compoundcurve

    cp = geom[9]
    @test length(interiorRings(cp)) == 1
    @test typeof(exteriorRing(cp)) == CompoundCurve
    @test typeof(interiorRings(cp)[1]) == LinearRing

    geom = [
        CircularString([[0.,0], [1,1], [2,0]])
        CircularString([[0.,0], [1,1], [2,0], [3,-1], [4,0], [2,2], [0,0]])
        CurvePolygon([[[0.,0], [2,0], [0,2], [0,0]]])
        CurvePolygon(CircularString([[0.,0], [1,1], [2,0], [3,-1], [4,0], [2,2], [0,0]]))
        ]
    @test ngeom.(geom) == [3, 7, 1, 1]
end
