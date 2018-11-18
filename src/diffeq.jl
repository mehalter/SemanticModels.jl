using DifferentialEquations
import DifferentialEquations: solve

export parameters, domain, initial_conditions, flux, odeproblem, accelerate!,
    SpringModel, SIRParams, SIRSimulation, solve
# using DiffEqBase
# using Unitful

# f = @ode_def LotkaVolterra begin
#   dx = a*x - b*x*y
#   dy = -c*y + d*x*y
# end a b c d

function hookeslaw(du, u, p, t)
    # u[1] = p
    # u[2] = v
    du[1] = u[2]
    du[2] = -p[1] * u[1]
end

mutable struct SpringModel{F,D,U}
    frequency::F
    domain::D
    initial_position::U
end

parameters(spm::SpringModel) = spm.frequency
domain(spm::SpringModel) = spm.domain
flux(spm::SpringModel) = hookeslaw
initial_conditions(spm::SpringModel) = spm.initial_position
odeproblem(spm::SpringModel) = ODEProblem(flux(spm), initial_conditions(spm), domain(spm), parameters(spm))
solve(spm::SpringModel, alg=Vern7()) = solve(odeproblem(spm), alg)
accelerate!(spm::SpringModel, factor::Number) = begin
    spm.frequency = factor*spm.frequency
end

struct SIRParams{T,U}
    β::T
    γ::U
end

struct SIRSimulation{V, T, P}
    initial_populations::V
    tspan::T
    params::P
end

parameters(sir::SIRSimulation) = sir.params
domain(sir::SIRSimulation) = sir.tspan
initial_conditions(sir::SIRSimulation) = sir.initial_populations

function flux(sir::SIRSimulation)
    function sirflux(du, u, p, t)
        # println("sirflux call")
        # @show t
        β, γ = p.β, p.γ
        # println(β, γ)
        N = sum(u)
        # println(N)
        infections = β * (u[1]*u[2]/N)
        # println(infections)
        recoveries = γ * (u[2]/N)
        # println(recoveries)
        du[1] = -infections
        du[2] =  infections - recoveries
        du[3] =  recoveries
        # println(du)
        # println(u)
        return du
    end
    return sirflux
end

function odeproblem(sir::SIRSimulation)
    problem = ODEProblem(flux(sir), initial_conditions(sir), domain(sir), parameters(sir))
    return problem
end
function RealSIR()
    # β = NumParameter(:β, u"person/s", TransitionRate)
    # γ = NumParameter(:γ, u"person/s", TransitionRate)
    # @show β, γ

    # S = NumVariable(:S, u"person", Amount)
    # I = NumVariable(:I, u"person", Amount)
    # R = NumVariable(:R, u"person", Amount)

    # sir = SIR([ODE(:(dS/dt -> -βSI/N),
    #             [β], [S]),
    #             ODE(:(dI/dt -> βSI/N -γI),
    #                 [β, γ], [S, I]),
    #         ODE(:(dR/dt -> γI), [γ], [I])],
    #         NumVariable.([:N,:S,:I,:R], u"person", Amount),
    #         NumVariable(:t, u"s", Amount))

    return odeproblem(SIRSimulation([100,1,0.0],
                      (0,100.0),
                       SIRParams(0.50,5.0)))
end
# test case where nothing happens because of *0.0
    # return odeproblem(SIRSimulation([100,0,0.0],
    #                   (0,10.0),
    #                    SIRParams(1.0,0.2)))

# this works at this point the next step is to run it with units
# β in person^-2/day
# γ in person/day

# then use the number class to encode more information
