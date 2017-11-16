var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#JuliaFEM.jl-documentation-1",
    "page": "Introduction",
    "title": "JuliaFEM.jl documentation",
    "category": "section",
    "text": "Pages = [\"index.md\", \"api.md\"]The JuliaFEM project develops open-source software for reliable, scalable, distributed Finite Element Method.The JuliaFEM software library is a framework that allows for the distributed processing of large Finite Element Models across clusters of computers using simple programming models. It is designed to scale up from single servers to thousands of machines, each offering local computation and storage. The basic design principle is: everything is nonlinear. All physics models are nonlinear from which the linearization are made as a special cases. "
},

{
    "location": "index.html#Installing-and-testing-package-1",
    "page": "Introduction",
    "title": "Installing and testing package",
    "category": "section",
    "text": "Installing package goes same way like other packages in julia, i.e.julia> Pkg.add(\"JuliaFEM\")Testing package can be done using Pkg.test, i.e.julia> Pkg.test(\"JuliaFEM\")"
},

{
    "location": "index.html#Contributing-1",
    "page": "Introduction",
    "title": "Contributing",
    "category": "section",
    "text": "Have a new great idea and want to share it with the open source community? From here and here you can look for coding style. Here is explained how to contribute to open source project, in general."
},

{
    "location": "examples.html#",
    "page": "Examples",
    "title": "Examples",
    "category": "page",
    "text": ""
},

{
    "location": "examples.html#Simple-usage-examples-1",
    "page": "Examples",
    "title": "Simple usage examples",
    "category": "section",
    "text": "A simple example demonstrating the basic usage of package. Calculate a simple one element model. Add pressure load on top and support block symmetrically.using JuliaFEM # hide\nX = Dict(\n    1 => [0.0, 0.0],\n    2 => [1.0, 0.0],\n    3 => [1.0, 1.0],\n    4 => [0.0, 1.0])element = Element(Quad4, [1, 2, 3, 4])\nupdate!(element, \"geometry\", X)\nupdate!(element, \"youngs modulus\", 288.0)\nupdate!(element, \"poissons ratio\", 1/3)First define a field problem and add element to itbody = Problem(Elasticity, \"test problem\", 2)\nupdate!(body.properties,\n    \"formulation\" => \"plane_stress\",\n    \"finite_strain\" => \"false\",\n    \"geometric_stiffness\" => \"false\")\nbody.elements = [element]Then create element to carry on pressuretr_el = Element(Seg2, [3, 4])\nupdate!(tr_el, \"geometry\", X)\nupdate!(tr_el, \"displacement traction force 2\", 288.0)\ntraction = Problem(Elasticity, \"pressure on top of block\", 2)\nupdate!(traction.properties,\n    \"formulation\" => \"plane_stress\",\n    \"finite_strain\" => \"false\",\n    \"geometric_stiffness\" => \"false\")\ntraction.elements = [tr_el]Create boundary condition to support block at bottom and leftbc_el_1 = Element(Seg2, [1, 2])\nbc_el_2 = Element(Seg2, [4, 1])\nupdate!(bc_el_1, \"displacement 2\", 0.0)\nupdate!(bc_el_2, \"displacement 1\", 0.0)\nbc = Problem(Dirichlet, \"add symmetry bc\", 2, \"displacement\")\nbc.elements = [bc_el_1, bc_el_2]Last thing is to create a solver, push problem to solver and solve:solver = Solver(Linear, body, traction, bc)\nsolver()Displacement in node 3 issolver(\"displacement\", 0.0)[3]"
},

{
    "location": "api.html#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "api.html#API-documentation-1",
    "page": "API",
    "title": "API documentation",
    "category": "section",
    "text": ""
},

{
    "location": "api.html#Index-1",
    "page": "API",
    "title": "Index",
    "category": "section",
    "text": "DocTestSetup = quote\n    using JuliaFEM\nend"
},

{
    "location": "api.html#Types-1",
    "page": "API",
    "title": "Types",
    "category": "section",
    "text": "JuliaFEM.Element\nJuliaFEM.Problem\nJuliaFEM.Elasticity"
},

{
    "location": "api.html#FEMBase.update!",
    "page": "API",
    "title": "FEMBase.update!",
    "category": "Function",
    "text": "Default update for solver. \n\n\n\n"
},

{
    "location": "api.html#Functions-1",
    "page": "API",
    "title": "Functions",
    "category": "section",
    "text": "JuliaFEM.update!"
},

]}
