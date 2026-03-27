#include <mutable/IR/TwoPhaseOptimizer.hpp>
#include <mutable/catalog/Catalog.hpp>
#include <mutable/IR/PlanTable.hpp>
#include <cmath>

namespace m {

/*===== JoinState Implementation =====*/

std::vector<JoinState> JoinState::generate_neighbors(const QueryGraph& G) const {
    std::vector<JoinState> neighbors;

    // Apply commutation: (A ⋈ B) → (B ⋈ A)
    for (std::size_t i = 0; i < join_pairs.size(); ++i) {
        JoinState new_state = apply_commutation(i);
        neighbors.push_back(new_state);
    }

    // Apply associativity: (A ⋈ B) ⋈ C → A ⋈ (B ⋈ C)
    for (std::size_t i = 0; i < join_pairs.size() - 1; ++i) {
        JoinState new_state = apply_associativity(i);
        neighbors.push_back(new_state);
    }

    return neighbors;
}

JoinState JoinState::apply_commutation(std::size_t idx) const {
    JoinState new_state = *this;
    if (idx < join_pairs.size()) {
        std::swap(new_state.join_pairs[idx].first, new_state.join_pairs[idx].second);
    }
    return new_state;
}

JoinState JoinState::apply_associativity(std::size_t idx) const {
    JoinState new_state = *this;

    if (idx + 1 < join_pairs.size()) {
        auto& [left1, right1] = new_state.join_pairs[idx];
        auto& [left2, right2] = new_state.join_pairs[idx + 1];

        // Check pattern (A ⋈ B) ⋈ C
        if (right1 == left2) {
            // Transform to A ⋈ (B ⋈ C)
            new_state.join_pairs[idx] = {left1, right2};
            new_state.join_pairs[idx + 1] = {right1, left2};
        }
    }

    return new_state;
}

namespace pe {

/*===== TwoPhaseOptimizer Implementation =====*/

TwoPhaseOptimizer::~TwoPhaseOptimizer() = default;

template<typename PlanTable>
void TwoPhaseOptimizer::operator()(enumerate_tag, PlanTable &PT,
                                const QueryGraph &G, const CostFunction &CF) const {

    auto &CE = Catalog::Get().get_database_in_use().cardinality_estimator();

    // Initialize single relation plans
    for (auto &ds : G.sources()) {
        Subproblem s = Subproblem::Singleton(ds->id());
        if (not PT.has_plan(s)) {
            PT[s].cost = 0;
            PT[s].model = CE.estimate_scan(G, s);
        }
    }

    // Phase 1: Iterative Improvement
    JoinState ii_best = iterative_improvement(G, PT, CF, CE);

    // Phase 2: Simulated Annealing starting from II result
    JoinState final_state = simulated_annealing(ii_best, G, PT, CF, CE);

    // Update plan table with final solution
    update_plan_table(final_state, PT, G, CF, CE);
}

template<typename PlanTable>
JoinState TwoPhaseOptimizer::iterative_improvement(
    const QueryGraph& G, PlanTable& PT,
    const CostFunction& CF, const CardinalityEstimator& CE) const {

    JoinState best_state = generate_random_state(G);
    best_state.cost = compute_state_cost(best_state, G, PT, CF, CE);

    const std::size_t max_iterations = 1000;
    const std::size_t max_restarts = 10;

    for (std::size_t restart = 0; restart < max_restarts; ++restart) {
        JoinState current_state = generate_random_state(G);
        current_state.cost = compute_state_cost(current_state, G, PT, CF, CE);

        bool improved = true;
        for (std::size_t iter = 0; improved && iter < max_iterations; ++iter) {
            improved = false;

            auto neighbors = current_state.generate_neighbors(G);

            for (const auto& neighbor : neighbors) {
                double neighbor_cost = compute_state_cost(neighbor, G, PT, CF, CE);

                if (neighbor_cost < current_state.cost) {
                    current_state = neighbor;
                    current_state.cost = neighbor_cost;
                    improved = true;
                }
            }
        }

        if (current_state.cost < best_state.cost) {
            best_state = current_state;
        }
    }

    return best_state;
}

template<typename PlanTable>
JoinState TwoPhaseOptimizer::simulated_annealing(
    const JoinState& initial_state, const QueryGraph& G, PlanTable& PT,
    const CostFunction& CF, const CardinalityEstimator& CE) const {

    JoinState current_state = initial_state;
    JoinState best_state = initial_state;
    double temperature = 0.1;  // Starting temperature
    const double cooling_rate = 0.95;

    while (temperature > 0.001) {  // Frozen condition
        for (std::size_t iter = 0; iter < 50; ++iter) {  // Equilibrium iterations
            auto neighbors = current_state.generate_neighbors(G);
            if (neighbors.empty()) continue;

            std::uniform_int_distribution<std::size_t> dist(0, neighbors.size() - 1);
            JoinState neighbor = neighbors[dist(rng_)];
            neighbor.cost = compute_state_cost(neighbor, G, PT, CF, CE);

            if (neighbor.cost < current_state.cost) {
                current_state = neighbor;
                if (neighbor.cost < best_state.cost) {
                    best_state = neighbor;
                }
            } else {
                // Accept with probability
                double delta = neighbor.cost - current_state.cost;
                double probability = std::exp(-delta / temperature);
                std::uniform_real_distribution<double> prob_dist(0.0, 1.0);

                if (prob_dist(rng_) < probability) {
                    current_state = neighbor;
                }
            }
        }

        // Cool down
        temperature *= cooling_rate;
    }

    return best_state;
}

template<typename PlanTable>
double TwoPhaseOptimizer::compute_state_cost(const JoinState& state, const QueryGraph& G,
                                         PlanTable& PT, const CostFunction& CF,
                                         const CardinalityEstimator& CE) const {
    double total_cost = 0.0;
    cnf::CNF condition; // TODO: Use actual join condition

    for (const auto& [left, right] : state.join_pairs) {
        if (!PT.has_plan(left | right)) {
            PT.update(G, CE, CF, left, right, condition);
        }
        total_cost += PT[left | right].cost;
    }

    return total_cost;
}

JoinState TwoPhaseOptimizer::generate_random_state(const QueryGraph& G) const {
    JoinState state;
    std::vector<Subproblem> relations;

    // Collect all relations
    for (std::size_t i = 0; i < G.num_sources(); ++i) {
        relations.push_back(Subproblem::Singleton(i));
    }

    // Random shuffle
    std::shuffle(relations.begin(), relations.end(), rng_);

    // Create join pairs sequentially
    while (relations.size() > 1) {
        Subproblem first = relations.back();
        relations.pop_back();
        Subproblem second = relations.back();
        relations.pop_back();

        state.join_pairs.emplace_back(first, second);
        relations.push_back(first | second);  // Add joined relation back
    }

    return state;
}

template<typename PlanTable>
void TwoPhaseOptimizer::update_plan_table(const JoinState& state, PlanTable& PT,
                                       const QueryGraph& G, const CostFunction& CF,
                                       const CardinalityEstimator& CE) const {
    cnf::CNF condition; // TODO: Use actual join condition

    for (const auto& [left, right] : state.join_pairs) {
        PT.update(G, CE, CF, left, right, condition);
    }
}

// Template instantiations
template void TwoPhaseOptimizer::operator()<m::PlanTableSmallOrDense&>(enumerate_tag, PlanTableSmallOrDense &PT, const QueryGraph &G, const CostFunction &CF) const;
template void TwoPhaseOptimizer::operator()<m::PlanTableLargeAndSparse&>(enumerate_tag, PlanTableLargeAndSparse &PT, const QueryGraph &G, const CostFunction &CF) const;

// Register TwoPhaseOptimizer
__attribute__((constructor(203)))
static void register_two_phase_optimizer()
{
    Catalog &C = Catalog::Get();
    C.register_plan_enumerator(
        C.pool("TwoPhaseOptimizer"),
        std::make_unique<TwoPhaseOptimizer>(),
        "Two-Phase Optimization combining Iterative Improvement and Simulated Annealing"
    );
}

} // namespace pe
} // namespace m
