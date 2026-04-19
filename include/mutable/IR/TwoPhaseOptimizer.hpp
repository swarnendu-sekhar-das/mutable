/**
 * @file TwoPhaseOptimizer.hpp
 *
 * @brief Implementation of the Two-Phase Optimization (2PO) algorithm for join ordering.
 *
 * This file implements the Two-Phase Optimizer as described in the paper:
 * "Query Optimization by Simulated Annealing" by Ioannidis and Kang.
 *
 * The algorithm tackles large join queries that are intractable for exhaustive dynamic programming
 * by using a two-phase randomized search approach:
 *
 * Phase 1: Iterative Improvement (II) - Rapid hill-climbing from multiple random start states
 * Phase 2: Simulated Annealing (SA) - Probabilistic search to escape local minima
 *
 * Key Components:
 * - JoinState: Represents a complete join order as a sequence of join pairs
 * - TwoPhaseOptimizer: Main optimizer implementing the two-phase algorithm
 *
 * @note This optimizer is particularly effective for large join queries (10+ relations)
 *       where exhaustive DP becomes computationally prohibitive.
 */

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
 * Represents a complete join order and its associated cost.
 * Unlike Dynamic Programming which builds optimal subplans implicitly, randomized local
 * search algorithms (Iterative Improvement & Simulated Annealing) require an explicit
 * representation of the entire full query plan to apply transformations (moves).
 * Implements transformation rules to generate neighboring states.
 */
struct JoinState {
    std::vector<std::pair<Subproblem, Subproblem>> join_pairs;
    double cost;

    JoinState() : cost(std::numeric_limits<double>::infinity()) {}

    /**
     * Generate all neighboring states reachable by a single transformation.
     * The neighborhood consists of all valid states reachable via:
     * 1. Commutativity: Swapping left/right inputs of any join.
     * 2. Associativity: Adjusting join depth/evaluation order for adjacent joins.
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
     * Changes the shape of the join tree, exploring bushy and alternative left/right-deep trees.
     * @param idx index of first join pair in associativity pattern
     * @return new state with associativity applied
     */
    JoinState apply_associativity(std::size_t idx) const;
};

namespace pe {

/**
 * Two-Phase Optimization (2PO) algorithm implementation.
 * Tackles extremely large join queries by avoiding exhaustive dynamic programming.
 * Combines two randomized search strategies as described in the Ioannidis & Kang paper:
 * Phase 1: Iterative Improvement (hill climbing random start states to strict local minima)
 * Phase 2: Simulated Annealing (started from II's best result; escapes local minima by
 *          probabilistically taking worse paths before cooling).
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
     * Phase 1: Iterative Improvement (II).
     * Performs a series of rapid hill-climbing optimization passes starting from
     * completely random plans. Greedily accepts any transformation that lowers cost.
     * The best local minimum found is returned to seed Phase 2.
     *
     * @param G query graph
     * @param PT plan table
     * @param CF cost function
     * @param CE cardinality estimator
     * @return best local minimum state found in II phase
     */
    template<typename PlanTable>
    JoinState iterative_improvement(const QueryGraph& G, PlanTable& PT,
                                const CostFunction& CF, const CardinalityEstimator& CE) const;

    /**
     * Phase 2: Simulated Annealing (SA).
     * Starting from the strong local minimum found by II, this phase explores the
     * neighborhood probabilistically. It can temporarily accept *higher* cost states
     * to escape local minima traps. Over time, the "temperature" cools, restricting it
     * strictly to better states until it freezes at an optimal/near-optimal solution.
     *
     * @param initial_state starting state from II phase
     * @param G query graph
     * @param PT plan table
     * @param CF cost function
     * @param CE cardinality estimator
     * @return final optimized state after freezing
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

} /* namespace pe */
} /* namespace m */
