using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    LibraryProduct(prefix, String["libgeos_c"], :libgeos_c),
    LibraryProduct(prefix, String["libgeos"], :libgeos),
]

# Download binaries from hosted location
bin_prefix = "https://github.com/JuliaGeo/GEOSBuilder/releases/download/v3.6.2-1"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    Linux(:aarch64, :glibc) => ("$bin_prefix/GEOS.aarch64-linux-gnu.tar.gz", "70960076a32cee812d680bf1b61af69a0f9a9cfd0234082e2c76a70b77b9b7bc"),
    Linux(:armv7l, :glibc, :eabihf) => ("$bin_prefix/GEOS.arm-linux-gnueabihf.tar.gz", "d35ee61812def5f89213fe03aed4e4dd6f91f22fa8f789b68977befd5456c230"),
    Linux(:i686, :glibc) => ("$bin_prefix/GEOS.i686-linux-gnu.tar.gz", "55800622f0823352e8921ea728ec833737bf21289742bbf0f566ab52718ed853"),
    Windows(:i686) => ("$bin_prefix/GEOS.i686-w64-mingw32.tar.gz", "8fcbfe26c5ca57e87c06b9631e8bcb9d68c2acc995b0f4db6e4dedc5c6db019d"),
    Linux(:powerpc64le, :glibc) => ("$bin_prefix/GEOS.powerpc64le-linux-gnu.tar.gz", "80a6140b351d3b2b60b267a168e2a3dcc030f38b106251dcc79705a87673a31c"),
    MacOS(:x86_64) => ("$bin_prefix/GEOS.x86_64-apple-darwin14.tar.gz", "06b685e786d21ccaa7fe1c104f9b41934d50a49b18bcc8c9accad8b279811bc6"),
    Linux(:x86_64, :glibc) => ("$bin_prefix/GEOS.x86_64-linux-gnu.tar.gz", "3d16219c3050c23877140d211f39b4b1e44eef156336ae4167d7efef598531b6"),
    Windows(:x86_64) => ("$bin_prefix/GEOS.x86_64-w64-mingw32.tar.gz", "5771a603742173e2e4360bfcdfbbbe04075981f3e6366b33629633ac4c4db396"),
)

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
if haskey(download_info, platform_key())
    url, tarball_hash = download_info[platform_key()]
    if unsatisfied || !isinstalled(url, tarball_hash; prefix=prefix)
        # Download and install binaries
        install(url, tarball_hash; prefix=prefix, force=true, verbose=verbose)
    end
elseif unsatisfied
    # If we don't have a BinaryProvider-compatible .tar.gz to download, complain.
    # Alternatively, you could attempt to install from a separate provider,
    # build from source or something even more ambitious here.
    error("Your platform $(triplet(platform_key())) is not supported by this package!")
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), products)
