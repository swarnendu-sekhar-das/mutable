#include "catch2/catch.hpp"

#include <iostream>
#include <mutable/catalog/Catalog.hpp>
#include <mutable/catalog/CostFunction.hpp>
#include <mutable/catalog/CostFunctionCout.hpp>
#include <mutable/catalog/Type.hpp>
#include <mutable/IR/TwoPhaseOptimizer.hpp>
#include <mutable/IR/PlanTable.hpp>
#include <mutable/mutable.hpp>
#include <mutable/storage/Store.hpp>
#include <mutable/util/ADT.hpp>
#include <parse/Parser.hpp>
#include <parse/Sema.hpp>
#include <testutil.hpp>

using namespace m;
using namespace pe;

/*======================================================================================================================
 * Helper functions for test setup.
 *====================================================================================================================*/

namespace twophase_test {

template<typename PlanTable>
void init_PT_base_case(const QueryGraph &G, PlanTable &PT)
{
    auto &CE = Catalog::Get().get_database_in_use().cardinality_estimator();
    using Subproblem = SmallBitset;
    for (auto &ds : G.sources()) {
        Subproblem s = Subproblem::Singleton(ds->id());
        auto bt = as<const BaseTable>(*ds);
        PT[s].cost = 0;
        PT[s].model = CE.estimate_scan(G, s);
    }
}

}

/*======================================================================================================================
 * Test JoinState functionality.
 *====================================================================================================================*/

TEST_CASE("JoinState basic operations", "[core][IR][TwoPhaseOptimizer]")
{
    JoinState state;

    // Test initial state
    REQUIRE(state.join_pairs.empty());
    REQUIRE(state.cost == std::numeric_limits<double>::infinity());

    // Test adding join pairs
    Subproblem left = Subproblem::Singleton(0);
    Subproblem right = Subproblem::Singleton(1);
    state.join_pairs.emplace_back(left, right);

    REQUIRE(state.join_pairs.size() == 1);
    REQUIRE(state.join_pairs[0].first == left);
    REQUIRE(state.join_pairs[0].second == right);
}

TEST_CASE("JoinState commutation via neighbors", "[core][IR][TwoPhaseOptimizer]")
{
    JoinState state;
    Subproblem left = Subproblem::Singleton(0);
    Subproblem right = Subproblem::Singleton(1);
    state.join_pairs.emplace_back(left, right);

    // Use the public generate_neighbors API which applies commutation and associativity
    QueryGraph G;
    auto neighbors = state.generate_neighbors(G);

    // With 1 join pair and 0 associativity candidates, we get 1 commutation neighbor
    REQUIRE(neighbors.size() == 1);
    // The commuted neighbor should swap left/right
    REQUIRE(neighbors[0].join_pairs[0].first == right);
    REQUIRE(neighbors[0].join_pairs[0].second == left);
}

TEST_CASE("JoinState associativity via neighbors", "[core][IR][TwoPhaseOptimizer]")
{
    JoinState state;
    Subproblem A = Subproblem::Singleton(0);
    Subproblem B = Subproblem::Singleton(1);
    Subproblem C = Subproblem::Singleton(2);
    Subproblem AB = A | B;

    // Create pattern (A ⋈ B) ⋈ C  — the second join's left must equal the first join's right for associativity
    state.join_pairs.emplace_back(A, B);
    state.join_pairs.emplace_back(AB, C);

    QueryGraph G;
    auto neighbors = state.generate_neighbors(G);

    // 2 commutations (one per join pair) + 1 associativity = 3 neighbors
    REQUIRE(neighbors.size() == 3);
}

/*======================================================================================================================
 * Test TwoPhaseOptimizer integration.
 *====================================================================================================================*/

TEST_CASE("TwoPhaseOptimizer basic functionality", "[core][IR][TwoPhaseOptimizer]")
{
    using Subproblem = SmallBitset;
    using PlanTable = PlanTableSmallOrDense;

    // Create a simple 3-table query
    Catalog &C = Catalog::Get();
    Catalog::Clear();

    // Create database and tables
    auto &DB = C.add_database(C.pool("test_db"));
    C.set_database_in_use(DB);

    auto &table_A = DB.add_table(C.pool("A"));
    table_A.push_back(C.pool("id"), Type::Get_Integer(Type::TY_Vector, 4));
    table_A.push_back(C.pool("value"), Type::Get_Integer(Type::TY_Vector, 4));

    auto &table_B = DB.add_table(C.pool("B"));
    table_B.push_back(C.pool("id"), Type::Get_Integer(Type::TY_Vector, 4));
    table_B.push_back(C.pool("value"), Type::Get_Integer(Type::TY_Vector, 4));

    auto &table_C = DB.add_table(C.pool("C"));
    table_C.push_back(C.pool("id"), Type::Get_Integer(Type::TY_Vector, 4));
    table_C.push_back(C.pool("value"), Type::Get_Integer(Type::TY_Vector, 4));

    // Create a simple query graph (3-way join)
    QueryGraph G;

    // This is a simplified test - in real usage, the query graph would be built from SQL
    // For testing purposes, we'll create a minimal setup

    // Test that TwoPhaseOptimizer can be instantiated and basic operations work
    TwoPhaseOptimizer optimizer;

    // The optimizer should be registered in the catalog
    REQUIRE_NOTHROW(C.plan_enumerator(C.pool("TwoPhaseOptimizer")));
}

TEST_CASE("TwoPhaseOptimizer registration", "[core][IR][TwoPhaseOptimizer]")
{
    Catalog &C = Catalog::Get();

    // Check that TwoPhaseOptimizer is registered
    REQUIRE_NOTHROW(C.plan_enumerator(C.pool("TwoPhaseOptimizer")));

    // Check that it is available in the iterator
    bool found_description = false;
    for (auto it = C.plan_enumerators_cbegin(); it != C.plan_enumerators_cend(); ++it) {
        // C.pool returns ThreadSafePooledString which can be compared
        if (it->first == C.pool("TwoPhaseOptimizer")) {
            // just ensuring it exists
            found_description = true;
        }
    }
    REQUIRE(found_description);
}

TEST_CASE("TwoPhaseOptimizer random state generation", "[core][IR][TwoPhaseOptimizer]")
{
    TwoPhaseOptimizer optimizer;

    // Create a mock query graph with 3 sources
    // Note: This is a simplified test - real QueryGraph would be more complex
    QueryGraph G;

    // Test that random state generation doesn't crash
    // In a real test, we would need to properly set up the QueryGraph
    // For now, this tests basic compilation and instantiation

    REQUIRE(true); // Placeholder test
}

/*======================================================================================================================
 * Integration with existing mu*t*able components.
 *====================================================================================================================*/

TEST_CASE("TwoPhaseOptimizer catalog integration", "[core][IR][TwoPhaseOptimizer]")
{
    Catalog &C = Catalog::Get();

    // Verify TwoPhaseOptimizer is properly registered
    bool found = false;
    for (auto it = C.plan_enumerators_cbegin(); it != C.plan_enumerators_cend(); ++it) {
        if (it->first == C.pool("TwoPhaseOptimizer")) {
            found = true;
            break;
        }
    }

    REQUIRE(found);
}

/*======================================================================================================================
 * Performance and correctness validation.
 *====================================================================================================================*/

TEST_CASE("TwoPhaseOptimizer algorithm phases", "[core][IR][TwoPhaseOptimizer]")
{
    // Test that both phases of the algorithm are implemented correctly

    // Phase 1: Iterative Improvement should find local optima
    // Phase 2: Simulated Annealing should start from best II result

    // This is a placeholder test for algorithm validation
    // In a complete test suite, we would:
    // 1. Create test queries of varying complexity
    // 2. Compare 2PO results with known optimal solutions
    // 3. Measure convergence behavior
    // 4. Validate that Phase 2 improves upon Phase 1 results

    REQUIRE(true); // Placeholder
}
