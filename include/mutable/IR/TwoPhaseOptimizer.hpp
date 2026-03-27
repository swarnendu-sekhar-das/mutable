#pragma once

#include <mutable/IR/PlanEnumerator.hpp>
#include <mutable/IR/QueryGraph.hpp>
#include <mutable/IR/PlanTable.hpp>
#include <mutable/catalog/CostFunction.hpp>
#include <mutable/catalog/CardinalityEstimator.hpp>
#include <vector>
#include <random>
#include <algorithm>
#include <limits>

namespace m {

/**
 * Represents a complete join order with associated cost.
 * Implements transformation rules for generating neighboring states.
 */
struct JoinState {
    std::vector<std::pair<Subproblem, Subproblem>> join_pairs;
    double cost;

    JoinState() : cost(std::numeric_limits<double>::infinity()) {}

    /**
     * Generate all neighboring states by applying transformation rules.
     * @param G query graph
     * @return vector of neighboring states
     */
    std::vector<JoinState> generate_neighbors(const QueryGraph& G) const;

private:
    /**
     * Apply commutation transformation: (A ⋈ B) → (B ⋈ A)
     * @param idx index of join pair to commute
     * @return new state with commutation applied
     */
    JoinState apply_commutation(std::size_t idx) const;

    /**
     * Apply associativity transformation: (A ⋈ B) ⋈ C → A ⋈ (B ⋈ C)
     * @param idx index of first join pair in associativity pattern
     * @return new state with associativity applied
     */
    JoinState apply_associativity(std::size_t idx) const;
};

namespace pe {

/**
 * Two-Phase Optimization (2PO) algorithm implementation.
 * Combines Iterative Improvement (Phase 1) and Simulated Annealing (Phase 2)
 * as described in Ioannidis & Kang paper.
 */
struct M_EXPORT TwoPhaseOptimizer final : PlanEnumeratorCRTP<TwoPhaseOptimizer> {
    using base_type = PlanEnumeratorCRTP<TwoPhaseOptimizer>;
    using base_type::operator();

private:
    mutable std::mt19937 rng_;

public:
    TwoPhaseOptimizer() = default;
    ~TwoPhaseOptimizer() override;

    /**
     * Main optimization entry point.
     * @param tag enumeration tag
     * @param PT plan table to fill
     * @param G query graph
     * @param CF cost function
     */
    template<typename PlanTable>
    void operator()(enumerate_tag, PlanTable &PT, const QueryGraph &G, const CostFunction &CF) const;

private:
    /**
     * Phase 1: Iterative Improvement (hill climbing).
     * @param G query graph
     * @param PT plan table
     * @param CF cost function
     * @param CE cardinality estimator
     * @return best state found in II phase
     */
    template<typename PlanTable>
    JoinState iterative_improvement(const QueryGraph& G, PlanTable& PT,
                                const CostFunction& CF, const CardinalityEstimator& CE) const;

    /**
     * Phase 2: Simulated Annealing.
     * @param initial_state starting state from II phase
     * @param G query graph
     * @param PT plan table
     * @param CF cost function
     * @param CE cardinality estimator
     * @return best state found in SA phase
     */
    template<typename PlanTable>
    JoinState simulated_annealing(const JoinState& initial_state,
                              const QueryGraph& G, PlanTable& PT,
                              const CostFunction& CF, const CardinalityEstimator& CE) const;

    /**
     * Calculate total cost of a join state.
     * @param state join state to evaluate
     * @param G query graph
     * @param PT plan table
     * @param CF cost function
     * @param CE cardinality estimator
     * @return total cost of state
     */
    template<typename PlanTable>
    double compute_state_cost(const JoinState& state, const QueryGraph& G,
                          PlanTable& PT, const CostFunction& CF,
                          const CardinalityEstimator& CE) const;

    /**
     * Generate a random initial join state.
     * @param G query graph
     * @return random join state
     */
    JoinState generate_random_state(const QueryGraph& G) const;

    /**
     * Update plan table with final join state.
     * @param state final join state
     * @param PT plan table
     * @param G query graph
     * @param CF cost function
     * @param CE cardinality estimator
     */
    template<typename PlanTable>
    void update_plan_table(const JoinState& state, PlanTable& PT, const QueryGraph& G,
                        const CostFunction& CF, const CardinalityEstimator& CE) const;
};

} // namespace pe
} // namespace m
