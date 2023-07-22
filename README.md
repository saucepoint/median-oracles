# median-oracles
### **An experimental suite of Median Price Oracles**

> *from ETHGlobal Paris 2023, built with Uniswap v4 Hooks 🦄*

Why not use TWAP? lower-liquidity pools are prone to manipulation!

---

| Algorithm                 | Gas (Read)                              |
|---------------------------|---------------------------------------- |
| Quickselect               | comically a lot (hundreds of thousands) |
| Frugal-2U                 | comically a lot (but less than QS)      |
| Running Frugal-2U         | 4812                                    |
| Quickselect Time-weighted | TBD                                     |
| Frugal-2U Time-weighted   | TBD                                     |

> Methodology: obtain 50 *unique* tick observations by running swaps in both directions. Each swap is spaced 12 seconds apart. Use `gasleft()` before and after reading the median

## Median Price Oracle (Quickselect)

The classic: given a sequence of unordered ticks, fetch the median with the quickselect algorithm

* Uses an O(logn) algorithm on-read
* Depends on tick observations written to storage

## Frugal Median Price Oracle

Approximates the median using `Frugal-2U` from a sequence of numbers (naive implementation)

Frugal median algorithm compares new numbers against the current approximation and updates the approximation according to a dynamic *step*

* Uses the frugal median-approximation algorithm
* Depends on tick observations written to storage

## Running Frugal Median Price Oracle

The gas-optimized implementation of the frugal median approximation: calculating an on-going approximation of the median

* Uses the frugal median-approxiation algorithm
* Stores the *running* median (approximated) in direct storage
* *additional research™️ required for windowed support* 

### Future work: step-optimization
In the frugal median algorithm, the dynamic *step* can be modified to favor stabilization or responsiveness/accuracy. The repo uses 1-tick as a step, but the implementation is set up for additional experimentation

### Future work: time-weighted medians

The repo is in its early stages and did not have sufficient time to implement time-weighted medians. Time-weighted medians are likely to better represent the price since they account for the duration of a tick (price observation). The repo currently treats unique price observations as having equivalent durations.


---


```
src/
├── RunningFrugalMedianHook.sol - Running median approximation
├── TickObserver.sol - store tick observations for windowed median reads
├── lens
│   ├── FrugalMedianLens.sol - read TickObserver and approximate median
│   └── MedianLens.sol - read TickObserver and calculate true median
└── lib
    ├── FrugalMedianLibrary.sol - median approximation library
    ├── MedianLibrary.sol - median calculation library (quickselect)
    └── RingBufferLibrary.sol - optimized ring buffer for price observations

test/
├── FrugalMedianLens.t.sol - test the naive frugal median
├── MedianLens.t.sol - test the true median (quickselect)
├── RunningMedian.t.sol - test the running median approximation
├── TickObserver.t.sol - test the tick observer
├── implementation
│   ├── ... - Uniswap overrides for testing
├── median
│   ├── FrugalMedianTest.t.sol - test frugal median algo
│   └── MedianLibrary.t.sol - test quickselect algo
└── utils
    ├── HookTest.sol
    └── RingBuffer.t.sol - test ring buffer
```

---

Additional resources:

[v4-periphery](https://github.com/uniswap/v4-periphery) contains advanced hook implementations that serve as a great reference

[v4-core](https://github.com/uniswap/v4-core)

---

*requires [foundry](https://book.getfoundry.sh)*

```
forge install
forge test
```

---

Credits

* [Frugal Streaming for Estimating Quantiles:One (or two)
memory suffices](https://arxiv.org/pdf/1407.1121v1.pdf)

* [euler-xyz/median-oracle](https://github.com/euler-xyz/median-oracle) and [median oracle discussions](https://ethresear.ch/t/median-prices-as-alternative-to-twap-an-optimised-proof-of-concept-analysis-and-simulation/12778)

* [Uniswap v3 TWAP Oracles in Proof of Stake](https://blog.uniswap.org/uniswap-v3-oracles)
