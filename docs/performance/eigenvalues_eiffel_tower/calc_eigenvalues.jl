using JuliaFEM
using JuliaFEM.Preprocess
using JuliaFEM.Postprocess

model = "EIFFEL_TOWER_TET10_220271"
mesh = joinpath("eiffel-tower", "$model.inp")
results = "$model"

@timeit to "run performance test" begin

@timeit to "parse input data" begin
    mesh = abaqus_read_mesh(mesh)
    for (nid, ncoords) in mesh.nodes
        mesh.nodes[nid] = 304.8 * ncoords
    end
    info("element sets = ", collect(keys(mesh.element_sets)))
    info("surface sets = ", collect(keys(mesh.surface_sets)))
end

@timeit to "initialize model" begin
    tower = Problem(Elasticity, "tower", 3)
    tower.elements = create_elements(mesh, "TOWER")
    update!(tower, "youngs modulus", 210.0E3)
    update!(tower, "poissons ratio", 0.3)
    update!(tower, "density", 7.85E-9)

    support = Problem(Dirichlet, "fixed", 3, "displacement")
    support.elements = create_surface_elements(mesh, "SUPPORT")
    update!(support, "geometry", mesh.nodes)
    update!(support, "displacement 1", 0.0)
    update!(support, "displacement 2", 0.0)
    update!(support, "displacement 3", 0.0)
end

@timeit to "solve eigenvalue problem" begin
    solver = Solver(Modal, tower, support)
    solver.xdmf = Xdmf(results; overwrite=true)
    solver.properties.nev = 5
    solver.properties.which = :SM
    solver()
    println("Eigenvalues: ", sqrt(solver.properties.eigvals) / (2*pi))
end

end

print_statistics()
