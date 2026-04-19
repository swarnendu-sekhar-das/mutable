add_library(
    IR
    OBJECT
    CNF.cpp
    Condition.cpp
    HeuristicSearchPlanEnumerator.cpp
    Operator.cpp
    Optimizer.cpp
    PartialPlanGenerator.cpp
    PhysicalOptimizer.cpp
    PlanEnumerator.cpp
    PlanTable.cpp
    QueryGraph.cpp
    QueryGraph2SQL.cpp
    Tuple.cpp
)

# Two-Phase Optimization (2PO) algorithm for large join queries
# Implements randomized search combining Iterative Improvement and Simulated Annealing
add_library(
    TwoPhaseOptimizer
    OBJECT
    TwoPhaseOptimizer.cpp
)
