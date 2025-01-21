module LibGEOS

using GEOS_jll
using GeoInterface
using GeoInterfaceRecipes
using Extents
using CEnum

const GI = GeoInterface

export CircularString,
    CompoundCurve,
    CurvePolygon,
    GeometryCollection,
    LineString,
    LinearRing,
    MultiCurve,
    MultiLineString,
    MultiPoint,
    MultiPolygon,
    MultiSurface,
    Point,
    Polygon,
    STRtree

export area,
    boundary,
    buffer,
    bufferWithStyle,
    centroid,
    constrainedDelaunayTriangulation,
    containsproperly,
    convexhull,
    coveredby,
    covers,
    crosses,
    delaunayTriangulation,
    delaunayTriangulationEdges,
    difference,
    disjoint,
    distance,
    endPoint,
    envelope,
    equals,
    equalsexact,
    exteriorRing,
    geomLength,
    getGeometries,
    getGeometry,
    getPrecision,
    getXMax,
    getXMin,
    getYMax,
    getYMin,
    hasZ,
    hausdorffdistance,
    interiorRing,
    interiorRings,
    interpolate,
    interpolateNormalized,
    intersection,
    intersects,
    isClosed,
    isEmpty,
    isRing,
    isSimple,
    isValid,
    lineMerge,
    minimumRotatedRectangle,
    nearestPoints,
    node,
    numGeometries,
    numPoints,
    overlaps,
    pointOnSurface,
    polygonize,
    prepareGeom,
    project,
    projectNormalized,
    query,
    readgeom,
    setPrecision,
    sharedPaths,
    simplify,
    snap,
    startPoint,
    symmetricDifference,
    topologyPreserveSimplify,
    touches,
    unaryUnion,
    union,
    uniquePoints,
    within,
    writegeom

include("generated/libgeos_api.jl")
include("error.jl")
include("context.jl")
include("wellknown.jl")
include("geos_types.jl")
include("geos_functions.jl")
include("geo_interface.jl")
include("strtree.jl")
include("deprecated.jl")

function __init__()
    _GLOBAL_CONTEXT_ALLOWED[] = true
    _GLOBAL_CONTEXT[] = GEOSContext()
end

end  # module
