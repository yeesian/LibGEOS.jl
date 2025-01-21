function _readgeom(
    wktstring::String,
    wktreader::WKTReader,
    context::GEOSContext = get_global_context(),
)
    result = GEOSWKTReader_read_r(context, wktreader, wktstring)
    if result == C_NULL
        error("LibGEOS: Error in GEOSWKTReader_read_r while reading $wktstring")
    end
    result
end
_readgeom(wktstring::String, context::GEOSContext = get_global_context()) =
    _readgeom(wktstring, WKTReader(context), context)

function _readgeom(
    wkbbuffer::Vector{Cuchar},
    wkbreader::WKBReader,
    context::GEOSContext = get_global_context(),
)
    result = GEOSWKBReader_read_r(context, wkbreader, wkbbuffer, length(wkbbuffer))
    if result == C_NULL
        error("LibGEOS: Error in GEOSWKBReader_read_r")
    end
    result
end
_readgeom(wkbbuffer::Vector{Cuchar}, context::GEOSContext = get_global_context()) =
    _readgeom(wkbbuffer, WKBReader(context), context)

readgeom(
    wktstring::String,
    wktreader::WKTReader,
    context::GEOSContext = get_global_context(),
) = geomFromGEOS(_readgeom(wktstring, wktreader, context), context)
readgeom(wktstring::String, context::GEOSContext = get_global_context()) =
    readgeom(wktstring, WKTReader(context), context)

readgeom(
    wkbbuffer::Vector{Cuchar},
    wkbreader::WKBReader,
    context::GEOSContext = get_global_context(),
) = geomFromGEOS(_readgeom(wkbbuffer, wkbreader, context), context)
readgeom(wkbbuffer::Vector{Cuchar}, context::GEOSContext = get_global_context()) =
    readgeom(wkbbuffer, WKBReader(context), context)

function writegeom(
    obj::Geometry,
    wktwriter::WKTWriter,
    context::GEOSContext = get_context(obj),
)
    GEOSWKTWriter_write_r(context, wktwriter, obj)
end

function writegeom(
    obj::Geometry,
    wkbwriter::WKBWriter,
    context::GEOSContext = get_context(obj),
)
    wkbsize = Ref{Csize_t}()
    result = GEOSWKBWriter_write_r(context, wkbwriter, obj, wkbsize)
    unsafe_wrap(Array, result, wkbsize[], own = true)
end

writegeom(obj::Geometry, context::GEOSContext = get_context(obj)) =
    writegeom(obj, WKTWriter(context), context)

writegeom(obj::PreparedGeometry, context::GEOSContext = get_context(obj)) =
    writegeom(obj.ownedby, WKTWriter(context), context)

# -----
# Coordinate Sequence functions
# -----
"""
    createCoordSeq(size::Integer; ndim::Integer=2) -> Ptr{Ptr{Void}}

Create a Coordinate sequence with ``size'' coordinates of ``dims'' dimensions (Return NULL on exception)
"""
function createCoordSeq(
    size::Integer,
    context::GEOSContext = get_global_context();
    ndim::Integer = 2,
)
    @assert ndim >= 2
    result = GEOSCoordSeq_create_r(context, size, ndim)
    if result == C_NULL
        error("LibGEOS: Error in GEOSCoordSeq_create")
    end
    result
end

# Clone a Coordinate Sequence (Return NULL on exception)
function cloneCoordSeq(ptr::GEOSCoordSeq, context::GEOSContext = get_global_context())
    result = GEOSCoordSeq_clone_r(context, ptr)
    if result == C_NULL
        error("LibGEOS: Error in GEOSCoordSeq_clone")
    end
    result
end

function destroyCoordSeq(ptr::GEOSCoordSeq, context::GEOSContext = get_global_context())
    result = GEOSCoordSeq_destroy_r(context, ptr)
    if result == C_NULL
        error("LibGEOS: Error in GEOSCoordSeq_destroy")
    end
    result
end

# Set ordinate values in a Coordinate Sequence (Return 0 on exception)
function setX!(
    ptr::GEOSCoordSeq,
    i::Integer,
    value::Real,
    context::GEOSContext = get_global_context(),
)
    if !(0 < i <= getSize(ptr, context))
        error(
            "LibGEOS: i=$i is out of bounds for CoordSeq with size=$(getSize(ptr, context))",
        )
    end
    result = GEOSCoordSeq_setX_r(context, ptr, i - 1, value)
    if result == 0
        error("LibGEOS: Error in GEOSCoordSeq_setX")
    end
    result
end

function setY!(
    ptr::GEOSCoordSeq,
    i::Integer,
    value::Real,
    context::GEOSContext = get_global_context(),
)
    if !(0 < i <= getSize(ptr, context))
        error(
            "LibGEOS: i=$i is out of bounds for CoordSeq with size=$(getSize(ptr, context))",
        )
    end
    result = GEOSCoordSeq_setY_r(context, ptr, i - 1, value)
    if result == 0
        error("LibGEOS: Error in GEOSCoordSeq_setY")
    end
    result
end

function setZ!(
    ptr::GEOSCoordSeq,
    i::Integer,
    value::Real,
    context::GEOSContext = get_global_context(),
)
    if !(0 < i <= getSize(ptr, context))
        error(
            "LibGEOS: i=$i is out of bounds for CoordSeq with size=$(getSize(ptr, context))",
        )
    end
    result = GEOSCoordSeq_setZ_r(context, ptr, i - 1, value)
    if result == 0
        error("LibGEOS: Error in GEOSCoordSeq_setZ")
    end
    result
end

"Get size info from a Coordinate Sequence (Return 0 on exception)"
function getSize(ptr::GEOSCoordSeq, context::GEOSContext = get_global_context())
    out = Ref{UInt32}()
    result = GEOSCoordSeq_getSize_r(context, ptr, out)
    if result == 0
        error("LibGEOS: Error in GEOSCoordSeq_getSize")
    end
    Int(out[])
end

"Get dimensions info from a Coordinate Sequence (Return 0 on exception)"
function getDimensions(ptr::GEOSCoordSeq, context::GEOSContext = get_global_context())
    out = Ref{UInt32}()
    result = GEOSCoordSeq_getDimensions_r(context, ptr, out)
    if result == 0
        error("LibGEOS: Error in GEOSCoordSeq_getDimensions")
    end
    Int(out[])
end

# convenience functions
# Use Tuple where possible
function setCoordSeq!(
    ptr::GEOSCoordSeq,
    i::Integer,
    coords::Union{Vector{<:Real},Tuple},
    context::GEOSContext = get_global_context(),
)
    ndim = length(coords)
    @assert ndim >= 2
    if !(0 < i <= getSize(ptr, context))
        error(
            "LibGEOS: i=$i is out of bounds for CoordSeq with size=$(getSize(ptr, context))",
        )
    end
    setX!(ptr, i, Float64(coords[1]), context)
    setY!(ptr, i, Float64(coords[2]), context)
    ndim >= 3 && setZ!(ptr, i, Float64(coords[3]), context)
    ptr
end

"""
    createCoordSeq(x::Real, y::Real) -> Ptr{Ptr{Void}}

Create a createCoordSeq of a single 2D coordinate
"""
function createCoordSeq(x::Real, y::Real, context::GEOSContext = get_global_context())
    coordinates = createCoordSeq(1, context, ndim = 2)
    setX!(coordinates, 1, x, context)
    setY!(coordinates, 1, y, context)
    coordinates
end

"""
    createCoordSeq(x::Real, y::Real, z::Real) -> Ptr{Ptr{Void}}

Create a createCoordSeq of a single 3D coordinate
"""
function createCoordSeq(
    x::Real,
    y::Real,
    z::Real,
    context::GEOSContext = get_global_context(),
)
    coordinates = createCoordSeq(1, context, ndim = 3)
    setX!(coordinates, 1, x, context)
    setY!(coordinates, 1, y, context)
    setZ!(coordinates, 1, z, context)
    coordinates
end

"""
    createCoordSeq(coords::Vector{Float64}) -> Ptr{Ptr{Void}}

Create a createCoordSeq of a single N dimensional coordinate
"""
function createCoordSeq(
    coords::Vector{Float64},
    context::GEOSContext = get_global_context(),
)
    ndim = length(coords)
    @assert ndim >= 2
    coordinates = createCoordSeq(1, context, ndim = ndim)
    setCoordSeq!(coordinates, 1, coords, context)
end

"""
    createCoordSeq(coords::Vector{Float64}) -> Ptr{Ptr{Void}}

Create a createCoordSeq of a multiple N dimensional coordinate
"""
function createCoordSeq(
    coords::Vector{Vector{Float64}},
    context::GEOSContext = get_global_context(),
)
    ncoords = length(coords)
    @assert ncoords > 0
    ndim = length(coords[1])
    coordinates = createCoordSeq(ncoords, context, ndim = ndim)
    for (i, coord) in enumerate(coords)
        setCoordSeq!(coordinates, i, coord, context)
    end
    coordinates
end

function getX(ptr::GEOSCoordSeq, i::Integer, context::GEOSContext = get_global_context())
    if !(0 < i <= getSize(ptr, context))
        error(
            "LibGEOS: i=$i is out of bounds for CoordSeq with size=$(getSize(ptr, context))",
        )
    end
    out = Ref{Float64}()
    result = GEOSCoordSeq_getX_r(context, ptr, i - 1, out)
    if result == 0
        error("LibGEOS: Error in GEOSCoordSeq_getX")
    end
    out[]
end

function getX(ptr::GEOSCoordSeq, context::GEOSContext = get_global_context())
    ncoords = getSize(ptr, context)
    xcoords = Vector{Float64}(undef, ncoords)
    start = pointer(xcoords)
    floatsize = sizeof(Float64)
    for i = 0:ncoords-1
        GEOSCoordSeq_getX_r(context, ptr, i, start + i * floatsize)
    end
    xcoords
end

function getY(ptr::GEOSCoordSeq, i::Integer, context::GEOSContext = get_global_context())
    if !(0 < i <= getSize(ptr, context))
        error(
            "LibGEOS: i=$i is out of bounds for CoordSeq with size=$(getSize(ptr, context))",
        )
    end
    out = Ref{Float64}()
    result = GEOSCoordSeq_getY_r(context, ptr, i - 1, out)
    if result == 0
        error("LibGEOS: Error in GEOSCoordSeq_getY")
    end
    out[]
end

function getY(ptr::GEOSCoordSeq, context::GEOSContext = get_global_context())
    ncoords = getSize(ptr, context)
    ycoords = Vector{Float64}(undef, ncoords)
    start = pointer(ycoords)
    floatsize = sizeof(Float64)
    for i = 0:ncoords-1
        GEOSCoordSeq_getY_r(context, ptr, i, start + i * floatsize)
    end
    ycoords
end

function getZ(ptr::GEOSCoordSeq, i::Integer, context::GEOSContext = get_global_context())
    if !(0 < i <= getSize(ptr, context))
        error(
            "LibGEOS: i=$i is out of bounds for CoordSeq with size=$(getSize(ptr, context))",
        )
    end
    out = Ref{Float64}()
    result = GEOSCoordSeq_getZ_r(context, ptr, i - 1, out)
    if result == 0
        error("LibGEOS: Error in GEOSCoordSeq_getZ")
    end
    out[]
end

function getZ(ptr::GEOSCoordSeq, context::GEOSContext = get_global_context())
    ncoords = getSize(ptr, context)
    zcoords = Array{Float64}(undef, ncoords)
    start = pointer(zcoords)
    floatsize = sizeof(Float64)
    for i = 0:ncoords-1
        GEOSCoordSeq_getZ_r(context, ptr, i, start + i * floatsize)
    end
    zcoords
end

function getCoordinates!(out::Vector{Float64}, ptr::GEOSCoordSeq, i::Integer, context)
    if !(0 < i <= getSize(ptr, context))
        error(
            "LibGEOS: i=$i is out of bounds for CoordSeq with size=$(getSize(ptr, context))",
        )
    end
    ndim = getDimensions(ptr, context)
    @assert length(out) == ndim
    start = pointer(out)
    floatsize = sizeof(Float64)
    if ndim == 3
        GEOSCoordSeq_getXYZ_r(
            context,
            ptr,
            i - 1,
            start,
            start + floatsize,
            start + 2 * floatsize,
        )
    else
        GEOSCoordSeq_getXY_r(context, ptr, i - 1, start, start + floatsize)
    end
    out
end

function getCoordinates(
    ptr::GEOSCoordSeq,
    i::Integer,
    context::GEOSContext = get_global_context(),
)
    ndim = getDimensions(ptr, context)
    out = Vector{Float64}(undef, ndim)
    getCoordinates!(out, ptr, i, context)
    out
end

function getCoordinates(ptr::GEOSCoordSeq, context::GEOSContext = get_global_context())
    ncoords = getSize(ptr, context)
    coordseq = Vector{Float64}[]
    sizehint!(coordseq, ncoords)
    for i = 1:ncoords
        push!(coordseq, getCoordinates(ptr, i, context))
    end
    coordseq
end

function isCCW(ptr::GEOSCoordSeq, context::GEOSContext = get_global_context())::Bool
    d = [0x02]
    GC.@preserve d begin
        result = GEOSCoordSeq_isCCW_r(context, ptr, pointer(d))
        if result == C_NULL
            error("LibGEOS: Error in GEOSInterpolateNormalized")
        end
        Bool(d[1])
    end
end

# -----
# Linear referencing functions -- there are more, but these are probably sufficient for most purposes
# -----
# (GEOSGeometry ownership is retained by caller)

# Return distance of point 'point' projected on 'line' from origin of 'line'. Geometry 'line' must be a lineal geometry
project(line::LineString, point::Point, context::GEOSContext = get_context(line)) =
    GEOSProject_r(context, line, point)

# Return closest point to given distance within geometry (Geometry must be a LineString)
function interpolate(line::LineString, dist::Real, context::GEOSContext = get_context(line))
    result = GEOSInterpolate_r(context, line, dist)
    if result == C_NULL
        error("LibGEOS: Error in GEOSInterpolate")
    end
    Point(result, context)
end

projectNormalized(
    line::LineString,
    point::Point,
    context::GEOSContext = get_context(line),
) = GEOSProjectNormalized_r(context, line, point)

function interpolateNormalized(
    line::LineString,
    dist::Real,
    context::GEOSContext = get_context(line),
)
    result = GEOSInterpolateNormalized_r(context, line, dist)
    if result == C_NULL
        error("LibGEOS: Error in GEOSInterpolateNormalized")
    end
    Point(result, context)
end

# -----
# Buffer related functions
# -----
# Computes the buffer of a geometry, for both positive and negative buffer distances.
# Since true buffer curves may contain circular arcs, computed buffer polygons can only be approximations to the true geometry.
# The user can control the accuracy of the curve approximation by specifying the number of linear segments with which to approximate a curve.

# Always returns a polygon. The negative or zero-distance buffer of lines and points is always an empty Polygon.
buffer(
    obj::Geometry,
    dist::Real,
    quadsegs::Integer = 8,
    context::GEOSContext = get_context(obj),
) = geomFromGEOS(GEOSBuffer_r(context, obj, dist, Int32(quadsegs)), context)

bufferWithStyle(
    obj::Geometry,
    dist::Real;
    quadsegs::Integer = 8,
    endCapStyle::GEOSBufCapStyles = GEOSBUF_CAP_ROUND,
    joinStyle::GEOSBufJoinStyles = GEOSBUF_JOIN_ROUND,
    mitreLimit::Real = 5.0,
    context::GEOSContext = get_context(obj),
) = geomFromGEOS(
    GEOSBufferWithStyle_r(
        context,
        obj,
        dist,
        Int32(quadsegs),
        Int32(endCapStyle),
        Int32(joinStyle),
        mitreLimit,
    ),
    context,
)

# GEOSBufferParams_create
# GEOSBufferParams_destroy
# GEOSBufferParams_setEndCapStyle
# GEOSBufferParams_setJoinStyle
# GEOSBufferParams_setMitreLimit
# GEOSBufferParams_setQuadrantSegments
# GEOSBufferParams_setSingleSided
# GEOSBufferWithParams
# GEOSOffsetCurve

# -----
# Geometry Constructors -- All functions return NULL on exception
# -----
# (GEOSCoordSequence* arguments will become ownership of the returned object.)

function createPoint(ptr::GEOSCoordSeq, context::GEOSContext = get_global_context())
    result = GEOSGeom_createPoint_r(context, ptr)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeom_createPoint")
    end
    result
end
createPoint(x::Real, y::Real, context::GEOSContext = get_global_context()) =
    createPoint(createCoordSeq(x, y, context), context)
createPoint(x::Real, y::Real, z::Real, context::GEOSContext = get_global_context()) =
    createPoint(createCoordSeq(x, y, z, context), context)
createPoint(coords::Vector{Vector{Float64}}, context::GEOSContext = get_global_context()) =
    createPoint(createCoordSeq(coords, context), context)
createPoint(coords::Vector{Float64}, context::GEOSContext = get_global_context()) =
    createPoint(createCoordSeq(Vector{Float64}[coords], context), context)

function createLinearRing(ptr::GEOSCoordSeq, context::GEOSContext = get_global_context())
    result = GEOSGeom_createLinearRing_r(context, ptr)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeom_createLinearRing")
    end
    result
end
createLinearRing(
    coords::Vector{Vector{Float64}},
    context::GEOSContext = get_global_context(),
) = GEOSGeom_createLinearRing_r(context, createCoordSeq(coords, context))

function createLineString(ptr::GEOSCoordSeq, context::GEOSContext = get_global_context())
    result = GEOSGeom_createLineString_r(context, ptr)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeom_createLineString")
    end
    result
end
createLineString(
    coords::Vector{Vector{Float64}},
    context::GEOSContext = get_global_context(),
) = GEOSGeom_createLineString_r(context, createCoordSeq(coords, context))

# Second argument is an array of GEOSGeometry* objects.
# The caller remains owner of the array, but pointed-to
# objects become ownership of the returned GEOSGeometry.
function createPolygon(
    shell::Union{LinearRing,GEOSGeom},
    holes::AbstractVector,
    context::GEOSContext = get_global_context(),
)
    result = GEOSGeom_createPolygon_r(context, shell, holes, length(holes))
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeom_createPolygon")
    end
    result
end
# convenience function to create polygon without holes
createPolygon(
    shell::Union{LinearRing,GEOSGeom},
    context::GEOSContext = get_global_context(),
) = createPolygon(shell, GEOSGeom[], context)

function createCollection(
    geomtype::GEOSGeomTypes,
    geoms::AbstractVector,
    context::GEOSContext = get_global_context(),
)
    result = GEOSGeom_createCollection_r(context, geomtype, geoms, length(geoms))
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeom_createCollection")
    end
    result
end

function createCircularString(ptr::GEOSCoordSeq, context::GEOSContext = get_global_context())
    result = GEOSGeom_createCircularString_r(context, ptr)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeom_createCircularString")
    end
    result
end
createCircularString(
    coords::Vector{Vector{Float64}},
    context::GEOSContext = get_global_context(),
) = GEOSGeom_createCircularString_r(context, createCoordSeq(coords, context))

# Second argument is an array of GEOSGeometry* objects.
# The caller remains owner of the array, but pointed-to
# objects become ownership of the returned GEOSGeometry.
function createCurvePolygon(
    shell::Union{LinearRing,CircularString,CompoundCurve,GEOSGeom},
    holes::AbstractVector,
    context::GEOSContext = get_global_context(),
)
    result = GEOSGeom_createCurvePolygon_r(context, shell, holes, length(holes))
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeom_createCurvePolygon")
    end
    result
end
# convenience function to create polygon without holes
createCurvePolygon(
    shell::Union{LinearRing,CircularString,CompoundCurve,GEOSGeom},
    context::GEOSContext = get_global_context(),
) = createCurvePolygon(shell, GEOSGeom[], context)

function createEmptyCollection(
    geomtype::GEOSGeomTypes,
    context::GEOSContext = get_global_context(),
)
    result = GEOSGeom_createEmptyCollection_r(context, geomtype)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeom_createEmptyCollection")
    end
    result
end

function createEmptyPolygon(context::GEOSContext = get_global_context())::Polygon
    result = GEOSGeom_createEmptyPolygon_r(context)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeom_createEmptyPolygon")
    end
    Polygon(result, context)
end

function reverse(
    obj::Geometry,
    context::GEOSContext = get_context(obj),
)::LibGEOS.AbstractGeometry
    result = GEOSReverse_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSReverse_r")
    end
    geomFromGEOS(result, context)
end

function makeValid(
    obj::Geometry,
    context::GEOSContext = get_context(obj),
)::LibGEOS.AbstractGeometry
    result = GEOSMakeValid_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSMakeValid_r")
    end
    geomFromGEOS(result, context)
end

# Memory management
# cloneGeom result needs to be wrapped in Geometry type
function cloneGeom(
    ptr::Union{Geometry,GEOSGeom},
    context::GEOSContext = get_global_context(),
)
    result = GEOSGeom_clone_r(context, ptr)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeom_clone")
    end
    result
end

function destroyGeom(obj::Geometry, context::GEOSContext = get_context(obj))
    GEOSGeom_destroy_r(context, obj)
    obj.ptr = C_NULL
end

function destroyGeom(obj::PreparedGeometry, context::GEOSContext = get_context(obj))
    destroyPreparedGeom(obj, context)
    obj.ptr = C_NULL
end


# -----
# Topology operations - return NULL on exception.
# -----

function envelope(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSEnvelope_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSEnvelope")
    end
    geomFromGEOS(result, context)
end

function envelope(obj::PreparedGeometry, context::GEOSContext = get_context(obj))
    envelope(obj.ownedby, context)
end

"""
    minimumRotatedRectangle(geom)

Returns the minimum rotated rectangular POLYGON which encloses the input geometry. The rectangle
has width equal to the minimum diameter, and a longer length. If the convex hill of the input is
degenerate (a line or point) a LINESTRING or POINT is returned. The minimum rotated rectangle can
be used as an extremely generalized representation for the given geometry.
"""
function minimumRotatedRectangle(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSMinimumRotatedRectangle_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSMinimumRotatedRectangle")
    end
    geomFromGEOS(result, context)
end


function intersection(
    obj1::Geometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSIntersection_r(context, obj1, obj2)
    if result == C_NULL
        error("LibGEOS: Error in GEOSIntersection")
    end
    geomFromGEOS(result, context)
end

# Returns a Geometry that represents the convex hull of the input geometry. The returned geometry contains the minimal number of points needed to represent the convex hull. In particular, no more than two consecutive points will be collinear.

# Returns:
# if the convex hull contains 3 or more points, a Polygon; 2 points, a LineString; 1 point, a Point; 0 points, an empty GeometryCollection.
function convexhull(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSConvexHull_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSConvexHull")
    end
    geomFromGEOS(result, context)
end

function difference(
    obj1::Geometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSDifference_r(context, obj1, obj2)
    if result == C_NULL
        error("LibGEOS: Error in GEOSDifference")
    end
    geomFromGEOS(result, context)
end

function symmetricDifference(
    obj1::Geometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSSymDifference_r(context, obj1, obj2)
    if result == C_NULL
        error("LibGEOS: Error in GEOSSymDifference")
    end
    geomFromGEOS(result, context)
end

function boundary(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSBoundary_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSBoundary")
    end
    geomFromGEOS(result, context)
end

function union(obj1::Geometry, obj2::Geometry, context::GEOSContext = get_context(obj1))
    result = GEOSUnion_r(context, obj1, obj2)
    if result == C_NULL
        error("LibGEOS: Error in GEOSUnion")
    end
    geomFromGEOS(result, context)
end

function unaryUnion(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSUnaryUnion_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSUnaryUnion")
    end
    geomFromGEOS(result, context)
end

function pointOnSurface(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSPointOnSurface_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSPointOnSurface")
    end
    Point(result, context)
end

function centroid(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSGetCentroid_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGetCentroid")
    end
    Point(result, context)
end

function node(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSNode_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSNode")
    end
    geomFromGEOS(result, context)
end

# all arguments remain ownership of the caller (both Geometries and pointers)
function polygonize(geoms::Vector{GEOSGeom}, context::GEOSContext = get_global_context())
    result = GEOSPolygonize_r(context, pointer(geoms), length(geoms))
    if result == C_NULL
        error("LibGEOS: Error in GEOSPolygonize")
    end
    result
end
# GEOSPolygonizer_getCutEdges
# GEOSPolygonize_full

function lineMerge(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSLineMerge_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSLineMerge")
    end
    geomFromGEOS(result, context)
end

function maximumInscribedCircle(
    obj::Geometry,
    tolerance,
    context::GEOSContext = get_context(obj),
)
    result = GEOSMaximumInscribedCircle_r(context, obj, tolerance)
    if result == C_NULL
        error("LibGEOS: Error in GEOSMaximumInscribedCircle")
    end
    geomFromGEOS(result, context)
end

function isValidReason(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSisValidReason_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSisValidReason")
    end
    result
end

function simplify(obj::Geometry, tol::Real, context::GEOSContext = get_context(obj))
    result = GEOSSimplify_r(context, obj, tol)
    if result == C_NULL
        error("LibGEOS: Error in GEOSSimplify")
    end
    geomFromGEOS(result, context)
end

function topologyPreserveSimplify(
    obj::Geometry,
    tol::Real,
    context::GEOSContext = get_context(obj),
)
    result = GEOSTopologyPreserveSimplify_r(context, obj, tol)
    if result == C_NULL
        error("LibGEOS: Error in GEOSTopologyPreserveSimplify")
    end
    geomFromGEOS(result, context)
end

# Return all distinct vertices of input geometry as a MULTIPOINT.
# (Note that only 2 dimensions of the vertices are considered when testing for equality)
function uniquePoints(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSGeom_extractUniquePoints_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeom_extractUniquePoints")
    end
    MultiPoint(result, context)
end

# Find paths shared between the two given lineal geometries.
# Returns a GEOMETRYCOLLECTION having two elements:
# - first element is a MULTILINESTRING containing shared paths
#    having the _same_ direction on both inputs
#  - second element is a MULTILINESTRING containing shared paths
#    having the _opposite_ direction on the two inputs
# (Returns NULL on exception)
function sharedPaths(
    obj1::LineString,
    obj2::LineString,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSSharedPaths_r(context, obj1, obj2)
    if result == C_NULL
        error("LibGEOS: Error in GEOSSharedPaths")
    end
    GeometryCollection(result, context)
end

# Snap first geometry on to second with given tolerance
# (Returns a newly allocated geometry, or NULL on exception)
function snap(
    obj1::Geometry,
    obj2::Geometry,
    tol::Real,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSSnap_r(context, obj1, obj2, tol)
    if result == C_NULL
        error("LibGEOS: Error in GEOSSnap")
    end
    geomFromGEOS(result, context)
end

# Return a Delaunay triangulation of the vertex of the given geometry
#
# @param g the input geometry whose vertex will be used as "sites"
# @param tolerance optional snapping tolerance to use for improved robustness
# @param onlyEdges if non-zero will return a MULTILINESTRING, otherwise it will
#                  return a GEOMETRYCOLLECTION containing triangular POLYGONs.
#
# @return  a newly allocated geometry, or NULL on exception
function delaunayTriangulation(
    obj::Geometry,
    tol::Real = 0.0,
    onlyEdges::Bool = false,
    context::GEOSContext = get_context(obj),
)
    result = GEOSDelaunayTriangulation_r(context, obj, tol, Int32(onlyEdges))
    if result == C_NULL
        error("LibGEOS: Error in GEOSDelaunayTriangulation")
    end
    onlyEdges ? MultiLineString(result, context) : GeometryCollection(result, context)
end

function delaunayTriangulationEdges(
    obj::Geometry,
    tol::Real = 0.0,
    context::GEOSContext = get_context(obj),
)
    delaunayTriangulation(obj, tol, true, context)
end

function constrainedDelaunayTriangulation(
    obj::Geometry,
    context::GEOSContext = get_context(obj),
)
    result = GEOSConstrainedDelaunayTriangulation_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSConstrainedDelaunayTriangulation")
    end
    GeometryCollection(result, context)
end

# -----
# Binary predicates - return 2 on exception, 1 on true, 0 on false
# -----
function disjoint(obj1::Geometry, obj2::Geometry, context::GEOSContext = get_context(obj1))
    result = GEOSDisjoint_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSDisjoint")
    end
    result != 0x00
end

function touches(obj1::Geometry, obj2::Geometry, context::GEOSContext = get_context(obj1))
    result = GEOSTouches_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSTouches")
    end
    result != 0x00
end

function intersects(
    obj1::Geometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSIntersects_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSIntersects")
    end
    result != 0x00
end

function crosses(obj1::Geometry, obj2::Geometry, context::GEOSContext = get_context(obj1))
    result = GEOSCrosses_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSCrosses")
    end
    result != 0x00
end

function within(obj1::Geometry, obj2::Geometry, context::GEOSContext = get_context(obj1))
    result = GEOSWithin_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSWithin")
    end
    result != 0x00
end

Base.contains(obj1::Geometry, obj2::Geometry, context::GEOSContext = get_context(obj1)) =
    contains(obj1, obj2, context)

function contains(obj1::Geometry, obj2::Geometry, context::GEOSContext = get_context(obj1))
    result = GEOSContains_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSContains")
    end
    result != 0x00
end

function overlaps(obj1::Geometry, obj2::Geometry, context::GEOSContext = get_context(obj1))
    result = GEOSOverlaps_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSOverlaps")
    end
    result != 0x00
end

function equals(obj1::Geometry, obj2::Geometry, context::GEOSContext = get_context(obj1))
    result = GEOSEquals_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSEquals")
    end
    result != 0x00
end

function equalsexact(
    obj1::Geometry,
    obj2::Geometry,
    tol::Real,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSEqualsExact_r(context, obj1, obj2, tol)
    if result == 0x02
        error("LibGEOS: Error in GEOSEqualsExact")
    end
    result != 0x00
end

function covers(obj1::Geometry, obj2::Geometry, context::GEOSContext = get_context(obj1))
    result = GEOSCovers_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSCovers")
    end
    result != 0x00
end

function coveredby(obj1::Geometry, obj2::Geometry, context::GEOSContext = get_context(obj1))
    result = GEOSCoveredBy_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSCoveredBy")
    end
    result != 0x00
end

# -----
# Prepared Geometry Binary predicates - return 2 on exception, 1 on true, 0 on false
# -----

# GEOSGeometry ownership is retained by caller
function prepareGeom(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSPrepare_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSPrepare")
    end
    PreparedGeometry(result, obj)
end

function destroyPreparedGeom(
    obj::PreparedGeometry,
    context::GEOSContext = get_global_context(),
)
    GEOSPreparedGeom_destroy_r(context, obj)
end

Base.contains(
    obj1::PreparedGeometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
) = contains(obj1, obj2, context)

function contains(
    obj1::PreparedGeometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSPreparedContains_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSPreparedContains")
    end
    result != 0x00
end

function containsproperly(
    obj1::PreparedGeometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSPreparedContainsProperly_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSPreparedContainsProperly")
    end
    result != 0x00
end

function coveredby(
    obj1::PreparedGeometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSPreparedCoveredBy_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSPreparedCoveredBy")
    end
    result != 0x00
end

function covers(
    obj1::PreparedGeometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSPreparedCovers_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSPreparedCovers")
    end
    result != 0x00
end

function crosses(
    obj1::PreparedGeometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSPreparedCrosses_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSPreparedCrosses")
    end
    result != 0x00
end

function disjoint(
    obj1::PreparedGeometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSPreparedDisjoint_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSPreparedDisjoint")
    end
    result != 0x00
end

function intersects(
    obj1::PreparedGeometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSPreparedIntersects_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSPreparedIntersects")
    end
    result != 0x00
end

function overlaps(
    obj1::PreparedGeometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSPreparedOverlaps_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSPreparedOverlaps")
    end
    result != 0x00
end

function touches(
    obj1::PreparedGeometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSPreparedTouches_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSPreparedTouches")
    end
    result != 0x00
end

function within(
    obj1::PreparedGeometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    result = GEOSPreparedWithin_r(context, obj1, obj2)
    if result == 0x02
        error("LibGEOS: Error in GEOSPreparedWithin")
    end
    result != 0x00
end

# -----
# STRtree functions
# -----
# GEOSSTRtree_create
# GEOSSTRtree_insert
# GEOSSTRtree_query
# GEOSSTRtree_iterate
# GEOSSTRtree_remove
# GEOSSTRtree_destroy

# -----
# Unary predicate - return 2 on exception, 1 on true, 0 on false
# -----
function isEmpty(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSisEmpty_r(context, obj)
    if result == 0x02
        error("LibGEOS: Error in GEOSisEmpty")
    end
    result != 0x00
end

isEmpty(obj::PreparedGeometry, context::GEOSContext = get_context(obj)) =
    isEmpty(obj.ownedby, context)

function isSimple(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSisSimple_r(context, obj)
    if result == 0x02
        error("LibGEOS: Error in GEOSisSimple")
    end
    result != 0x00
end

function isRing(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSisRing_r(context, obj)
    if result == 0x02
        error("LibGEOS: Error in GEOSisRing")
    end
    result != 0x00
end

function hasZ(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSHasZ_r(context, obj)
    if result == 0x02
        error("LibGEOS: Error in GEOSHasZ")
    end
    result != 0x00
end
hasZ(obj::PreparedGeometry, context::GEOSContext = get_context(obj)) =
    hasZ(obj.ownedby, context)

# Call only on LINESTRING (return 2 on exception, 1 on true, 0 on false)
function isClosed(obj::LineString, context::GEOSContext = get_context(obj))
    result = GEOSisClosed_r(context, obj)
    if result == 0x02
        error("LibGEOS: Error in GEOSisClosed")
    end
    result != 0x00
end

# -----
# Dimensionally Extended 9 Intersection Model related
# -----

# GEOSRelatePattern (return 2 on exception, 1 on true, 0 on false)
# GEOSRelate (return NULL on exception, a string to GEOSFree otherwise)
# GEOSRelatePatternMatch (return 2 on exception, 1 on true, 0 on false)
# GEOSRelateBoundaryNodeRule (return NULL on exception, a string to GEOSFree otherwise)

# -----
# Validity checking -- return 2 on exception, 1 on true, 0 on false
# -----

# /* These are for use with GEOSisValidDetail (flags param) */
# enum GEOSValidFlags {
#     GEOSVALID_ALLOW_SELFTOUCHING_RING_FORMING_HOLE=1
# };

function isValid(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSisValid_r(context, obj)
    if result == 0x02
        error("LibGEOS: Error in GEOSisValid")
    end
    result != 0x00
end

# * return NULL on exception, a string to GEOSFree otherwise
# GEOSisValidReason

# * Caller has the responsibility to destroy 'reason' (GEOSFree)
# * and 'location' (GEOSGeom_destroy) params
# * return 2 on exception, 1 when valid, 0 when invalid
# GEOSisValidDetail

# -----
# Geometry info
# -----

# Return NULL on exception, result must be freed by caller
# function geomType(ptr::GEOSGeom)
#     result = GEOSGeomType(ptr)
#     if result == C_NULL
#         error("LibGEOS: Error in GEOSGeomType")
#     end
#     result
# end

# Return -1 on exception
function geomTypeId(
    obj::Union{Geometry,Ptr{Cvoid}},
    context::GEOSContext = get_global_context(),
)
    result = GEOSGeomTypeId_r(context, obj)
    if result == -1
        error("LibGEOS: Error in GEOSGeomTypeId")
    end
    result
end

# Return 0 on exception
function getSRID(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSGetSRID_r(context, obj)
    if result == 0
        error("LibGEOS: Error in GEOSGeomTypeId")
    end
    result
end

setSRID(obj::Geometry, context::GEOSContext = get_context(obj)) =
    GEOSSetSRID_r(context, obj)

# May be called on all geometries in GEOS 3.x, returns -1 on error and 1
# for non-multi geometries. Older GEOS versions only accept
# GeometryCollections or Multi* geometries here, and are likely to crash
# when fed simple geometries, so beware if you need compatibility with
# old GEOS versions.
"""
    numGeometries(obj::Geometry, context::GEOSContext = get_context(obj))

Returns the number of sub-geometries immediately under a
multi-geometry or collection or 1 for a simple geometry.
For nested collections, remember to check if returned
sub-geometries are **themselves** also collections.
"""
function numGeometries(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSGetNumGeometries_r(context, obj)
    if result == -1
        error("LibGEOS: Error in GEOSGeomTypeId")
    end
    result
end

# Call only on GEOMETRYCOLLECTION or MULTI*
# (Return a pointer to the internal Geometry. Return NULL on exception.)
# Returned object is a pointer to internal storage:
# it must NOT be destroyed directly.
# Up to GEOS 3.2.0 the input geometry must be a Collection, in
# later version it doesn't matter (i.e. getGeometryN(0) for a single will return the input).
"""
    getGeometry(obj::Geometry, n::Integer, context::GEOSContext = get_context(obj))

Returns a copy of the specified sub-geometry of a collection.
Numbering is one-based.
For a simple geometry, returns a copy of the input.
"""
function getGeometry(obj::Geometry, n::Integer, context::GEOSContext = get_context(obj))
    n in 1:numGeometries(obj, context) || error(
        "GEOSGetGeometryN: $(numGeometries(obj, context)) sub-geometries in geom, therefore n should be in 1:$(numGeometries(obj, context))",
    )
    result = GEOSGetGeometryN_r(context, obj, n - 1)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGetGeometryN")
    end
    geomFromGEOS(cloneGeom(result, context), context)
end

"""
    getGeometries(obj::Geometry, context::GEOSContext = get_context(obj))

Returns a vector of copies of the sub-geometries of a collection.
For a simple geometry, returns the geometry in a vector of length one.
"""
getGeometries(obj::Geometry, context::GEOSContext = get_context(obj)) =
    [getGeometry(obj, i, context) for i = 1:numGeometries(obj, context)]

# Converts Geometry to normal form (or canonical form).
# Return -1 on exception, 0 otherwise.
function normalize!(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSNormalize_r(context, obj)
    if result == -1
        error("LibGEOS: Error in GEOSNormalize")
    end
    result
end

# Return -1 on exception
function numInteriorRings(
    obj::Union{Polygon,CurvePolygon},
    context::GEOSContext = get_context(obj),
)
    result = GEOSGetNumInteriorRings_r(context, obj)
    if result == -1
        error("LibGEOS: Error in GEOSGetNumInteriorRings")
    end
    result
end

# Call only on LINESTRING (returns -1 on exception)
function numPoints(
    obj::Union{LineString,LinearRing,CircularString},
    context::GEOSContext = get_context(obj),
)
    result = GEOSGeomGetNumPoints_r(context, obj)
    if result == -1
        error("LibGEOS: Error in GEOSGeomGetNumPoints")
    end
    result
end

# Return -1 on exception, Geometry must be a Point.
function getGeomX(obj::Point, context::GEOSContext = get_context(obj))
    out = Ref{Float64}()
    result = GEOSGeomGetX_r(context, obj, out)
    if result == -1
        error("LibGEOS: Error in GEOSGeomGetX")
    end
    out[]
end

function getGeomY(obj::Point, context::GEOSContext = get_context(obj))
    out = Ref{Float64}()
    result = GEOSGeomGetY_r(context, obj, out)
    if result == -1
        error("LibGEOS: Error in GEOSGeomGetY")
    end
    out[]
end

function getGeomZ(obj::Point, context::GEOSContext = get_context(obj))
    out = Ref{Float64}()
    result = GEOSGeomGetZ_r(context, obj, out)
    if result == -1
        error("LibGEOS: Error in GEOSGeomGetY")
    end
    out[]
end

# Return NULL on exception, Geometry must be a Polygon.
# Returned object is a pointer to internal storage: it must NOT be destroyed directly.
function interiorRing(obj::Polygon, n::Integer, context::GEOSContext = get_context(obj))
    if !(0 < n <= numInteriorRings(obj, context))
        error(
            "LibGEOS: n=$n is out of bounds for Polygon with $(numInteriorRings(obj, context)) interior ring(s)",
        )
    end
    result = GEOSGetInteriorRingN_r(context, obj, n - 1)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGetInteriorRingN")
    end
    LinearRing(cloneGeom(result, context), context)
end

function interiorRings(obj::Polygon, context::GEOSContext = get_context(obj))
    n = numInteriorRings(obj, context)
    if n == 0
        return LinearRing[]
    else
        return LinearRing[interiorRing(obj, i, context) for i = 1:n]
    end
end

# Polygon rings are of type LinearRing, and can be inferred, but CurvePolygon rings can be Union{LinearRing,CircularString,CompoundCurve}
function interiorRing(
    obj::CurvePolygon,
    n::Integer,
    context::GEOSContext = get_context(obj),
)
    if !(0 < n <= numInteriorRings(obj, context))
        error(
            "LibGEOS: n=$n is out of bounds for CurvePolygon with $(numInteriorRings(obj, context)) interior ring(s)",
        )
    end
    result = GEOSGetInteriorRingN_r(context, obj, n - 1)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGetInteriorRingN")
    end
    geomFromGEOS(cloneGeom(result, context), context)
end

function interiorRings(obj::CurvePolygon, context::GEOSContext = get_context(obj))
    n = numInteriorRings(obj, context)
    if n == 0
        return LinearRing[]
    else
        return [interiorRing(obj, i, context) for i = 1:n]
    end
end


# Return NULL on exception, Geometry must be a Polygon.
# Returned object is a pointer to internal storage: it must NOT be destroyed directly.
function exteriorRing(
    obj::Polygon,
    context::GEOSContext = get_context(obj),
)::LinearRing
    result = GEOSGetExteriorRing_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGetExteriorRing")
    end
    LinearRing(cloneGeom(result, context), context)
end

function exteriorRing(
    obj::CurvePolygon,
    context::GEOSContext = get_context(obj),
)::Union{LinearRing,CircularString,CompoundCurve}
    result = GEOSGetExteriorRing_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGetExteriorRing")
    end
    geomFromGEOS(cloneGeom(result, context), context)
end


# Return -1 on exception
function numCoordinates(obj::Geometry, context::GEOSContext = get_context(obj))
    result = GEOSGetNumCoordinates_r(context, obj)
    if result == -1
        error("LibGEOS: Error in GEOSGetNumCoordinates")
    end
    result
end

# Geometry must be a LineString, LinearRing or Point (Return NULL on exception)
function getCoordSeq(
    obj::Union{LineString,LinearRing,Point},
    context::GEOSContext = get_context(obj),
)
    result = GEOSGeom_getCoordSeq_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeom_getCoordSeq")
    end
    result
end
# getGeomCoordinates(ptr::GEOSGeom) = getCoordinates(getCoordSeq(ptr))

# Return 0 on exception (or empty geometry)
getGeomDimensions(obj::Geometry, context::GEOSContext = get_context(obj)) =
    GEOSGeom_getDimensions_r(context, obj)

# Return 2 or 3.
getCoordinateDimension(obj::Geometry, context::GEOSContext = get_context(obj)) =
    GEOSGeom_getCoordinateDimension_r(context, obj)

"""
    getXMin(obj::Geometry, context::GEOSContext = get_context(obj))

Finds the minimum X value in the geometry
"""
function getXMin(obj::Geometry, context::GEOSContext = get_context(obj))
    out = Ref{Float64}()
    result = GEOSGeom_getXMin_r(context, obj, out)
    if result == 0
        error("LibGEOS: Error in GEOSGeom_getXMin_r")
    end
    return out[]
end

"""
    getYMin(obj::Geometry, context::GEOSContext = get_context(obj))

Finds the minimum Y value in the geometry
"""
function getYMin(obj::Geometry, context::GEOSContext = get_context(obj))
    out = Ref{Float64}()
    result = GEOSGeom_getYMin_r(context, obj, out)
    if result == 0
        error("LibGEOS: Error in GEOSGeom_getYMin_r")
    end
    return out[]
end

"""
    getXMax(obj::Geometry, context::GEOSContext = get_context(obj))

Finds the maximum X value in the geometry
"""
function getXMax(obj::Geometry, context::GEOSContext = get_context(obj))
    out = Ref{Float64}()
    result = GEOSGeom_getXMax_r(context, obj, out)
    if result == 0
        error("LibGEOS: Error in GEOSGeom_getXMax_r")
    end
    return out[]
end

"""
    getYMax(obj::Geometry, context::GEOSContext = get_context(obj))

Finds the maximum Y value in the geometry
"""
function getYMax(obj::Geometry, context::GEOSContext = get_context(obj))
    out = Ref{Float64}()
    result = GEOSGeom_getYMax_r(context, obj, out)
    if result == 0
        error("LibGEOS: Error in GEOSGeom_getYMax_r")
    end
    return out[]
end


# TODO 02/2022: wait for libgeos release beyond 3.10.2 which will in include GEOSGeom_getExtent_r
# Note: This is not in as of the current GEOS_jll 3.10.2...
# """
#     getExtent(geom, context=get_global_context())

# Retrieves the extent (xmin, ymin, xmax, ymax) of the geometry
# """
# function getExtent(ptr::GEOSGeom, context::GEOSContext = get_global_context())
#     out = Vector{Float64}(undef, 4)
#     result = GEOSGeom_getExtent_r(
#         context,
#         ptr,
#         Ref(out, 1),
#         Ref(out, 2),
#         Ref(out, 3),
#         Ref(out, 4),
#     )
#     if result == 0
#         error("LibGEOS: Error in GEOSGeom_getExtent_r")
#     end
#     return out
# end

# Call only on LINESTRING, and must be freed by caller (Returns NULL on exception)
function getPoint(
    obj::Union{LineString,LinearRing},
    n::Integer,
    context::GEOSContext = get_context(obj),
)
    if !(0 < n <= numPoints(obj, context))
        error(
            "LibGEOS: n=$n is out of bounds for LineString with numPoints=$(numPoints(obj, context))",
        )
    end
    result = GEOSGeomGetPointN_r(context, obj, n - 1)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeomGetPointN")
    end
    Point(result, context)
end

# Call only on LINESTRING, and must be freed by caller (Returns NULL on exception)
function startPoint(
    obj::Union{LineString,LinearRing},
    context::GEOSContext = get_context(obj),
)
    result = GEOSGeomGetStartPoint_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeomGetStartPoint")
    end
    Point(result, context)
end

# Call only on LINESTRING, and must be freed by caller (Returns NULL on exception)
function endPoint(
    obj::Union{LineString,LinearRing},
    context::GEOSContext = get_context(obj),
)
    result = GEOSGeomGetEndPoint_r(context, obj)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeomGetEndPoint")
    end
    Point(result, context)
end

# -----
# Misc functions
# -----
function area(obj::Geometry, context::GEOSContext = get_context(obj))
    out = Ref{Float64}()
    # Return 0 on exception, 1 otherwise
    result = GEOSArea_r(context, obj, out)
    if result == 0
        error("LibGEOS: Error in GEOSArea")
    end
    out[]
end

function geomLength(obj::Geometry, context::GEOSContext = get_context(obj))
    out = Ref{Float64}()
    # Return 0 on exception, 1 otherwise
    result = GEOSLength_r(context, obj, out)
    if result == 0
        error("LibGEOS: Error in GEOSLength")
    end
    out[]
end

function distance(obj1::Geometry, obj2::Geometry, context::GEOSContext = get_context(obj1))
    out = Ref{Float64}()
    # Return 0 on exception, 1 otherwise
    result = GEOSDistance_r(context, obj1, obj2, out)
    if result == 0
        error("LibGEOS: Error in GEOSDistance")
    end
    out[]
end

function hausdorffdistance(
    obj1::Geometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    out = Ref{Float64}()
    # Return 0 on exception, 1 otherwise
    result = GEOSHausdorffDistance_r(context, obj1, obj2, out)
    if result == 0
        error("LibGEOS: Error in GEOSHausdorffDistance")
    end
    out[]
end

function hausdorffdistance(
    obj1::Geometry,
    obj2::Geometry,
    densifyFrac::Real,
    context::GEOSContext = get_context(obj1),
)
    out = Ref{Float64}()
    # Return 0 on exception, 1 otherwise
    result = GEOSHausdorffDistanceDensify_r(context, obj1, obj2, densifyFrac, out)
    if result == 0
        error("LibGEOS: Error in GEOSHausdorffDistanceDensify")
    end
    out[]
end

# Returns the closest points of the two geometries.
# The first point comes from g1 geometry and the second point comes from g2.
# Return 0 on exception, the closest points of the two geometries otherwise.
function nearestPoints(
    obj1::Geometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    points = GEOSNearestPoints_r(context, obj1, obj2)
    if points == C_NULL
        return Point[]
    else
        return Point[
            Point(getCoordinates(points, 1, context), context),
            Point(getCoordinates(points, 2, context), context),
        ]
    end
end

function nearestPoints(
    obj1::PreparedGeometry,
    obj2::Geometry,
    context::GEOSContext = get_context(obj1),
)
    points = GEOSPreparedNearestPoints_r(context, obj1, obj2)
    if points == C_NULL
        return Point[]
    else
        return Point[
            Point(getCoordinates(points, 1, context), context),
            Point(getCoordinates(points, 2, context), context),
        ]
    end
end

# -----
# Precision functions
# -----

"""
    getPrecision(obj::Geometry, context::GEOSContext = get_context(obj))

Return the size of the geometry's precision grid, 0 for FLOATING precision.
"""
function getPrecision(obj::Geometry, context::GEOSContext = get_context(obj))
    GEOSGeom_getPrecision_r(context, obj)
end

"""
    setPrecision(obj::Geometry, grid;
        flags = GEOS_PREC_VALID_OUTPUT,
        context::GEOSContext = get_context(obj))

Change the rounding precision on a geometry. This will affect the precision of the existing geometry as well as any geometries derived from this geometry using overlay functions. The output will be a valid GEOSGeometry.

Note that operations will always be performed in the precision of the geometry with higher precision (smaller "grid"). That same precision will be attached to the operation outputs.

In the Default and `GEOS_PREC_KEEP_COLLAPSED` modes invalid input may cause an error to occur, unless the invalidity is below the scale of the requested precision

There are only 3 modes. The `GEOS_PREC_NO_TOPO` mode takes precedence over `GEOS_PREC_KEEP_COLLAPSED`. So the combination `GEOS_PREC_NO_TOPO || GEOS_PREC_KEEP_COLLAPSED` has the same semantics as `GEOS_PREC_NO_TOPO`

# Parameters
* `obj`	Input geometry
* `grid`	cell size of grid to round coordinates to, or 0 for FLOATING precision
* `flags`	The bitwise OR of members of the `GEOSPrecisionRules` enum

# Returns
The precision reduced result. Caller must free with `GEOSGeom_destroy()` NULL on exception.

"""
function setPrecision(
    obj::Geometry,
    grid::Real;
    flags::Union{GEOSPrecisionRules,Integer} = GEOS_PREC_VALID_OUTPUT,
    context::GEOSContext = get_context(obj),
)
    result = geomFromGEOS(GEOSGeom_setPrecision_r(context, obj, grid, flags), context)
    if result == C_NULL
        error("LibGEOS: Error in GEOSGeom_setPrecision_r")
    end
    result
end
