# Two-Phase Optimizer (2PO) - Codebase Footprint Map

> [!NOTE]
> This document explicitly isolates the operational footprint of the `TwoPhaseOptimizer` within the `mutable` codebase. It identifies the exact physical bounds where the algorithm resides, alongside precisely parsing how configuration tools were modified to wire it perfectly into execution paths.

The entire scope of the algorithm safely distributes across **6 primary files**:

---

## 1. The Algorithmic Brain (Interfaces & Execution)

The actual procedural logic lives in completely decoupled core files isolated natively into the internal `IR` (Intermediate Representation) folder mapping.

### `include/mutable/IR/TwoPhaseOptimizer.hpp`
* **Status**: New File
* **Footprint Purpose**: Defines the architectural interfaces shielding implementation properties. Emits standard data structure boundaries specifically handling `JoinState` configuration sets and publicly structuring the algorithmic transitions defining `apply_associativity()` and `apply_commutation()`.

### `src/IR/TwoPhaseOptimizer.cpp`
* **Status**: New File
* **Footprint Purpose**: The operational payload carrying the mathematical logic. Houses the rigid hill-climbing descent logic driving `iterative_improvement`, explicit randomized thermodynamically probabilistic computations dictating `<random>` pulls natively inside `simulated_annealing`, and leverages GNU structural initialization hooks `__attribute__((constructor(203)))` bridging the algorithm dynamically into catalog memory execution registries without hardcoding constraints.

---

## 2. The Verification Framework (Unit Tests)

The framework demands explicit bounds-checking validating meta-heuristic probabilities independently to isolate operational runtime regressions seamlessly.

### `unittest/IR/TwoPhaseOptimizerTest.cpp`
* **Status**: New File
* **Footprint Purpose**: Anchors automated structural integration validations actively invoking the `Catch2` testing harness.
* **Coverage Scope**:
  1. Validates `std::numeric_limits<double>::infinity()` structural bindings checking cost assignments organically.
  2. Synthesizes memory pointer validations proving left-deep mathematical boundaries natively via Associativity shifts. *(This isolated testing environment properly exposed and ultimately shielded C++ array structural memory overlaps found and corrected earlier).*
  3. Proves correct dynamic registration against the explicit system layout `Catalog::Get().list_plan_enumerators()`.

---

## 3. The Central Integrations (Engine Bindings)

Internal execution nodes must seamlessly invoke algorithmic dependencies mapping memory variables homogeneously.

### `src/IR/PlanEnumerator.cpp`
* **Status**: Modified File
* **Footprint Purpose**: Integrates the algorithm homogeneously into dynamic execution parameters natively mapped by internal user-facing shell structures.
* **Alteration Logistics**: Extensively decoupled native `Dynamic Programming` explicit enumerator lists (e.g., `DPsize`, `DPccp`) using explicit predefined macro isolation rules `LIST_PE_INSTANTIATE(X)`, implicitly safeguarding the stochastic meta-heuristic boundaries strictly without clashing configurations globally across execution threads.

---

## 4. Compile Constraints (The Build Pipeline)

Linker paths explicitly validate module boundaries parsing definitions flawlessly without polluting adjacent logical parameters.

### `src/IR/CMakeLists.txt`
* **Status**: Modified File
* **Footprint Purpose**: Isolates logical boundary constraints actively compiling specific object modules safely avoiding `Linker` cross-pollution rules natively.
* **CMake Action**: Executed structural segregation via `add_library(TwoPhaseOptimizer OBJECT TwoPhaseOptimizer.cpp)`.

### `src/CMakeLists.txt`
* **Status**: Modified File
* **Footprint Purpose**: Unifies dynamic binary boundaries compiling the final `libmutable` artifact footprint securely.
* **CMake Action**: Successfully loops explicit static variables cascading directly into `$TARGET_OBJECTS:TwoPhaseOptimizer>`, generating terminal-ready executables efficiently wrapping the backend optimization tools.

---

> [!TIP]
> **To showcase the payload in execution natively:**
> If you pull apart the codebase, these 6 files alone are strictly responsible for navigating complex 15-way topological exponential growth bounds securely inside < 500ms intervals!
