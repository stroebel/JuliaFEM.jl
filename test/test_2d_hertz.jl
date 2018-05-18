# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/JuliaFEM.jl/blob/master/LICENSE.md

using JuliaFEM
using JuliaFEM.Preprocess
using JuliaFEM.Postprocess
using FEMBase.Test: @test, @test_resource

add_elements! = JuliaFEM.add_elements!

# Read mesh file, have denser mesh `mesh1` and sparse `mesh2`

meshfile = @test_resource("2d_hertz_mesh.med")
meshname = "mesh2"
mesh = aster_read_mesh(meshfile, uppercase(meshname))
nnodes = length(mesh.nodes)
println("number of nodes: $nnodes")

# Create bodies, cylinder and block

cylinder = Problem(Elasticity, "CYLINDER", 2)
cylinder.properties.formulation = :plane_strain
cylinder_elements = create_elements(mesh, "CYLINDER")
add_elements!(cylinder, cylinder_elements)
update!(cylinder_elements, "youngs modulus", 70.0e3)
update!(cylinder_elements, "poissons ratio", 0.3)
nel_cylinder = length(cylinder_elements)
println("number of elements in cylinder: $nel_cylinder")

block = Problem(Elasticity, "BLOCK", 2)
block.properties.formulation = :plane_strain
block_elements = create_elements(mesh, "BLOCK")
add_elements!(block, block_elements)
update!(block_elements, "youngs modulus", 210.0e3)
update!(block_elements, "poissons ratio", 0.3)
nel_block = length(block_elements)
println("number of elements in block: $nel_block")

# Create boundary conditions:
# - block fixed to ground,
# - displacement in x direction is fixed in symmetry line, and
# - nodal force is pointing to the nearest node in top of cylinder

# support block to ground
bc1 = Problem(Dirichlet, "block bottom fixed", 2, "displacement")
bc1_elements = create_elements(mesh, "BLOCK_BOTTOM")
add_elements!(bc1, bc1_elements)
update!(bc1_elements, "displacement 2", 0.0)
nel_bc1 = length(bc1_elements)
println("number of elements in bc1: $nel_bc1")

# symmetry line
bc2 = Problem(Dirichlet, "symmetry line", 2, "displacement")
bc2_elements = [
    create_elements(mesh, "BLOCK_SYMMETRY");
    create_elements(mesh, "CYLINDER_SYMMETRY")]
add_elements!(bc2, bc2_elements)
update!(bc2_elements, "displacement 1", 0.0)
nel_bc2 = length(bc2.elements)
println("number of elements in bc2: $nel_bc2")

# find nearest node in top of cylinder and apply -35e3 newton load to that
nid = find_nearest_node(mesh, [0.0, 100.0])
load1 = Problem(Elasticity, "point load on top of cylinder", 2)
load1.properties.formulation = :plane_strain
load1_elements = [Element(Poi1, [nid])]
add_elements!(load1, load1_elements)
update!(load1_elements, "displacement traction force 2", -35.0e3)
nel_load1 = length(load1_elements)
println("number of elements in load1: $nel_load1")

contact = Problem(Contact2D, "contact between block and cylinder", 2, "displacement")
contact.properties.rotate_normals = true
contact.properties.contact_state_in_first_iteration = :ACTIVE
contact_slave_elements = create_elements(mesh, "BLOCK_TO_CYLINDER")
contact_master_elements = create_elements(mesh, "CYLINDER_TO_BLOCK")
add_slave_elements!(contact, contact_slave_elements)
add_master_elements!(contact, contact_master_elements)
nel_slave_elements = length(contact_slave_elements)
nel_master_elements = length(contact_master_elements)
println("number of elements in slave side contact: $nel_slave_elements")
println("number of elements in master side contact: $nel_master_elements")

analysis = Analysis(Nonlinear, "quasistatic analysis of cylinder-block-contact")
add_problems!(analysis, [block, cylinder, bc1, bc2, load1, contact])
analysis()

# Analysis

slaves = contact_slave_elements
masters = contact_master_elements
node_ids_s, la = get_nodal_vector(slaves, "lambda", 0.0)
node_ids_m, Xm = get_nodal_vector(masters, "geometry", 0.0)
node_ids, Xs = get_nodal_vector(slaves, "geometry", 0.0)
node_ids, ns = get_nodal_vector(slaves, "normal", 0.0)
node_ids, us = get_nodal_vector(slaves, "displacement", 0.0)
node_ids, um = get_nodal_vector(masters, "displacement", 0.0)
nsnodes = length(Xs)
nmnodes = length(Xm)
println("number of contact nodes in slave side: $nsnodes")
println("number of contact nodes in master side: $nmnodes")

Xs1 = [z[1] for z in Xs]
Xs2 = [z[2] for z in Xs]
us1 = [z[1] for z in us]
us2 = [z[2] for z in us]
Xm1 = [z[1] for z in Xm]
Xm2 = [z[2] for z in Xm]
um1 = [z[1] for z in um]
um2 = [z[2] for z in um]
p = [dot(ni, lai) for (ni, lai) in zip(ns, la)]

# order nodes according to x coordinates
o = sortperm(Xs1)
node_ids_s = node_ids_s[o]
Xs1 = Xs1[o]
Xs2 = Xs2[o]
us1 = us1[o]
us2 = us2[o]
p = p[o]

o = sortperm(Xm1)
node_ids_m = node_ids_m[o]
Xm1 = Xm1[o]
Xm2 = Xm2[o]
um1 = um1[o]
um2 = um2[o]

xs1 = Xs1 + us1
xs2 = Xs2 + us2
xm1 = Xm1 + um1
xm2 = Xm2 + um2

# Calculate resultant force from contact pressure using Trapezoidal rule

R = 0.0
for j=1:5
    l = Xs[j+1]-Xs[j]
    pavg = 1/2*(p[j]+p[j+1])
    println("$j: $l, $pavg")
    R += l*pavg
end
@test isapprox(R, [35.0e3, 0.0])
