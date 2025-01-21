"""All Geometries in LibGEOS are an AbstractGeometry."""
abstract type AbstractGeometry end

"""
All MultiGeometries in LibGEOS are an AbstractMultiGeometry.

Used to specialize on methods that only work on MultiGeometries, like `ngeom`.
"""
abstract type AbstractMultiGeometry <: AbstractGeometry end

function Base.show(io::IO, geo::AbstractGeometry)
    compact = get(io, :compact, false)
    if compact
        print(io, typeof(geo), "(...)")
    else
        s = writegeom(geo)
        print(io, s)
    end
end

function open_issue_if_conversion_makes_sense(T::Type, id)
    msg = """LibGEOS: Can't convert a pointer to an element with a GeomType ID id = $id (GEOSGeomType = $(GEOSGeomTypes(id)))
    to a geometry of type $T (yet).
    Please open an issue if you think this conversion makes sense.")
    """
    error(msg)
end

mutable struct Point <: AbstractGeometry
    ptr::GEOSGeom
    context::GEOSContext
    function Point(obj::Point, context::GEOSContext = get_global_context())
        point = new(cloneGeom(obj, context), context)
        finalizer(destroyGeom, point)
        point
    end
    # create a point from a pointer - only makese sense if it is a pointer to a point, otherwise error
    function Point(obj::GEOSGeom, context::GEOSContext = get_global_context())
        id = LibGEOS.geomTypeId(obj, context)
        point = if id == GEOS_POINT
            point = new(obj, context)
        else
            open_issue_if_conversion_makes_sense(Point, id)
        end
        finalizer(destroyGeom, point)
        point
    end
    # create a point from a vector of floats
    Point(coords::Vector{Float64}, context::GEOSContext = get_global_context()) =
        Point(createPoint(coords, context), context)
    Point(x::Real, y::Real, context::GEOSContext = get_global_context()) =
        Point(createPoint(x, y, context), context)
    Point(x::Real, y::Real, z::Real, context::GEOSContext = get_global_context()) =
        Point(createPoint(x, y, z, context), context)
end

mutable struct MultiPoint <: AbstractMultiGeometry
    ptr::GEOSGeom
    context::GEOSContext
    function MultiPoint(obj::Point, context::GEOSContext = get_global_context())
        multipoint = new(
            createCollection(GEOS_MULTIPOINT, [cloneGeom(obj, context)], context),
            context,
        )
        finalizer(destroyGeom, multipoint)
        multipoint
    end
    function MultiPoint(obj::MultiPoint, context::GEOSContext = get_global_context())
        multipoint = new(cloneGeom(obj, context), context)
        finalizer(destroyGeom, multipoint)
        multipoint
    end
    # create a multipoint from a pointer - only makes sense if it is a pointer to a multipoint
    # or to a point, otherwise error
    function MultiPoint(obj::GEOSGeom, context::GEOSContext = get_global_context())
        id = LibGEOS.geomTypeId(obj, context)
        multipoint = if id == GEOS_MULTIPOINT
            new(obj, context)
        elseif id == GEOS_POINT
            new(createCollection(GEOS_MULTIPOINT, [cloneGeom(obj, context)], context), context)
        else
            open_issue_if_conversion_makes_sense(MultiPoint, id)
        end
        finalizer(destroyGeom, multipoint)
        multipoint
    end
    # create a multipoint frome a vector of vector coordinates
    MultiPoint(
        multipoint::Vector{Vector{Float64}},
        context::GEOSContext = get_global_context(),
    ) = MultiPoint(
        createCollection(
            GEOS_MULTIPOINT,
            GEOSGeom[createPoint(coords, context) for coords in multipoint],
            context,
        ),
        context,
    )
    # create a multipoint from a list of points
    MultiPoint(points::Vector{LibGEOS.Point}, context::GEOSContext = get_context(points)) =
        MultiPoint(
            createCollection(GEOS_MULTIPOINT, cloneGeom.(points, Ref(context)), context),
            context,
        )
end

mutable struct LineString <: AbstractGeometry
    ptr::GEOSGeom
    context::GEOSContext
    function LineString(obj::LineString, context::GEOSContext = get_global_context())
        line = new(cloneGeom(obj, context), context)
        finalizer(destroyGeom, line)
        line
    end
    # create a linestring from a linestring pointer, otherwise error
    function LineString(obj::GEOSGeom, context::GEOSContext = get_global_context())
        id = LibGEOS.geomTypeId(obj, context)
        line = if id == GEOS_LINESTRING
            new(obj, context)
        else
            open_issue_if_conversion_makes_sense(LineString, id)
        end
        finalizer(destroyGeom, line)
        line
    end
    # create a linestring from a vector of points
    function LineString(
        coords::Vector{Vector{Float64}},
        context::GEOSContext = get_global_context(),
    )
        line = new(createLineString(coords, context), context)
        finalizer(destroyGeom, line)
        line
    end
    function LineString(coords::Vector{Point}, context::GEOSContext = get_global_context())
        line = new(createLineString(coords, context), context)
        finalizer(destroyGeom, line)
        line
    end
end

mutable struct MultiLineString <: AbstractMultiGeometry
    ptr::GEOSGeom
    context::GEOSContext
    function MultiLineString(
        obj::MultiLineString,
        context::GEOSContext = get_global_context(),
    )
        multiline = new(cloneGeom(obj, context), context)
        finalizer(destroyGeom, multiline)
        multiline
    end
    function MultiLineString(obj::LineString, context::GEOSContext = get_global_context())
        multiline = new(
            createCollection(GEOS_MULTILINESTRING, [cloneGeom(obj, context)], context),
            context,
        )
        finalizer(destroyGeom, multiline)
        multiline
    end
    # create a multiline string from a multilinestring or a linestring pointer, else error
    function MultiLineString(obj::GEOSGeom, context::GEOSContext = get_global_context())
        id = LibGEOS.geomTypeId(obj, context)
        multiline = if id == GEOS_MULTILINESTRING
            new(obj, context)
        elseif id == GEOS_LINESTRING
            new(
                createCollection(GEOS_MULTILINESTRING, [cloneGeom(obj, context)], context),
                context,
            )
        else
            open_issue_if_conversion_makes_sense(MultiLineString, id)
        end
        finalizer(destroyGeom, multiline)
        multiline
    end
    # create a multilinestring from a list of linestring coordinates
    MultiLineString(
        multiline::Vector{Vector{Vector{Float64}}},
        context::GEOSContext = get_global_context(),
    ) = MultiLineString(
        createCollection(
            GEOS_MULTILINESTRING,
            GEOSGeom[createLineString(coords, context) for coords in multiline],
            context,
        ),
        context,
    )
    MultiLineString(
        multiline::Vector{LineString},
        context::GEOSContext = get_global_context(),
    ) = MultiLineString(
        createCollection(
            GEOS_MULTILINESTRING,
            GEOSGeom[cloneGeom(ls, context) for ls in multiline],
            context,
        ),
        context,
    )
end

mutable struct LinearRing <: AbstractGeometry
    ptr::GEOSGeom
    context::GEOSContext
    function LinearRing(obj::LinearRing, context::GEOSContext = get_global_context())
        ring = new(cloneGeom(obj, context), context)
        finalizer(destroyGeom, ring)
        ring
    end
    # create a linear ring from a linear ring pointer, otherwise error
    function LinearRing(obj::GEOSGeom, context::GEOSContext = get_global_context())
        id = LibGEOS.geomTypeId(obj, context)
        ring = if id == GEOS_LINEARRING
            new(obj, context)
        else
            open_issue_if_conversion_makes_sense(LinearRing, id)
        end
        finalizer(destroyGeom, ring)
        ring
    end
    # create linear ring from a list of coordinates -
    # first and last coordinates must be the same
    function LinearRing(
        coords::Vector{Vector{Float64}},
        context::GEOSContext = get_global_context(),
    )
        ring = new(createLinearRing(coords, context), context)
        finalizer(destroyGeom, ring)
        ring
    end
end

mutable struct Polygon <: AbstractGeometry
    ptr::GEOSGeom
    context::GEOSContext
    function Polygon(obj::Polygon, context::GEOSContext = get_global_context())
        polygon = new(cloneGeom(obj, context), context)
        finalizer(destroyGeom, polygon)
        polygon
    end
    function Polygon(obj::LinearRing, context::GEOSContext = get_global_context())
        polygon = new(createPolygon(cloneGeom(obj, context), context), context)
        finalizer(destroyGeom, polygon)
        polygon
    end
    # create polygon using GEOSGeom pointer - only makes sense if pointer points to a polygon or a linear ring to start with.
    function Polygon(obj::GEOSGeom, context::GEOSContext = get_global_context())
        id = LibGEOS.geomTypeId(obj, context)
        polygon = if id == GEOS_POLYGON
            new(obj, context)
        elseif id == GEOS_LINEARRING
            new(createPolygon(obj, context), context)
        else
            open_issue_if_conversion_makes_sense(Polygon, id)
        end
        finalizer(destroyGeom, polygon)
        polygon
    end
    # using vector of coordinates in following form:
    # [[exterior], [hole1], [hole2], ...] where exterior and holeN are coordinates where the first and last point are the same
    function Polygon(
        coords::Vector{Vector{Vector{Float64}}},
        context::GEOSContext = get_global_context(),
    )
        exterior = createLinearRing(coords[1], context)
        interiors = GEOSGeom[createLinearRing(lr, context) for lr in coords[2:end]]
        polygon = new(createPolygon(exterior, interiors, context), context)
        finalizer(destroyGeom, polygon)
        polygon
    end
    # using multiple linear rings to form polygon with holes - exterior linear ring will be polygon boundary and list of interior linear rings will form holes
    Polygon(
        exterior::LinearRing,
        holes::Vector{LinearRing},
        context::GEOSContext = get_context(exterior),
    ) = Polygon(
        createPolygon(
            cloneGeom(exterior, context),
            cloneGeom.(holes, Ref(context)),
            context,
        ),
        context,
    )
end

mutable struct MultiPolygon <: AbstractMultiGeometry
    ptr::GEOSGeom
    context::GEOSContext
    function MultiPolygon(obj::MultiPolygon, context::GEOSContext = get_global_context())
        multipolygon = new(cloneGeom(obj, context), context)
        finalizer(destroyGeom, multipolygon)
        multipolygon
    end
    function MultiPolygon(obj::Polygon, context::GEOSContext = get_global_context())
        multipolygon = new(
            createCollection(GEOS_MULTIPOLYGON, [cloneGeom(obj, context)], context),
            context,
        )
        finalizer(destroyGeom, multipolygon)
        multipolygon
    end
    # create multipolygon using a multipolygon or polygon pointer, else error
    function MultiPolygon(obj::GEOSGeom, context::GEOSContext = get_global_context())
        id = LibGEOS.geomTypeId(obj, context)
        multipolygon = if id == GEOS_MULTIPOLYGON
            new(obj, context)
        elseif id == GEOS_POLYGON
            new(
                createCollection(GEOS_MULTIPOLYGON, [cloneGeom(obj, context)], context),
                context,
            )
        else
            open_issue_if_conversion_makes_sense(MultiPolygon, id)
        end
        finalizer(destroyGeom, multipolygon)
        multipolygon
    end

    # create multipolygon from list of Polygon objects
    MultiPolygon(polygons::Vector{Polygon}, context::GEOSContext = get_context(polygons)) =
        MultiPolygon(
            createCollection(
                GEOS_MULTIPOLYGON,
                cloneGeom.(polygons, Ref(context)),
                context,
            ),
            context,
        )

    # create multipolygon using list of polygon coordinates - note that each polygon can have holes as explained above in Polygon comments
    MultiPolygon(
        multipolygon::Vector{Vector{Vector{Vector{Float64}}}},
        context::GEOSContext = get_global_context(),
    ) = MultiPolygon(
        createCollection(
            GEOS_MULTIPOLYGON,
            GEOSGeom[
                createPolygon(
                    createLinearRing(coords[1], context),
                    GEOSGeom[createLinearRing(c, context) for c in coords[2:end]],
                    context,
                ) for coords in multipolygon
            ],
            context,
        ),
        context,
    )
end

mutable struct GeometryCollection <: AbstractMultiGeometry
    ptr::GEOSGeom
    context::GEOSContext
    function GeometryCollection(
        obj::GeometryCollection,
        context::GEOSContext = get_global_context(),
    )
        geometrycollection = new(cloneGeom(obj, context), context)
        finalizer(destroyGeom, geometrycollection)
        geometrycollection
    end
    # create a geometric collection from a pointer to a geometric collection, else error
    function GeometryCollection(obj::GEOSGeom, context::GEOSContext = get_global_context())
        id = LibGEOS.geomTypeId(obj, context)
        geometrycollection = if id == GEOS_GEOMETRYCOLLECTION
            new(obj, context)
        else
            open_issue_if_conversion_makes_sense(GeometryCollection, id)
        end
        finalizer(destroyGeom, geometrycollection)
        geometrycollection
    end
    # create a geometric collection from a list of pointers to geometric objects
    GeometryCollection(
        collection::AbstractVector,
        context::GEOSContext = get_global_context(),
    ) = GeometryCollection(
        createCollection(GEOS_GEOMETRYCOLLECTION, collection, context),
        context,
    )
    GeometryCollection(
        collection::Vector{<:AbstractGeometry},
        context::GEOSContext = get_global_context(),
    ) = GeometryCollection(
        createCollection(
            GEOS_GEOMETRYCOLLECTION,
            GEOSGeom[cloneGeom(geom, context) for geom in collection],
            context,
        ),
        context,
    )
end

mutable struct CircularString <: AbstractGeometry
    ptr::GEOSGeom
    context::GEOSContext
    function CircularString(
        obj::CircularString,
        context::GEOSContext = get_global_context(),
    )
        circularstring = new(cloneGeom(obj, context), context)
        finalizer(destroyGeom, circularstring)
        circularstring
    end
    # create a circularstring from a circularstring pointer, otherwise error
    function CircularString(obj::GEOSGeom, context::GEOSContext = get_global_context())
        id = LibGEOS.geomTypeId(obj, context)
        circularstring = if id == GEOS_CIRCULARSTRING
            new(obj, context)
        else
            open_issue_if_conversion_makes_sense(CircularString, id)
        end
        finalizer(destroyGeom, circularstring)
        circularstring
    end
    # create a circularstring from a vector of points
    function CircularString(
        coords::Vector{Vector{Float64}},
        context::GEOSContext = get_global_context(),
    )
        circularstring = new(createCircularString(coords, context), context)
        finalizer(destroyGeom, circularstring)
        circularstring
    end
    function CircularString(coords::Vector{Point}, context::GEOSContext = get_global_context())
        circularstring = new(createCircularString(coords, context), context)
        finalizer(destroyGeom, circularstring)
        circularstring
    end
end

mutable struct CompoundCurve <: AbstractGeometry
    ptr::GEOSGeom
    context::GEOSContext
    function CompoundCurve(obj::CompoundCurve, context::GEOSContext = get_global_context())
        compoundcurve = new(cloneGeom(obj, context), context)
        finalizer(destroyGeom, compoundcurve)
        compoundcurve
    end
    # create a compoundcurve from a compoundcurve pointer, otherwise error
    function CompoundCurve(obj::GEOSGeom, context::GEOSContext = get_global_context())
        id = LibGEOS.geomTypeId(obj, context)
        compoundcurve = if id == GEOS_COMPOUNDCURVE
            new(obj, context)
        else
            open_issue_if_conversion_makes_sense(CompoundCurve, id)
        end
        finalizer(destroyGeom, compoundcurve)
        compoundcurve
    end
end

mutable struct CurvePolygon <: AbstractGeometry
    ptr::GEOSGeom
    context::GEOSContext
    function CurvePolygon(obj::CurvePolygon, context::GEOSContext = get_global_context())
        curvepolygon = new(cloneGeom(obj, context), context)
        finalizer(destroyGeom, curvepolygon)
        curvepolygon
    end
    function CurvePolygon(obj::Union{LinearRing,CircularString,CompoundCurve}, context::GEOSContext = get_global_context())
        curvepolygon = new(createCurvePolygon(cloneGeom(obj, context), context), context)
        finalizer(destroyGeom, curvepolygon)
        curvepolygon
    end
    function CurvePolygon(obj::GEOSGeom, context::GEOSContext = get_global_context())
        id = LibGEOS.geomTypeId(obj, context)
        curvepolygon = if id == GEOS_CURVEPOLYGON
            new(obj, context)
        elseif id in [GEOS_LINEARRING,GEOS_CIRCULARSTRING,GEOS_COMPOUNDCURVE]
            new(createCurvePolygon(obj, context), context)
        else
            open_issue_if_conversion_makes_sense(CurvePolygon, id)
        end
        finalizer(destroyGeom, curvepolygon)
        curvepolygon
    end
    # using vector of coordinates in following form:
    # [[exterior], [hole1], [hole2], ...] where exterior and holeN are coordinates where the first and last point are the same
    function CurvePolygon(
        coords::Vector{Vector{Vector{Float64}}},
        context::GEOSContext = get_global_context(),
    )
        exterior = createLinearRing(coords[1], context)
        interiors = GEOSGeom[createLinearRing(lr, context) for lr in coords[2:end]]
        curvepolygon = new(createCurvePolygon(exterior, interiors, context), context)
        finalizer(destroyGeom, curvepolygon)
        curvepolygon
    end
    # using multiple rings to form polygon with holes - exterior ring will be polygon boundary and list of interior rings will form holes
    CurvePolygon(
        exterior::Union{LinearRing,CircularString,CompoundCurve},
        holes::Vector{Union{LinearRing,CircularString,CompoundCurve}},
        context::GEOSContext = get_context(exterior),
    ) = CurvePolygon(
        createCurvePolygon(
            cloneGeom(exterior, context),
            cloneGeom.(holes, Ref(context)),
            context,
        ),
        context,
    )
  
end

mutable struct MultiCurve <: AbstractGeometry
    ptr::GEOSGeom
    context::GEOSContext
    function MultiCurve(obj::MultiCurve, context::GEOSContext = get_global_context())
        multicurve = new(cloneGeom(obj, context), context)
        finalizer(destroyGeom, multicurve)
        multicurve
    end
    # create a compoundcurve from a compoundcurve pointer, otherwise error
    function MultiCurve(obj::GEOSGeom, context::GEOSContext = get_global_context())
        id = LibGEOS.geomTypeId(obj, context)
        multicurve = if id == GEOS_MULTICURVE
            new(obj, context)
        else
            open_issue_if_conversion_makes_sense(MultiCurve, id)
        end
        finalizer(destroyGeom, multicurve)
        multicurve
    end
end

mutable struct MultiSurface <: AbstractGeometry
    ptr::GEOSGeom
    context::GEOSContext
    function MultiSurface(obj::MultiSurface, context::GEOSContext = get_global_context())
        multisurface = new(cloneGeom(obj, context), context)
        finalizer(destroyGeom, multisurface)
        multisurface
    end
    # create a multisurface from a multisurface, otherwise error
    function MultiSurface(obj::GEOSGeom, context::GEOSContext = get_global_context())
        id = LibGEOS.geomTypeId(obj, context)
        multisurface = if id == GEOS_MULTISURFACE
            new(obj, context)
        else
            open_issue_if_conversion_makes_sense(MultiSurface, id)
        end
        finalizer(destroyGeom, multisurface)
        multisurface
    end
end

const Geometry = Union{
    Point,
    MultiPoint,
    LineString,
    MultiLineString,
    LinearRing,
    Polygon,
    MultiPolygon,
    GeometryCollection,
    CircularString,
    CompoundCurve,
    CurvePolygon,
    MultiCurve,
    MultiSurface,
}

"""
    clone(obj::Geometry, context=get_context(obj))

Create a deep copy of obj, optionally also moving it to a new context.
"""
function clone(obj::Geometry, context = get_context(obj))
    G = typeof(obj)
    # Note that all Geometry constructors
    # implicitly clone the pointer, in the following line
    G(obj, context)::G
end

"""

    get_context(obj::AbstractGeometry)::GEOSContext

Return the `GEOSContext` that `obj` belongs to. If obj is not a GEOS object with
a context, return the global context.
"""
get_context(obj::Geometry) = obj.context
get_context(obj::Any) = get_global_context()

mutable struct PreparedGeometry{G<:AbstractGeometry} <: AbstractGeometry
    ptr::Ptr{GEOSPreparedGeometry}
    ownedby::G
end

get_context(obj::PreparedGeometry) = get_context(obj.ownedby)

const geomtypes = [
    Point,
    LineString,
    LinearRing,
    Polygon,
    MultiPoint,
    MultiLineString,
    MultiPolygon,
    GeometryCollection,
    CircularString,
    CompoundCurve,
    CurvePolygon,
    MultiCurve,
    MultiSurface,
]

const HasCoordSeq = Union{LineString,LinearRing,Point}
"""

    coordinates!(out::Vector{Float64}, geo::$HasCoordSeq, i::Integer)
    coordinates!(out::Vector{Float64}, geo::Point)

Copy the coordinates of the ith point of geo into `out`.
"""
function coordinates!(
    out,
    geo::HasCoordSeq,
    i::Integer,
    ctx::GEOSContext = get_context(geo),
)
    GC.@preserve out geo begin
        seq = GEOSGeom_getCoordSeq_r(ctx, geo)::Ptr
        getCoordinates!(out, seq, i, ctx)
    end
end
function coordinates!(out, geo::Point, ctx::GEOSContext = get_context(geo))
    coordinates!(out, geo, 1, ctx)
end

function has_coord_seq(geo::AbstractGeometry)
    false
end
function has_coord_seq(::HasCoordSeq)
    true
end

Base.@kwdef struct IsApprox
    atol::Float64 = 0.0
    rtol::Float64 = sqrt(eps(Float64))
end

function Base.:(==)(geo1::AbstractGeometry, geo2::AbstractGeometry)::Bool
    compare(==, geo1, geo2)
end
function Base.isequal(geo1::AbstractGeometry, geo2::AbstractGeometry)::Bool
    compare(isequal, geo1, geo2)
end
function Base.isapprox(geo1::AbstractGeometry, geo2::AbstractGeometry; kw...)::Bool
    compare(IsApprox(; kw...), geo1, geo2)
end
function compare(
    cmp,
    geo1::AbstractGeometry,
    geo2::AbstractGeometry,
    ctx = get_context(geo1),
)::Bool
    (typeof(geo1) === typeof(geo2)) || return false
    if (geo1 === geo2) && (cmp === isequal)
        return true
    end
    if has_coord_seq(geo1)
        return compare_coord_seqs(cmp, geo1, geo2, ctx)
    else
        ng1 = ngeom(geo1)
        ng2 = ngeom(geo2)
        ng1 == ng2 || return false
        for i = 1:ng1
            compare(cmp, getgeom(geo1, i), getgeom(geo2, i), ctx) || return false
        end
    end
    return true
end

npoints(pt::Point) = 1
npoints(geo::HasCoordSeq) = GeoInterface.ngeom(geo)

function compare_coord_seqs(cmp, geo1, geo2, ctx)
    ncoords1 = GeoInterface.ncoord(geo1)
    ncoords2 = GeoInterface.ncoord(geo2)
    ncoords1 == ncoords2 || return false
    ncoords1 == 0 && return true
    np1 = npoints(geo1)
    np2 = npoints(geo2)
    np1 == np2 || return false
    coords1 = Vector{Float64}(undef, ncoords1)
    coords2 = Vector{Float64}(undef, ncoords1)
    for i = 1:np1
        coordinates!(coords1, geo1, i, ctx)
        coordinates!(coords2, geo2, i, ctx)
        cmp(coords1, coords2) || return false
    end
    return true
end

function compare_coord_seqs(cmp::IsApprox, geo1, geo2, ctx)
    ncoords1 = GeoInterface.ncoord(geo1)
    ncoords2 = GeoInterface.ncoord(geo2)
    ncoords1 == ncoords2 || return false
    ncoords1 == 0 && return true
    @assert ncoords1 in 2:3
    ncoords1 == ncoords2 || return false
    np1 = npoints(geo1)
    np2 = npoints(geo2)
    np1 == np2 || return false
    coords1 = Vector{Float64}(undef, ncoords1)
    coords2 = Vector{Float64}(undef, ncoords1)
    # isapprox of two vectors is calculated using their euclidean norms and the norm of their difference
    # we compute (the squares) of these norms in an allocation free way
    s1 = 0.0
    s2 = 0.0
    s12 = 0.0
    for i = 1:np1
        coordinates!(coords1, geo1, i, ctx)
        coordinates!(coords2, geo2, i, ctx)
        if ncoords1 == 2
            x1, y1 = coords1
            x2, y2 = coords2
            s12 += (x1 - x2)^2 + (y1 - y2)^2
        else
            x1, y1, z1 = coords1
            x2, y2, z2 = coords2
            s12 += (x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2
        end
        s1 += sum(abs2, coords1)
        s2 += sum(abs2, coords2)
    end
    return sqrt(s12) <= cmp.atol + cmp.rtol * sqrt(max(s1, s2))
end

typesalt(::Type{GeometryCollection}) = 0xd1fd7c6403c36e5b
typesalt(::Type{PreparedGeometry}) = 0xbc1a26fe2f5b7537
typesalt(::Type{LineString}) = 0x712352fe219fca15
typesalt(::Type{LinearRing}) = 0xac7644fd36955ef1
typesalt(::Type{MultiLineString}) = 0x85aff0a53a2f2a32
typesalt(::Type{MultiPoint}) = 0x6213e67dbfd3b570
typesalt(::Type{MultiPolygon}) = 0xff2f957b4cdb5832
typesalt(::Type{Point}) = 0x4b5c101d3843160e
typesalt(::Type{Polygon}) = 0xa5c895d62ef56723
typesalt(::Type{CircularString}) = 0x78ba4f50813d8da9
typesalt(::Type{CompoundCurve}) = 0x44258e194220dc61
typesalt(::Type{CurvePolygon}) = 0xdd0a2660d0239f1d
typesalt(::Type{MultiCurve}) = 0x0641e0678af4d103
typesalt(::Type{MultiSurface}) = 0x9f6a2cba51468ea5

function Base.hash(geo::AbstractGeometry, h::UInt)::UInt
    h = hash(typesalt(typeof(geo)), h)
    if has_coord_seq(geo)
        return hash_coord_seq(geo, h)
    else
        for i = 1:ngeom(geo)
            h = hash(getgeom(geo, i), h)
        end
    end
    return h
end
function hash_coord_seq(geo::HasCoordSeq, h::UInt)::UInt
    nc = GeoInterface.ncoord(geo)
    if nc == 0
        return h
    end
    buf = Vector{Float64}(undef, nc)
    ctx = get_context(geo)
    for i = 1:npoints(geo)
        coordinates!(buf, geo, i, ctx)
        h = hash(buf, h)
    end
    return h
end

# teach ccall how to get the pointer to pass to libgeos
# this way the Julia compiler will track the lifetimes for us
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::AbstractGeometry) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::GEOSContext) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::WKTReader) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::WKTWriter) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::WKBReader) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::WKBWriter) = x.ptr

const GEOMTYPE = Dict{GEOSGeomTypes,Symbol}(
    GEOS_POINT => :Point,
    GEOS_LINESTRING => :LineString,
    GEOS_LINEARRING => :LinearRing,
    GEOS_POLYGON => :Polygon,
    GEOS_MULTIPOINT => :MultiPoint,
    GEOS_MULTILINESTRING => :MultiLineString,
    GEOS_MULTIPOLYGON => :MultiPolygon,
    GEOS_GEOMETRYCOLLECTION => :GeometryCollection,
    GEOS_CIRCULARSTRING => :CircularString,
    GEOS_COMPOUNDCURVE => :CompoundCurve,
    GEOS_CURVEPOLYGON => :CurvePolygon,
    GEOS_MULTICURVE => :MultiCurve,
    GEOS_MULTISURFACE => :MultiSurface,
)

function geomFromGEOS(
    ptr::Union{Geometry,Ptr{Cvoid}},
    context::GEOSContext = get_global_context(),
)
    id = geomTypeId(ptr, context)
    if id == GEOS_POINT
        return Point(ptr, context)
    elseif id == GEOS_LINESTRING
        return LineString(ptr, context)
    elseif id == GEOS_LINEARRING
        return LinearRing(ptr, context)
    elseif id == GEOS_POLYGON
        return Polygon(ptr, context)
    elseif id == GEOS_MULTIPOINT
        return MultiPoint(ptr, context)
    elseif id == GEOS_MULTILINESTRING
        return MultiLineString(ptr, context)
    elseif id == GEOS_MULTIPOLYGON
        return MultiPolygon(ptr, context)
    elseif id == GEOS_GEOMETRYCOLLECTION
        return GeometryCollection(ptr, context)
    elseif id == GEOS_CIRCULARSTRING
        return CircularString(ptr, context)
    elseif id == GEOS_COMPOUNDCURVE
        return CompoundCurve(ptr, context)
    elseif id == GEOS_CURVEPOLYGON
        return CurvePolygon(ptr, context)
    elseif id == GEOS_MULTICURVE
        return MultiCurve(ptr, context)
    elseif id == GEOS_MULTISURFACE
        return MultiSurface(ptr, context)
    else
        throw(ErrorException("Geometric type with code $id not implemented."))
    end
end
