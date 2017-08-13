# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/JuliaFEM.jl/blob/master/LICENSE.md

function calculate_linear_elasticity_matrix_3d!{T}(C::Matrix{T}, E::T, nu::T)
    fill!(C, 0.0)
    @fastmath begin
        mu = E/(2.0*(1.0+nu))
        la = E*nu/((1.0+nu)*(1.0-2.0*nu))
    end
    @inbounds begin
        C[1,1] = C[2,2] = C[3,3] = 2*mu + la
        C[4,4] = C[5,5] = C[6,6] = mu
        C[1,2] = C[2,1] = C[2,3] = C[3,2] = C[1,3] = C[3,1] = la
    end
    return C
end

""" Calculate strain related quantities from displacement:

- displacement gradient ∇u
- deformation matrix F
- Green-Lagrange strain tensor E or small strain tensor ɛ
- kinematic matrix (linear part) B
"""
function calculate_kinematics_3d!{T}(N::Matrix{T}, dN::Matrix{T}, u::Vector{Vector{T}}, gradu::Matrix{T}, F::Matrix{T}, strain_tensor::Matrix{T}, strain_vector::Vector{T}, B::Matrix{T}; finite_strain=false)

    grad!(gradu, dN, u) # displacement gradient ∇u = ∂u/∂X

    # Deformation gradient F = I + ∇u || F_ij = δ(i,j) + u_i,j
    for i=1:3
        for j=1:3
            @inbounds F[i,j] = (i==j ? 1.0 : 0.0) + gradu[i,j]
        end
    end

    # Green-Lagrange strain tensor or small strain tensor
    if finite_strain
        for i =1:3
            for j=1:3
                @inbounds strain_tensor[i,j] = 1/2*(gradu[i,j] + gradu[j,i] + gradu[i,j]*gradu[j,i])
            end
        end
    else
        for i =1:3
            for j=1:3
                @inbounds strain_tensor[i,j] = 1/2*(gradu[i,j] + gradu[j,i])
            end
        end
    end

    # Strain in vector notation (11,22,33,12,23,13), note that for shear strain
    # components we use engineering strain definition to make σ = D*E to work.
    @inbounds begin
        strain_vector[1] = strain_tensor[1,1]
        strain_vector[2] = strain_tensor[2,2]
        strain_vector[3] = strain_tensor[3,3]
        strain_vector[4] = 2.0*strain_tensor[1,2]
        strain_vector[5] = 2.0*strain_tensor[2,3]
        strain_vector[6] = 2.0*strain_tensor[1,3]
    end

    # Kinematic matrix, for finite strain we write deformation gradient into this

    nnodes = length(N)

    fill!(B, 0.0)
    if finite_strain
        @inbounds for i=1:nnodes
            B[1, 3*(i-1)+1] = F[1,1]*dN[1,i]
            B[1, 3*(i-1)+2] = F[2,1]*dN[1,i]
            B[1, 3*(i-1)+3] = F[3,1]*dN[1,i]
            B[2, 3*(i-1)+1] = F[1,2]*dN[2,i]
            B[2, 3*(i-1)+2] = F[2,2]*dN[2,i]
            B[2, 3*(i-1)+3] = F[3,2]*dN[2,i]
            B[3, 3*(i-1)+1] = F[1,3]*dN[3,i]
            B[3, 3*(i-1)+2] = F[2,3]*dN[3,i]
            B[3, 3*(i-1)+3] = F[3,3]*dN[3,i]
            B[4, 3*(i-1)+1] = F[1,1]*dN[2,i] + F[1,2]*dN[1,i]
            B[4, 3*(i-1)+2] = F[2,1]*dN[2,i] + F[2,2]*dN[1,i]
            B[4, 3*(i-1)+3] = F[3,1]*dN[2,i] + F[3,2]*dN[1,i]
            B[5, 3*(i-1)+1] = F[1,2]*dN[3,i] + F[1,3]*dN[2,i]
            B[5, 3*(i-1)+2] = F[2,2]*dN[3,i] + F[2,3]*dN[2,i]
            B[5, 3*(i-1)+3] = F[3,2]*dN[3,i] + F[3,3]*dN[2,i]
            B[6, 3*(i-1)+1] = F[1,3]*dN[1,i] + F[1,1]*dN[3,i]
            B[6, 3*(i-1)+2] = F[2,3]*dN[1,i] + F[2,1]*dN[3,i]
            B[6, 3*(i-1)+3] = F[3,3]*dN[1,i] + F[3,1]*dN[3,i]
        end
    else
        @inbounds for i=1:nnodes
            B[1, 3*(i-1)+1] = dN[1,i]
            B[2, 3*(i-1)+2] = dN[2,i]
            B[3, 3*(i-1)+3] = dN[3,i]
            B[4, 3*(i-1)+1] = dN[2,i]
            B[4, 3*(i-1)+2] = dN[1,i]
            B[5, 3*(i-1)+2] = dN[3,i]
            B[5, 3*(i-1)+3] = dN[2,i]
            B[6, 3*(i-1)+1] = dN[3,i]
            B[6, 3*(i-1)+3] = dN[1,i]
        end
    end

    return nothing

end
